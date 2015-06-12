require 'json'
require 'open-uri'
require 'rake/clean'
require 'pry'
require 'csv'

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

def json_write(file, json)
  # TODO remove the need for the .to_s here, by ensuring all People and Orgs have names
  json[:persons].sort_by!       { |p| [ p[:name].to_s, p[:id] ] }
  json[:organizations].sort_by! { |o| [ o[:name].to_s, o[:id] ] }
  json[:memberships].sort_by!   { |m| [ m[:person_id], m[:organization_id] ] }
  final = Hash[deep_sort(json).sort_by { |k, _| k }.reverse]
  File.write(file, JSON.pretty_generate(final))
end

desc "Rebuild from source data"
task :rebuild => [ :clobber, 'final.json' ]
task :default => 'final.json'

desc "Remove unwanted data from source"
task :whittle => [:clobber, 'clean.json']

namespace :whittle do

  # Source-specific files must provide a whittle:load

  file 'clean.json' => :write 
  CLOBBER.include('clean.json')

  # Source-specific files must provide a @SOURCE

  task :meta_info => :load do
    @json[:meta] ||= {}
    @json[:meta][:source] = @SOURCE or abort "No @SOURCE defined"
  end

  # Remove any 'warnings' left behind from (e.g.) csv-to-popolo
  task :write => :remove_warnings
  task :remove_warnings => :load do
    @json.delete :warnings
  end

  # TODO work out how to make this do the 'only run if needed'
  task :write => :meta_info do
    unless File.exists? 'clean.json'
      json_write('clean.json', @json)
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

  file 'final.json' => :write
  CLOBBER.include('final.json')

  task :load => 'clean.json' do
    @json = JSON.parse(File.read('clean.json'), symbolize_names: true )
  end

  task :write do
    json_write('final.json', @json)
  end  

  #---------------------------------------------------------------------
  # Rule: There must be a legislature
  #---------------------------------------------------------------------
  task :write => :ensure_legislature
  task :ensure_legislature => :load do
    if @json[:organizations].find_all { |h| h[:classification] == 'legislature' }.count.zero?
      @json[:organizations] << {
        classification: "legislature",
        name: "Legislature",
        id: "legislature",
      }
    end
  end

  #---------------------------------------------------------------------
  # Rule: The legislature must be named
  #---------------------------------------------------------------------
  task :write => :name_legislature
  task :name_legislature => :ensure_legislature do
    # Can be defined in country-level rakefile
    if (@LEGISLATURE)
      leg = @json[:organizations].find_all { |h| h[:classification] == 'legislature' }
      raise "More than one legislature exists, and @LEGISLATURE set" if leg.count > 1
      # Don't pass through the seat count until we work out how to do this properly
      leg.first.merge! @LEGISLATURE.reject { |k,_| k == :seats }
    end

  end

  #---------------------------------------------------------------------
  # Rule: There must be at least one term
  # If there are none, we create them, by (in order of preference)
  # 1) Reading them from a 'terms.csv'
  # 2) Reading them from a file specified as @TERMFILE
  # 3) Reading them from a @TERMS array
  #---------------------------------------------------------------------
  task :write => :ensure_term

  def extra_termdata
    @TERMFILES = Dir.glob("sources/**/terms.csv")
    raise "Too many Termfiles [#{@TERMFILES}]" if @TERMFILES.count > 1

    if @TERMFILES.count == 1
      @TERMS = CSV.read(@TERMFILES.first, headers:true).map do |row|
        {
          id: row['id'][/\//] ? row['id'] : "term/#{row['id']}",
          name: row['name'],
          start_date: row['start_date'],
          end_date: row['end_date'],
        }.reject { |_,v| v.nil? or v.empty? }
      end
    end

    return [] if @TERMS.nil? or @TERMS.count.zero?
    @TERMS.each { |t| t[:classification] ||= 'legislative period' } 
    return @TERMS
  end

  def latest_term 
    @TERMS.sort_by { |t| t[:start_date].to_s }.last
  end

  task :write => :ensure_term
  task :ensure_term => :ensure_legislature do
    leg = @json[:organizations].find { |h| h[:classification] == 'legislature' } or raise "No legislature"
    newterms = extra_termdata
    if not leg.has_key?(:legislative_periods) or leg[:legislative_periods].count.zero? 
      raise "No @TERMFILE or @TERMS" if newterms.count.zero?
      leg[:legislative_periods] = newterms 
    else 
      leg[:legislative_periods].each do |t|
        if extra = newterms.find { |nt| nt[:id].to_s.split('/').last == t[:id].to_s.split('/').last }
          t.merge! extra.reject { |k, _| k == :id }
        end
      end
    end
  end

  #---------------------------------------------------------------------
  # Rule: Legislative Memberships must be for a Term
  #---------------------------------------------------------------------
  task :write => :ensure_membership_terms
  task :ensure_membership_terms => :ensure_term do
    leg_ids = @json[:organizations].find_all { |o| %w(legislature chamber).include? o[:classification] }.map { |o| o[:id] }
    @json[:memberships].find_all { |m| m[:role] == 'member' and leg_ids.include? m[:organization_id] }.each do |m|
      m[:legislative_period_id] ||= latest_term[:id] 
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
      m[:on_behalf_of_id] ||= unknown_party[:id]
    end
  end

end


desc "Build the term-table CSVs"
task :csvs => ['term_csvs:term_tables']

namespace :term_csvs do

  def persons_twitter(p)
    if p.key? :contact_details
      if cd_twitter = p[:contact_details].find { |d| d[:type] == 'twitter' }
        return cd_twitter[:value]
      end
    end

    if p.key? 'links'
      if l_twitter = p[:links].find { |d| d[:note][/twitter/i] }
        return l_twitter[:url]
      end
    end
  end


  require 'csv'

  task :term_tables => 'final.json' do
    @json = JSON.parse(File.read('final.json'), symbolize_names: true )
    data = @json[:memberships].find_all { |m| m.key? :legislative_period_id }.map do |m|
      person = @json[:persons].find       { |r| (r[:id] == m[:person_id])       || (r[:id].end_with? "/#{m[:person_id]}") }
      group  = @json[:organizations].find { |o| (o[:id] == m[:on_behalf_of_id]) || (o[:id].end_with? "/#{m[:on_behalf_of_id]}") }
      house  = @json[:organizations].find { |o| (o[:id] == m[:organization_id]) || (o[:id].end_with? "/#{m[:organization_id]}") }
      {
        id: person[:id].split('/').last,
        name: person[:name],
        email: person[:email],
        twitter: persons_twitter(person),
        group: group[:name],
        group_id: group[:id].split('/').last,
        area: m[:area] && m[:area][:name],
        chamber: house[:name],
        term: m[:legislative_period_id].split('/').last,
        start_date: m[:start_date],
        end_date: m[:end_date],
      }
    end
    data.group_by { |r| r[:term] }.each do |t, rs|
      filename = "term-#{t}.csv"
      header = rs.first.keys.to_csv
      rows   = rs.sort_by { |r| [r[:name], r[:start_date]] }.map { |r| r.values.to_csv }
      csv    = [header, rows].compact.join
      warn "Creating #{filename}"
      File.write(filename, csv)
    end
  end

end

