require_relative '../rakefile_popit.rb'

@POPIT = 'inatsisartut'
@DEST = 'greenland'
@LEGISLATURE = {
  name: 'Inatsisartut',
}

namespace :transform do

  task :write => :fix_term_dates
  task :fix_term_dates => :ensure_term do
    parl = @json[:organizations].find { |h| h[:classification] == 'legislature' } or raise "No legislature"
    terms = parl[:legislative_periods].sort_by { |p| p[:name] }
    terms.each_with_index do |p, i|
      p[:start_date] = p[:name]
      p[:name] = "Inatsisartut #{i+1}"
      unless (i+1 == terms.size)
        p[:end_date] = Date.parse(terms[i+1][:name]) - 1
      end
    end
  end

end

