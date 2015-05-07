require_relative '../rakefile_popit.rb'

@POPIT = 'za-peoples-assembly'
@DEST = 'za'

@KEEP_ORG_TYPES = %w(executive parliament party)

namespace :whittle do

  task :no_orphaned_memberships => :clean_orphaned_people
    
  #TODO: remove Parliaments that aren't the National Assembly
  task :delete_unwanted_orgs => :load do
    # puts "Starting with #{@json[:organizations].count} orgs"
    keep = @json[:organizations].find_all { |o| @KEEP_ORG_TYPES.include? o[:classification].downcase }
    keepids = keep.map { |o| o[:id] }
    @json[:memberships].keep_if   { |m| keepids.include? m[:organization_id] }
    @json[:organizations].keep_if { |m| keepids.include? m[:id] }
    # puts "Ending with #{@json[:organizations].count} orgs"
  end

  # Delete everyone whose only Membership is to a Party
  task :clean_orphaned_people => :delete_unwanted_orgs do
    # puts "Starting with #{@json[:persons].count} people"
    orgt = Hash[@json[:organizations].map { |o| [ o[:id], o[:classification].downcase] } ]
    @json[:persons].delete_if { |p| 
      @json[:memberships].find_all { |m| 
        m[:person_id] == p[:id] and orgt[ m[:organization_id] ]!= 'party' 
      }.count.zero?
    }
    # puts "Ending with #{@json[:persons].count} people"
  end

  task :write => :remove_interest_register
  task :remove_interest_register => :clean_orphaned_people do
    @json[:persons].each { |p| p.delete :interests_register }
  end

end
