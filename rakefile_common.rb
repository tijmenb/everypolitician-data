require 'json'
require 'open-uri'
require 'rake/clean'
require 'pry'


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
  json[:persons].sort_by!       { |p| [ p[:name], p[:id] ] }
  json[:organizations].sort_by! { |p| [ p[:name], p[:id] ] }
  json[:memberships].sort_by!   { |p| [ p[:person_id], p[:organization_id] ] }
  File.write(file, JSON.pretty_generate(deep_sort(json)))
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

  # TODO work out how to make this do the 'only run if needed'
  task :write => :load do
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
  #---------------------------------------------------------------------
  task :write => :ensure_term

  def default_term 
    return @_default_term if @_default_term
    @_default_term = {
      id: 'term/current',
      name: 'current',
      classification: 'legislative period',
    }
    # Merge in anything defined by the individual country
    @_default_term.merge! @current_term if @current_term
    @_default_term
  end

  task :ensure_term => :ensure_legislature do
    leg = @json[:organizations].find { |h| h[:classification] == 'legislature' } or raise "No legislature"
    unless leg.has_key?(:legislative_periods) and not leg[:legislative_periods].count.zero? 
      # use @TERM || @current_term || default_term()
      leg[:legislative_periods] = [ @TERMS || default_term ].flatten
    end
  end

  # Helper: expand data of all terms, if requested, by supplying @TERMS
  task :write => :add_term_dates
  task :add_term_dates => :ensure_term do
    if @TERMS
      leg = @json[:organizations].find { |h| h[:classification] == 'legislature' } or raise "No legislature"
      leg[:legislative_periods].each do |t|
        t.merge! @TERMS.find { |termdata| termdata[:id] == t[:id] }
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
      m[:legislative_period_id] ||= default_term[:id] 
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
