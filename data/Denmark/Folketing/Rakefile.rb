require_relative '../../../rakefile_popit.rb'

namespace :whittle do

  task :no_orphaned_memberships => :dk_remove_not_current
  task :dk_remove_not_current => :load do
    @json[:persons].keep_if { |p| p[:data] && p[:data][:currentMP] && p[:data][:currentMP].first == 'y' }
  end

end

namespace :transform do

  task :write => :add_party_names
  task :add_party_names => :load do
    # from https://en.wikipedia.org/wiki/List_of_members_of_the_Folketing
    parties = { 
      'A' => 'Social Democrats',
      'B' => 'Danish Social Liberal Party',
      'C' => 'Conservative People‘s Party',
      'F' => 'Socialist People‘s Party',
      'I' => 'Liberal Alliance',
      'O' => 'Danish People‘s Party',
      'K' => 'Christian Democrats',
      'V' => 'Venstre',
      'Ø' => 'Red–Green Alliance',
    }
    @json[:organizations].each do |o|
      if fullname = parties[o[:name]]
        oldid = o[:id]
        o[:id] = o[:name]
        o[:name] = fullname
        @json[:memberships].each { |m| m[:on_behalf_of_id] = o[:id] if m[:on_behalf_of_id] == oldid }
      end 
    end
  end

  # This helper only works because the only other Orgs are the Parties 
  # But make sure it's run before the default version
  task :ensure_membership_terms => :create_on_behalf_ofs
  task :create_on_behalf_ofs => :ensure_legislature do
    @json[:organizations].find_all { |h| h[:classification] != 'legislature' }.each do |o|
      @json[:memberships].find_all { |m| m[:organization_id] == o[:id] }.each do |m|
        m[:role] = 'member'
        m[:on_behalf_of_id] = o[:id]
        m[:organization_id] = 'legislature'
      end
    end
  end

end
