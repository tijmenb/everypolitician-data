require_relative '../../rakefile_morph.rb'

@MORPH = 'duncanparkes/monaco'
@MORPH_QUERY = 'SELECT id, name, party, area, image, email, term_id AS term, details_url AS source FROM data'
@MORPH_TERMS = true
@LEGISLATURE = {
  name: 'National Council',
  seats: 24
}
