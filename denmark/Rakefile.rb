require 'csv'
require 'csv_to_popolo'

require_relative '../rakefile_common.rb'

@DEST = 'denmark'

@current_term = { 
  id: 'term/2011',
  name: 'Folketing 2011–15',
  start_date: '2011-09-15'
}

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

task :process_json => [
  :dk_remove_not_current,
  :clean_orphaned_memberships,
  :add_party_names,
  :ensure_legislative_period,
  :switch_party_to_behalf,
  :default_memberships_to_current_term,
] 

