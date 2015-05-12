require_relative '../../rakefile_morph.rb'

@DEST = 'Brazil'
@MORPH = 'tmtmtmtm/brasil-deputados-scraper'
@LEGISLATURE = {
  name: 'National Congress'
}

# From https://en.wikipedia.org/wiki/National_Congress_of_Brazil
@TERMS = [
  { 
    id: 'term/55',
    name: '55th Legislature',
    start_date: '2015'
  },
  { 
    id: 'term/54',
    name: '54th Legislature',
    start_date: '2011',
    end_date: '2015',
  },
  { 
    id: 'term/53',
    name: '53rd Legislature',
    start_date: '2007',
    end_date: '2011',
  },
  { 
    id: 'term/52',
    name: '52nd Legislature',
    start_date: '2003',
    end_date: '2007',
  },
  { 
    id: 'term/51',
    name: '51st Legislature',
    start_date: '1999',
    end_date: '2003',
  },
  { 
    id: 'term/50',
    name: '50th Legislature',
    start_date: '1995',
    end_date: '1999',
  },
  { 
    id: 'term/49',
    name: '49th Legislature',
    start_date: '1991',
    end_date: '1995',
  },
  { 
    id: 'term/48',
    name: '48th Legislature',
    start_date: '1987',
    end_date: '1991',
  },
  { 
    id: 'term/47',
    name: '47th Legislature',
    start_date: '1983',
    end_date: '1987',
  },
  { 
    id: 'term/46',
    name: '46th Legislature',
    start_date: '1979',
    end_date: '1983',
  },
  { 
    id: 'term/45',
    name: '45th Legislature',
    start_date: '1975',
    end_date: '1979',
  },
  { 
    id: 'term/44',
    name: '44th Legislature',
    start_date: '1971',
    end_date: '1975',
  },
  { 
    id: 'term/43',
    name: '43rd Legislature',
    start_date: '1967',
    end_date: '1971',
  },
  { 
    id: 'term/42',
    name: '42nd Legislature',
    start_date: '1963',
    end_date: '1967',
  },
  { 
    id: 'term/41',
    name: '41st Legislature',
    start_date: '1959',
    end_date: '1962',
  },

]
