
require_relative '../../rakefile_parldata.rb'

@PARLDATA = [ 'cz/psp', 'cz/senat' ]
@LEGISLATURE = {
  name: 'Parlament',
  seats: {
    psp: 200,
    senat: 81,
  },
}
@FACTION_CLASSIFICATION = 'political group'
@MEMBERSHIP_GROUPING = 'faction'


