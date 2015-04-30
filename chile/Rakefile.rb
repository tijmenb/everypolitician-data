require_relative '../rakefile_common.rb'

@POPIT = 'pmocl'
@DEST = 'chile'

@current_term = { 
  id: "term/2014",
  name: "Legislativo 2014-2018",
  start_date: "2014-03-11",
  end_date: "2018-03-10",
}

# Must be done in correct order
task :default_memberships_to_current_term => :switch_party_to_behalf

task :process_json => [
  :clean_orphaned_memberships, 
  :ensure_legislative_period,
  :default_memberships_to_current_term
] 
