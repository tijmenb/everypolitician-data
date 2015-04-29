require_relative '../rakefile_common.rb'

@DEST = 'wales'

@current_term = { 
  id: 'term/4',
  name: 'Fourth Assembly',
  start_date: '2011-09-15',
}

task :process_json => :default_memberships_to_current_term
