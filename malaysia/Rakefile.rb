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

task :downcase_classifications => :my_fixup_orgs do
  @json[:organizations].each { |o| o[:classification] = o[:classification].to_s.downcase } 
end


task :clean_orphaned_people => :clean_orphaned_memberships do
  keep_people = @json[:memberships].map { |m| m[:person_id] }
  @json[:persons].keep_if { |p| keep_people.include? p[:id] }
end

task :remove_candidates => :remove_unwanted_orgs do
  @json[:memberships].delete_if { |m| m[:role].to_s.include? 'Candidate' }
  @json[:memberships].delete_if { |m| m[:role].to_s.include? 'State Assembly Representative' }
end

task :remove_unwanted_orgs => :downcase_classifications do
  keep_type = ['executive', 'legislature', 'chamber', 'party' ]
  keep_orgs = @json[:organizations].find_all { |o| keep_type.include? o[:classification] }.map { |o| o[:id] }
  @json[:memberships].keep_if   { |m| keep_orgs.include? m[:organization_id] }
  @json[:organizations].keep_if { |m| keep_orgs.include? m[:id] }
end


task :process_json => [
  :my_fixup_orgs,
  :downcase_classifications,
  :remove_unwanted_orgs,
  :remove_candidates,
  :clean_orphaned_memberships, 
  :clean_orphaned_people,
  :ensure_legislative_period,
  :default_memberships_to_current_term
] 

