require_relative '../rakefile_popit.rb'

@POPIT = 'za-peoples-assembly'
@DEST = 'za'

@KEEP_ORG_TYPES = %w(executive parliament party)

namespace :whittle do

  task :no_orphaned_memberships => :clean_orphaned_people
    
  #TODO: remove Parliaments that aren't the National Assembly
  task :delete_unwanted_orgs => :load do
    puts "We start with #{@json[:organizations].count} orgs"
    keep = @json[:organizations].find_all { |o| @KEEP_ORG_TYPES.include? o[:classification].downcase }
    keepids = keep.map { |o| o[:id] }
    @json[:memberships].keep_if   { |m| keepids.include? m[:organization_id] }
    @json[:organizations].keep_if { |m| keepids.include? m[:id] }
    puts "We now have #{@json[:organizations].count} orgs"
  end

  # Remove everyone who's not in any remaining organizations
  task :clean_orphaned_people => :delete_unwanted_orgs do
    keep_people = @json[:memberships].map { |m| m[:person_id] }
    @json[:persons].keep_if { |p| keep_people.include? p[:id] }
  end

  task :write => :remove_interest_register
  task :remove_interest_register => :clean_orphaned_people do
    @json[:persons].each { |p| p.delete :interests_register }
  end

end
