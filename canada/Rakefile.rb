require_relative '../rakefile_popit.rb'

@POPIT = 'canada-commons'
@DEST = 'canada'

@current_term = { 
  id: "term/41",
  name: "41st Canadian Parliament",
  start_date: "2011-06-02",
}

task :process_json => :default_memberships_to_current_term
