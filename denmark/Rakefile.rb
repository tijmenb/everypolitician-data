require_relative '../rakefile_popit.rb'

@DEST = 'denmark'
@LEGISLATURE = {
  name: 'Folketing'
}

@current_term = { 
  id: 'term/2011',
  name: 'Folketing 2011–15',
  start_date: '2011-09-15'
}

namespace :whittle do

  task :no_orphaned_memberships => :dk_remove_not_current
  task :dk_remove_not_current => :load do
    @json[:persons].keep_if { |p| p[:data] && p[:data][:currentMP] && p[:data][:currentMP].first == 'y' }
  end

end

namespace :transform do

  # safe to trigger the 'simple' behalf_of switcher
  task :ensure_membership_terms => :ensure_behalf_of

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
        o[:other_names] = [{
          name: o[:name],
        }]
        o[:name] = fullname
      end 
    end
  end

end
