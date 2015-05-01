require_relative '../rakefile_popit.rb'

@POPIT = 'iran-test'
@DEST = 'iran'

@current_term = { 
  id: "term/9",
  name: "9th Assembly",
  start_date: "2012-05-27",
}

task :process_json => :default_memberships_to_current_term
