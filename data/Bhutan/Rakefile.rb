require_relative '../../rakefile_morph.rb'

@MORPH = 'tmtmtmtm/bhutan-national-assembly'
@LEGISLATURE = {
  name: 'National Assembly',
  seats: 47,
}

# http://www.nab.gov.bt/about/parliament-session
@TERMS = [
  {
    id: 'term/1',
    name: "1st Parliament",
    start_date: '2008-03-01',
    end_date: '2013-04-30',
  },
  {
    id: 'term/2',
    name: "2nd Parliament",
    start_date: '2013-07-01',
  },
]
