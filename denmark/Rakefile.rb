require 'csv'
require 'csv_to_popolo'

require_relative '../rakefile_common.rb'

@DEST = 'denmark'

task :process_json => [
  :ensure_legislative_period,
  :switch_party_to_behalf,
  :default_memberships_to_current_term
] 

