require 'json'
require 'open-uri'
require 'rake/clean'
require 'pry'

CLEAN.include('final.json')

Numeric.class_eval { def empty?; false; end }

task :rebuild => [ :clean, 'final.json' ]

task :default => 'final.json'

task :load_json => 'clean.json' do
  @json = JSON.parse(File.read('clean.json'), symbolize_names: true )
end

task :process_json => :ensure_memberships_have_term

file 'final.json' => :process_json do
  File.write('final.json', JSON.pretty_generate(@json))
end  




task :clean_orphaned_memberships => :load_json do
  @json[:memberships].keep_if { |m|
    @json[:organizations].find { |o| o[:id] == m[:organization_id] } and
    @json[:persons].find { |p| p[:id] == m[:person_id] } 
  }
end  

task :ensure_legislature_exists => :load_json do
  if @json[:organizations].find_all { |h| h[:classification] == 'legislature' }.count.zero?
    @json[:organizations] << {
      classification: "legislature",
      name: "Legislature",
      id: "legislature",
    }
  end
end

task :name_legislature => :ensure_legislature_exists do
  if (@LEGISLATURE)
    leg = @json[:organizations].find_all { |h| h[:classification] == 'legislature' }
    raise "More than one legislature exists, and @LEGISLATURE set" if leg.count > 1
    leg.first.merge! @LEGISLATURE
  end
end

task :build_term_info do
  @_default_term = {
    id: 'term/current',
    name: 'current',
    classification: 'legislative period',
  }
  @_default_term.merge! @current_term if @current_term
end

task :ensure_legislative_period => [ :name_legislature, :build_term_info ] do
  leg = @json[:organizations].find { |h| h[:classification] == 'legislature' } or raise "No legislature"
  unless leg.has_key?(:legislative_periods) and not leg[:legislative_periods].count.zero? 
    # TODO extend this also allow simple provision of historic terms
    leg[:legislative_periods] = [ @_default_term ]
  end
end

task :switch_party_to_behalf => :ensure_legislature_exists do
  # TODO: Only works if *all* other Orgs are Parties
  # TODO: Only works for unicameral legislature
  @json[:organizations].find_all { |h| h[:classification] != 'legislature' }.each do |o|
    @json[:memberships].find_all { |m| m[:organization_id] == o[:id] }.each do |m|
      m[:role] = 'member'
      m[:on_behalf_of_id] = o[:id]
      m[:organization_id] = 'legislature'
    end
  end
end

task :ensure_memberships_have_term => :ensure_legislative_period do
  leg_ids = @json[:organizations].find_all { |o| %w(legislature chamber).include? o[:classification] }.map { |o| o[:id] }
  @json[:memberships].find_all { |m| m[:role] == 'member' and leg_ids.include? m[:organization_id] }.each do |m|
    m[:legislative_period_id] ||= @_default_term[:id] 
  end
end


