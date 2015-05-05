require_relative '../rakefile_morph.rb'

@DEST = 'turkey'
@MORPH = 'tmtmtmtm/turkey-tbmm-wp'
@LEGISLATURE = {
  name: 'Grand National Assembly'
}

@TERMS = [
  { 
    id: 'term/24',
    name: '24th Parliament',
  },
  { 
    id: 'term/23',
    name: '23rd Parliament',
  },
  { 
    id: 'term/22',
    name: '22nd Parliament',
  },
  { 
    id: 'term/21',
    name: '21st Parliament',
  },
  { 
    id: 'term/20',
    name: '20th Parliament',
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


