
require_relative '../rakefile_common.rb'

@DEST = 'australia'
@POPIT = 'australia-test'


task :connect_chambers => :ensure_legislature_exists do
  better_name = { 
    'senate' => 'Senate',
    'representatives' => 'House of Representatives',
  }
  @json[:organizations].find_all { |h| h[:classification] == 'chamber' }.each do |c|
    c[:name] = better_name[c[:name]] || c[:name]
    c[:parent_id] ||= 'legislature'
  end
end

task :add_legislative_period => :ensure_legislature_exists do
  # Don't use the default one, because we have info
  # http://en.wikipedia.org/wiki/Chronology_of_Australian_federal_parliaments
  # Let's simply deal with Parliaments, ignoring the 6-year Senate

  leg = @json[:organizations].find { |h| h[:classification] == 'legislature' } or raise "No legislature"
  unless leg.has_key?(:legislative_periods) and not leg[:legislative_periods].count.zero? 
    leg[:legislative_periods] = [{
      id: 'term/44',
      name: '44th Parliament',
      start_date: '2013-09-07',
      classification: 'legislative period',
    }]
  end

  chambers = @json[:organizations].find_all { |h| h[:classification] == 'chamber' } or raise "No chambers"
  chamber_ids = chambers.map { |c| c[:id] }
  @json[:memberships].find_all { |m| m[:role] == 'member' && chamber_ids.include?(m[:organization_id]) }.each do |m|
    m[:legislative_period_id] ||= 'term/44'
  end
  
end

task :process_json => [
  :load_json, 
  :connect_chambers,
  :add_legislative_period,
] 

