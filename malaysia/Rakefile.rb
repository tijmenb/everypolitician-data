require 'csv'
require 'csv_to_popolo'

require_relative '../rakefile_common.rb'

@POPIT = 'sinar-malaysia'
@DEST = 'malaysia'

task :my_fixup_orgs => :load_json do

  if o = @json[:organizations].find { |o| o[:name] == 'Parliament of Malaysia' } 
    o[:classification] = 'Legislature'
  end

  if o = @json[:organizations].find { |o| o[:name] == 'House of Representatives' } 
    o[:classification] = 'Chamber'
  end

  if o = @json[:organizations].find { |o| o[:name] == 'Senate' } 
    o[:classification] = 'Chamber'
  end

  if o = @json[:organizations].find { |o| o[:name] == "Malaysian People's Movement Party" } 
    o[:classification] = 'Party'
  end

  if o = @json[:organizations].find { |o| o[:name] == "Cabinet of Malaysia" } 
    o[:classification] = 'Executive'
  end

end

task :clean_orphaned_people => :clean_orphaned_memberships do
  keep_people = @json[:memberships].map { |m| m[:person_id] }
  @json[:persons].keep_if { |p| keep_people.include? p[:id] }
end

task :remove_unwanted_orgs => :my_fixup_orgs do
  keep_type = ['Executive', 'Legislature', 'Chamber', 'Party' ]
  keep_orgs = @json[:organizations].find_all { |o| keep_type.include? o[:classification] }.map { |o| o[:id] }
  @json[:memberships].keep_if   { |m| keep_orgs.include? m[:organization_id] }
  @json[:organizations].keep_if { |m| keep_orgs.include? m[:id] }
end


task :process_json => [
  :my_fixup_orgs,
  :remove_unwanted_orgs,
  :clean_orphaned_memberships, 
  :clean_orphaned_people,
  :ensure_legislative_period,
  :default_memberships_to_current_term
] 

