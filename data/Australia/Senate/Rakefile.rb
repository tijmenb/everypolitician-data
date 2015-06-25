require_relative '../../../rakefile_morph.rb'

@MORPH = 'openaustralia/aus_mp_contact_details'
@MORPH_QUERY = "SELECT aph_id AS id, full_name AS name, electorate AS constituency, photo_url AS photo, REPLACE(LOWER(party),' ','_') AS party_id, * FROM data WHERE house = 'senate'"

@LEGISLATURE = {
  name: 'Senate',
  seats: 76,
}

@TERMS = [{ 
  id: 'term/44',
  name: '44th Parliament',
  start_date: '2013-09-07',
}]
