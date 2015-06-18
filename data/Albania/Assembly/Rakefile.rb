require_relative '../../../rakefile_parldata.rb'

@PARLDATA = 'al/kuvendi'
@LEGISLATURE = {
  name: 'Kuvendi',
  seats: 140,
}

@FACTION_CLASSIFICATION = 'parliamentary_group'

namespace :whittle do
  task :standardise_terminology do
    # binding.pry
  end
end
