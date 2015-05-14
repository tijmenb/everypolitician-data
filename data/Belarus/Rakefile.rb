require_relative '../../rakefile_morph.rb'
require 'csv'

@MORPH = 'duncanparkes/belarus'
@LEGISLATURE = {
  name: 'National Assembly'
}
@CSV_FILE = 'processed.csv'

@TERMS = [{
  id: "term/2012",
  name: "2012",
  start_date: "2012-09-23",
}]

# http://www.comparty.by/deputati
@comparty = [
  'ZHILINSKY MARAT',
  'ZHURAVSKAYA VALENTINA',
  'KLIMOVICH NATALIA',
  'KUBRAKOVA LIUDMILA',
  'KUZMICH ALEKSEY',
  'LEONENKO VALENTINA',
]

namespace :whittle do
  task :load => 'processed.csv'

  file 'processed.csv' => 'morph.csv' do
    morph = CSV.read('morph.csv', headers: true)
    headers = morph.headers.to_csv
    morph.each do |row|
      row['party'] = 'Communist Party of Belarus' if @comparty.include? row['name']
    end
    output = morph.map { |row| row.to_hash.values.to_csv }.join
    File.write('processed.csv', headers + output)
  end

end
