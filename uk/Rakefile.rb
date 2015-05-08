require_relative '../rakefile_common.rb'

require 'csv'
require 'csv_to_popolo'

@DEST = 'uk'
@LEGISLATURE = {
  name: 'House of Commons'
}

@current_term = { 
  id: 'term/2015',
  name: 'House of Commons 2015–',
  start_date: '2015'
}


namespace :raw do
  file 'candidates.csv' do
    warn "Refetching CSV"
    File.write('candidates.csv', open('https://edit.yournextmp.com/media/candidates.csv').read)
  end
end

namespace :winners do
  file 'winners.csv' => 'candidates.csv' do
    all = CSV.read('candidates.csv', headers: true)
    headers = all.headers.to_csv
    winners = all.find_all { |row| row['elected'] == 'True' }
    output = winners.map { |row| row.to_hash.values.to_csv }.join
    File.write('winners.csv', headers + output)
  end
end

namespace :whittle do
  task :load => 'winners.csv' do
    @json = Popolo::CSV.new('winners.csv').data
  end

end

