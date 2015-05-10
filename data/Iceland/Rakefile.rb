require_relative '../../rakefile_morph.rb'

@DEST = 'iceland'
@MORPH = 'tmtmtmtm/iceland-althing-wp'
@LEGISLATURE = {
  name: 'Alþingi'
}

namespace :transform do

  task :write => :add_term_dates
  task :add_term_dates => :ensure_term do
    parl = @json[:organizations].find { |h| h[:classification] == 'legislature' } or raise "No legislature"
    terms = parl[:legislative_periods].sort_by { |t| t[:name] }
    terms.each_with_index do |t, i|
      t[:start_date] = t[:name].clone
      t[:end_date] = terms[i+1][:name].clone unless i+1 == terms.size
      t[:name].prepend 'Alþingi '
    end
  end

end

