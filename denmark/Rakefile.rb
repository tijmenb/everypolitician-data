require 'csv'
require 'csv_to_popolo'

require_relative '../rakefile_common.rb'

@DEST = 'denmark'

task :dk_remove_not_current => :load_json do
  @json[:persons].keep_if { |p| p[:data] && p[:data][:currentMP] && p[:data][:currentMP].first == 'y' }
end

# Don't clean up until we've removed things
task :clean_orphaned_memberships => :dk_remove_not_current

task :add_party_names => :load_json do
  # from https://en.wikipedia.org/wiki/List_of_members_of_the_Folketing
  parties = { 
    'A' => 'Social Democrats',
    'B' => 'Danish Social Liberal Party',
    'C' => 'Conservative People‘s Party',
    'F' => 'Socialist People‘s Party',
    'I' => 'Liberal Alliance',
    'O' => 'Danish People‘s Party',
    'K' => 'Christian Democrats',
    'V' => 'Venstre',
    'Ø' => 'Red–Green Alliance',
  }
  @json[:organizations].each do |o|
    if fullname = parties[o[:name]]
      o[:other_names] = [{
        name: o[:name],
      }]
      o[:name] = fullname
    end 
  end
end

task :rename_current_term => :default_memberships_to_current_term do
  leg = @json[:organizations].find { |h| h[:classification] == 'legislature' } or raise "No legislature"
  if term = leg[:legislative_periods].find { |h| h[:id] == 'term/current' }
    term[:id] = 'term/2011'
    term[:name] = 'Folketing 2011–15'
    term[:start_date] = '2011-09-15'
  end

  @json[:memberships].find_all { |m| m[:legislative_period_id] == 'term/current' }.each do |mem|
    mem[:legislative_period_id] = 'term/2011'
  end
end
  
task :process_json => [
  :dk_remove_not_current,
  :clean_orphaned_memberships,
  :add_party_names,
  :ensure_legislative_period,
  :switch_party_to_behalf,
  :default_memberships_to_current_term,
  :rename_current_term,
] 

