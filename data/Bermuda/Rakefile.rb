require_relative '../../rakefile_morph.rb'

@MORPH = 'tmtmtmtm/bermuda_parliament'
@LEGISLATURE = {
  name: 'Parliament',
  seats: 36,
}

file 'morph.csv' => 'terms.csv'

