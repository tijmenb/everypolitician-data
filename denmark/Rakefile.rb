require 'csv'
require 'csv_to_popolo'

require_relative '../rakefile_common.rb'

@DEST = 'denmark'

task :dk_remove_not_current => :load_json do
  @json[:persons].keep_if { |p| p[:data] && p[:data][:currentMP] && p[:data][:currentMP].first == 'y' }
end

task :clean_orphaned_memberships => :dk_remove_not_current

task :process_json => [
  :dk_remove_not_current,
  :clean_orphaned_memberships,
  :ensure_legislative_period,
  :switch_party_to_behalf,
  :default_memberships_to_current_term
] 

