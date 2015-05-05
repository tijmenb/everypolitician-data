require_relative '../rakefile_morph.rb'

@DEST = 'turkey'
@MORPH = 'tmtmtmtm/turkey-tbmm-wp'
@LEGISLATURE = {
  name: 'Grand National Assembly'
}

# From https://tr.wikipedia.org/wiki/T%C3%BCrkiye_B%C3%BCy%C3%BCk_Millet_Meclisi
@TERMS = [
  { 
    id: 'term/24',
    name: '24th Parliament',
    start_date: '2011-06-28',
  },
  { 
    id: 'term/23',
    name: '23rd Parliament',
    start_date: '2007-07-23',
    end_date: '2011-06-28',
  },
  { 
    id: 'term/22',
    name: '22nd Parliament',
    start_date: '2002-11-14',
    end_date: '2007-07-23',
  },
  { 
    id: 'term/21',
    name: '21st Parliament',
    start_date: '1999-04-18',
    end_date: '2002-11-14',
  },
  { 
    id: 'term/20',
    name: '20th Parliament',
    start_date: '1996-01-08',
    end_date: '1999-04-18',
  },
]

task 'final.json' => :add_term_dates
task :add_term_dates => :ensure_legislative_period do
  parl = @json[:organizations].find { |h| h[:classification] == 'legislature' } or raise "No legislature"
  parl[:legislative_periods].each do |t|
    warn "Term #{t}"
    t.merge! @TERMS.find { |termdata| termdata[:id] == t[:id] }
    warn "\tNow #{t}"
  end
end


