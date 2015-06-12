require_relative '../../rakefile_morph.rb'

@MORPH = 'duncanparkes/tonga'
@MORPH_TERMS = true
@MORPH_QUERY = "SELECT id, name, constituency, 'unknown' AS party, term_id AS term, image, email, phone, cell, details_url AS source FROM data"
@LEGISLATURE = {
  name: 'Legislative Assembly',
  seats: 26
}
