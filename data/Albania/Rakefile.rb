require_relative '../../rakefile_parldata.rb'

@PARLDATA = 'al/kuvendi'
@LEGISLATURE = {
  name: 'Kuvendi'
}
@FACTION_CLASSIFICATION = 'parliamentary_group'

namespace :whittle do
  task :standardise_terminology do
    # binding.pry
  end
end
