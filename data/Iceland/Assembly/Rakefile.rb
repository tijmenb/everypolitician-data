require_relative '../../../rakefile_morph.rb'

@MORPH = 'tmtmtmtm/iceland-althing-wp'
@MORPH_QUERY = "SELECT REPLACE(LOWER(name),' ','_') AS id, REPLACE(LOWER(party),' ','_') AS party_id, * FROM data"

@LEGISLATURE = {
  name: 'Alþingi',
  seats: 63,
}

