require 'json'
require 'open-uri'
require 'rake/clean'
require 'pry'

CLEAN.include('final.json')

Numeric.class_eval { def empty?; false; end }

@JSON_FILE = 'popit.json'

file 'popit.json' do 
  popit_src = @POPIT_URL || "https://#{@POPIT || @DEST}.popit.mysociety.org/api/v0.1/export.json"
  File.write('popit.json', open(popit_src).read) 
end

task :rebuild => [ :clean, 'final.json' ]

task :default => 'final.json'

task :load_json => 'popit.json' do
  @json = JSON.load(File.read(@JSON_FILE), lambda { |h| 
    if h.class == Hash 
      h.reject! { |_, v| v.nil? or v.empty? }
      h.reject! { |k, v| (k == :url or k == :html_url) and v[/popit.mysociety.org/] }
    end
  }, { symbolize_names: true })
end

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

task :build_term_info do
  @_default_term = {
    id: 'term/current',
    name: 'current',
    classification: 'legislative period',
  }
  @_default_term.merge! @current_term if @current_term
end

task :ensure_legislative_period => [ :ensure_legislature_exists, :build_term_info ] do
  leg = @json[:organizations].find { |h| h[:classification] == 'legislature' } or raise "No legislature"
  unless leg.has_key?(:legislative_periods) and not leg[:legislative_periods].count.zero? 
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

task :default_memberships_to_current_term => [:ensure_legislative_period] do
  leg_ids = @json[:organizations].find_all { |o| %w(legislature chamber).include? o[:classification] }.map { |o| o[:id] }
  @json[:memberships].find_all { |m| m[:role] == 'member' and leg_ids.include? m[:organization_id] }.each do |m|
    m[:legislative_period_id] ||= @_default_term[:id] 
  end
end

# Individual country files should extend this
task :process_json => :load_json


