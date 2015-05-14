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
      leg.first.merge! @LEGISLATURE
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
    @TERMFILE ||= 'terms.csv' if File.exists? 'terms.csv'

    if @TERMFILE 
      @TERMS = CSV.read(@TERMFILE, headers:true).map do |row|
        {
          id: row['id'][/\//] ? row['id'] : "term/#{row['id']}",
          name: row['name'],
          start_date: row['start_date'],
          end_date: row['end_date'],
        }.reject { |_,v| v.nil? or v.empty? }
      end
    end

    if @TERMS.nil? or @TERMS.empty?
      raise "Can't find any terms"
    end

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
      leg[:legislative_periods] = newterms
    else 
      leg[:legislative_periods].each do |t|
        t.merge! newterms.find { |nt| nt[:id] == t[:id] }
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

  def default_behalf
    if ind_party = @INDEPENDENT || @json[:organizations].find { |o| o[:classification] == 'party' and o[:name] == 'Independent' }
      return ind_party
    end
    ind_party = {
      classification: "party",
      name: "Independent",
      id: "party/independent",
    }
    @json[:organizations] << ind_party
    ind_party
  end

  task :write => :ensure_behalf_of
  task :ensure_behalf_of => :ensure_legislature do
    leg_ids = @json[:organizations].find_all { |o| %w(legislature chamber).include? o[:classification] }.map { |o| o[:id] }
    @json[:memberships].find_all { |m| m[:role] == 'member' and leg_ids.include? m[:organization_id] }.each do |m|
      m[:on_behalf_of_id] ||= default_behalf[:id]
    end
  end

end
