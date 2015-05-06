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

task 'final.json' => :add_term_dates
task :add_term_dates => :ensure_legislative_period do
  parl = @json[:organizations].find { |h| h[:classification] == 'legislature' } or raise "No legislature"
  parl[:legislative_periods].each do |t|
    t.merge! @TERMS.find { |termdata| termdata[:id] == t[:id] }
  end
end


