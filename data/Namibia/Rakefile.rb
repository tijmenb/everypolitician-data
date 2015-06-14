require_relative '../../rakefile_morph.rb'

@MORPH = 'duncanparkes/namibia'
@MORPH_QUERY = "SELECT data.id, data.name, data.image, data.party, data.party AS party_id, terms.term_number AS term, data.email, data.area, data.details_url AS source from data JOIN terms ON data.term_id = terms.id WHERE chamber = 'National Assembly'"

@MORPH_TERMS = true
@MORPH_TERM_QUERY = 'SELECT term_number AS id, * FROM terms'

@LEGISLATURE = {
  name: 'National Assembly'
}

