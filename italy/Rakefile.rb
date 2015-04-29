require_relative '../rakefile_common.rb'

@POPIT = 'parlamento-test'
@DEST = 'italy'

task :process_json => :default_memberships_to_current_term
