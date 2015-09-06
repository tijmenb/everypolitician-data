require 'yajl/json_gem'
require 'open-uri'
require 'rake/clean'
require 'pry'
require 'csv'
require 'colorize'

Numeric.class_eval { def empty?; false; end }


def deep_sort(element)
  if element.is_a?(Hash)
    element.keys.sort.each_with_object({}) { |k, newhash| newhash[k] = deep_sort(element[k]) }
  elsif element.is_a?(Array)
    element.map { |v| deep_sort(v) }
  else
    element
  end
end

def json_load(file)
  return unless File.exist? file
  JSON.parse(File.read(file), symbolize_names: true)
end

def json_write(file, json)
  # TODO remove the need for the .to_s here, by ensuring all People and Orgs have names
  json[:persons].sort_by!       { |p| [ p[:name].to_s, p[:id] ] }
  json[:organizations].sort_by! { |o| [ o[:name].to_s, o[:id] ] }
  json[:memberships].sort_by!   { |m| [ m[:person_id], m[:organization_id] ] }
  json[:events].sort_by!        { |e| [ e[:start_date] || '', e[:id] ] } if json.key? :events
  json[:areas].sort_by!         { |a| [ a[:id] ] } if json.key? :areas
  final = Hash[deep_sort(json).sort_by { |k, _| k }.reverse]
  File.write(file, JSON.pretty_generate(final))
end

def instructions(key)
  @instructions ||= json_load(@INSTRUCTIONS_FILE) || raise("Can't read #{@INSTRUCTIONS_FILE}")
  @instructions[key]
end

desc "Rebuild from source data"
task :rebuild => [ :clobber, 'ep-popolo-v1.0.json' ]
task :default => :csvs

desc "Remove unwanted data from source"
task :whittle => [:clobber, 'sources/merged.json']

namespace :whittle do

  # Source-specific files must provide a whittle:load

  file 'sources/merged.json' => :write 
  CLEAN.include('sources/merged.json')

  # Source-specific files must provide a @SOURCE

  task :meta_info => :load do
    @json[:meta] ||= {}
    @json[:meta][:source] = @SOURCE || instructions(:source) || abort("No @SOURCE defined")
  end

  # Remove any 'warnings' left behind from (e.g.) csv-to-popolo
  task :write => :remove_warnings
  task :remove_warnings => :load do
    @json.delete :warnings
  end

  # TODO work out how to make this do the 'only run if needed'
  task :write => :meta_info do
    unless File.exists? 'sources/merged.json'
      json_write('sources/merged.json', @json)
    end
  end

  #---------------------------------------------------------------------
  # Rule: No orphaned memberships
  #---------------------------------------------------------------------
  task :write => :no_orphaned_memberships
  task :no_orphaned_memberships => :load do
    @json[:memberships].keep_if { |m|
      @json[:organizations].find { |o| o[:id] == m[:organization_id] } and
      @json[:persons].find { |p| p[:id] == m[:person_id] } 
    }
  end  
end


namespace :transform do

  file 'ep-popolo-v1.0.json' => :write
  CLEAN.include('ep-popolo-v1.0.json', 'final.json')

  task :load => 'sources/merged.json' do
    @json = JSON.parse(File.read('sources/merged.json'), symbolize_names: true )
  end

  task :write do
    json_write('ep-popolo-v1.0.json', @json)
  end  

  #---------------------------------------------------------------------
  # Rule: There must be a single legislature
  #---------------------------------------------------------------------
  task :write => :ensure_legislature
  task :ensure_legislature => :load do
    legis = @json[:organizations].find_all { |h| h[:classification] == 'legislature' }
    raise "Legislature count = #{count}" unless legis.count == 1
    @legislature = legis.first
  end

  #---------------------------------------------------------------------
  # Rule: The legislature must be named
  #   Get this from the meta.json file
  #---------------------------------------------------------------------
  task :write => :name_legislature
  task :name_legislature => :ensure_legislature do
    raise "No meta.json file available" unless File.exist? 'meta.json'
    meta_info = json_load('meta.json')
    @legislature.merge! meta_info
    (@legislature[:identifiers] ||= []) << { 
      scheme: 'wikidata',
      identifier: @legislature.delete(:wikidata)
    } if @legislature.key?(:wikidata)
  end

  #---------------------------------------------------------------------
  # Merge with terms.csv
  #---------------------------------------------------------------------
  task :write => :ensure_term

  def terms_from_csv
    termfiles = Dir.glob("sources/**/terms.csv")
    raise "No terms.csv" if termfiles.count.zero?
    raise "Too many terms.csv [#{termfiles}]" if termfiles.count > 1

    CSV.read(termfiles.first, headers:true).map do |row|
      {
        id: row['id'][/\//] ? row['id'] : "term/#{row['id']}",
        name: row['name'],
        start_date: row['start_date'],
        end_date: row['end_date'],
        classification: 'legislative period',
        organization_id: @legislature[:id]
      }.reject { |_,v| v.nil? or v.empty? }
    end
  end

  task :ensure_term => :ensure_legislature do
    @json[:events] ||= []

    terms_from_csv.each do |t| 
      if event = @json[:events].find { |e| e[:id] == t[:id] }
        event.merge! t
      else 
        warn "Unused event: #{t}"
      end
    end

  end

  #---------------------------------------------------------------------
  # Rule: Legislative Memberships must be for a Term
  #---------------------------------------------------------------------
  task :write => :ensure_membership_terms
  task :ensure_membership_terms => :ensure_term do
    @json[:memberships].find_all { |m| m[:role] == 'member' and m[:organization_id] == @legislature[:id] }.each do |m|
      raise "No term" if m[:legislative_period_id].to_s.empty?

      # Don't duplicate start/end dates into memberships needlessly
      e = @json[:events].find { |e| e[:id] == m[:legislative_period_id] } or raise "#{m[:legislative_period_id]} is not a term"
      m.delete :start_date if m[:start_date].to_s == e[:start_date].to_s
      m.delete :end_date   if m[:end_date].to_s   == e[:end_date].to_s
    end
  end

  #---------------------------------------------------------------------
  # Rule: Legislative Memberships must have `on_behalf_of`
  # Will be set to @INDEPENDENT, or first named "Independent" party
  # (or one will be created)
  #---------------------------------------------------------------------

  def unknown_party
    if unknown = @json[:organizations].find { |o| o[:classification] == 'party' and o[:name].downcase == 'unknown' }
      return unknown
    end
    unknown = {
      classification: "party",
      name: "Unknown",
      id: "party/_unknown",
    }
    @json[:organizations] << unknown
    unknown
  end

  task :write => :ensure_behalf_of
  task :ensure_behalf_of => :ensure_legislature do
    leg_ids = @json[:organizations].find_all { |o| %w(legislature chamber).include? o[:classification] }.map { |o| o[:id] }
    @json[:memberships].find_all { |m| m[:role] == 'member' and leg_ids.include? m[:organization_id] }.each do |m|
      m[:on_behalf_of_id] = unknown_party[:id] if m[:on_behalf_of_id].to_s.empty?
    end
  end

  #---------------------------------------------------------------------
  # Rule: Areas should be first class, not just embedded
  #---------------------------------------------------------------------

  task :write => :check_no_embedded_areas 
  task :check_no_embedded_areas => :ensure_legislature do
    raise "Memberships should not have embedded areas" if @json[:memberships].any? { |m| m.key? :area }
  end

end


desc "Build the term-table CSVs"
task :csvs => ['term_csvs:term_tables']

CLEAN.include('term-*.csv')

namespace :term_csvs do

  require 'csv'

  def persons_twitter(p)
    if p.key? :contact_details
      if cd_twitter = p[:contact_details].find { |d| d[:type] == 'twitter' }
        return cd_twitter[:value].strip
      end
    end

    if p.key? 'links'
      if l_twitter = p[:links].find { |d| d[:note][/twitter/i] }
        return l_twitter[:url].strip
      end
    end
  end

  # https://twitter.com/tom_watson?lang=en
  # https://twitter.com/search?q=%23EvelynMEP&src=typd

  def standardised_twitter(t)
    return if t.to_s.empty?
    return $1 if t.match /^\@(\w+)$/
    return $1 if t.match /^(\w+)$/
    return $1 if t.match %r{(?:www.)?twitter.com/@?(\w+)$}

    # Odd special cases
    return $1 if t.match %r{twitter.com/search\?q=%23(\w+)}
    return $1 if t.match %r{twitter.com/#!/https://twitter.com/(\w+)}
    return $1 if t.match %r{(?:www.)?twitter.com/#!/(\w+)[/\?]?}
    return $1 if t.match %r{(?:www.)?twitter.com/@?(\w+)[/\/]?}
    warn "Unknown twitter handle: #{t.to_s.magenta}"
    return 
  end

  def persons_facebook(p)
    (p[:links] || {}).find(->{{url: nil}}) { |d| d[:note] == 'facebook' }[:url]
  end

  def name_at(p, date)
    return p[:name] unless date && p.key?(:other_names)
    historic = p[:other_names].find_all { |n| n.key?(:end_date) } 
    return p[:name] unless historic.any?
    at_date = historic.find_all { |n|
      n[:end_date] >= date && (n[:start_date] || '0000-00-00') <= date
    }
    return p[:name] if at_date.empty?
    raise "Too many names at #{date}: #{at_date}" if at_date.count > 1
    
    return at_date.first[:name]
  end

  task :term_tables => 'ep-popolo-v1.0.json' do
    @json = JSON.parse(File.read('ep-popolo-v1.0.json'), symbolize_names: true )
    terms = {}

    data = @json[:memberships].find_all { |m| m.key? :legislative_period_id }.map do |m|
      person = @json[:persons].find       { |r| (r[:id] == m[:person_id])       || (r[:id].end_with? "/#{m[:person_id]}") }
      group  = @json[:organizations].find { |o| (o[:id] == m[:on_behalf_of_id]) || (o[:id].end_with? "/#{m[:on_behalf_of_id]}") }
      house  = @json[:organizations].find { |o| (o[:id] == m[:organization_id]) || (o[:id].end_with? "/#{m[:organization_id]}") }
      terms[m[:legislative_period_id]] ||= @json[:events].find { |e| e[:id].split('/').last == m[:legislative_period_id].split('/').last }

      if group.nil?
        puts "No group for #{m}"
        binding.pry
        next
      end

      {
        id: person[:id].split('/').last,
        name: name_at(person, m[:end_date] || terms[m[:legislative_period_id]][:end_date]),
        email: person[:email],
        twitter: standardised_twitter(persons_twitter(person)),
        facebook: persons_facebook(person),
        group: group[:name],
        group_id: group[:id].split('/').last,
        area_id: m[:area_id],
        area: m[:area_id] && @json[:areas].find { |a| a[:id] == m[:area_id] }[:name],
        chamber: house[:name],
        term: m[:legislative_period_id].split('/').last,
        start_date: m[:start_date],
        end_date: m[:end_date],
        image: person[:image],
        gender: person[:gender],
      }
    end
    data.group_by { |r| r[:term] }.each do |t, rs|
      filename = "term-#{t}.csv"
      header = rs.first.keys.to_csv
      rows   = rs.sort_by { |r| [r[:name], r[:start_date].to_s] }.map { |r| r.values.to_csv }
      csv    = [header, rows].compact.join
      warn "Creating #{filename}"
      File.write(filename, csv)
    end
  end

end
