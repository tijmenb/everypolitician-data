require_relative '../rakefile_morph.rb'

@DEST = 'mongolia'
@MORPH = 'tmtmtmtm/mongolia-khurai-wp'
@LEGISLATURE = {
  name: 'State Great Khural'
}

# From https://tr.wikipedia.org/wiki/T%C3%BCrkiye_B%C3%BCy%C3%BCk_Millet_Meclisi
@TERMS = [
  { 
    id: 'term/2012',
    name: 'State Grand Khural 2012–',
    start_date: '2012-06-28',
  },
  { 
    id: 'term/2008',
    name: 'State Grand Khural 2008–2012',
    start_date: '2008-07-23',
    end_date: '2012-06-28',
  },
]

