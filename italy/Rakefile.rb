require_relative '../rakefile_common.rb'

@POPIT = 'parlamento-test'
@DEST = 'italy'

@current_term = { 
  id: 'legislatura/17',
  name: 'XVII Legislatura',
  start_date: '2013-03-15'
}

task :process_json => :default_memberships_to_current_term
