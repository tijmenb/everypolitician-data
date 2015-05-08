require_relative '../rakefile_morph.rb'

@DEST = 'bangladesh'
@MORPH = 'tmtmtmtm/bangladesh-parliament-scraper'
@LEGISLATURE = {
  name: 'Jatiyo Sangshad',
}

# From https://tr.wikipedia.org/wiki/T%C3%BCrkiye_B%C3%BCy%C3%BCk_Millet_Meclisi
@TERMS = [
  { 
    id: 'term/10',
    name: '10th Parliament',
    start_date: '2014-01-29',
  },
  { 
    id: 'term/9',
    name: '9th Parliament',
    start_date: '2009-01-25',
    end_date: '2014-01-24',
  },
]
