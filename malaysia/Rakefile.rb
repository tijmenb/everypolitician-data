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

task :clean_orphaned_memberships => :clean_memberships_to_missing_posts

task :clean_memberships_to_missing_posts => :load_json do
  all_post_ids = @json[:posts].map { |post| post[:id] }
  # @json[:memberships].keep_if { |m| m[:post_id].nil? or all_post_ids.include? m[:post_id] }
  @json[:memberships].each { |m| 
    next if m[:post_id].nil?
   raise "Orphaned" unless all_post_ids.include? m[:post_id] 
  }
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

task :my_fixup_behalfs => :clean_orphaned_people do
  # Every Member of Parliament has an associated Parliament Representative — merge these

  @json[:memberships].find_all { |o| o[:role] == 'Parliament Representative' }.each do |rep|
    matching = @json[:memberships].find_all { |m| 
      m[:person_id] == rep[:person_id] and
      # m[:post_id] == rep[:post_id] and
      m[:start_date] == rep[:start_date] and
      m[:end_date] == rep[:end_date] and
      m[:role] == 'Member of Parliament' 
    } or raise "No matching MP membership for #{rep}" 
    require 'pry'
    binding.pry
    raise "Too many MP memberships for #{rep}: #{matching}" if matching.count > 1
    
  end

end



task :process_json => [
  :my_fixup_orgs,
  :downcase_classifications,
  :remove_unwanted_orgs,
  :remove_candidates,
  :clean_orphaned_memberships, 
  :clean_orphaned_people,
  :my_fixup_behalfs,
  :ensure_legislative_period,
  :default_memberships_to_current_term
] 

