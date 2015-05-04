require_relative '../rakefile_morph.rb'

@DEST = 'iceland'
@MORPH = 'tmtmtmtm/iceland-althing-wp'

task 'final.json' => :add_term_dates
task :add_term_dates => :ensure_legislative_period do
  parl = @json[:organizations].find { |h| h[:classification] == 'legislature' } or raise "No legislature"
  parl[:legislative_periods].each do |t|
    (start_date, end_date) = t[:name].split(/\D+/)
    t[:start_date] = start_date if start_date
    t[:end_date] = end_date if end_date
  end
end


