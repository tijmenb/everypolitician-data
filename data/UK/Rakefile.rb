require_relative '../../rakefile_common.rb'

require 'csv'
require 'csv_to_popolo'

@LEGISLATURE = {
  name: 'House of Commons',
  seats: 650,
}

@TERMS = [{ 
  id: 'term/2015',
  name: 'House of Commons 2015–',
  start_date: '2015'
}]


namespace :raw do
  file 'candidates.csv' do
    warn "Refetching CSV"
    File.write('candidates.csv', open('https://edit.yournextmp.com/media/candidates.csv').read)
  end
end

namespace :winners do
  file 'winners.csv' => 'candidates.csv' do
    remap_csv_headers = {
      'twitter_username' => 'twitter',
      'facebook_page_url' => 'facebook',
      'homepage_url' => 'homepage',
      'wikipedia_url' => 'wikipedia',
      'linkedin_url' => 'linkedin',
    }
    all = CSV.read('candidates.csv', {
      headers: true, 
      header_converters: lambda { |h| 
        hc = h.to_s.encode(::CSV::ConverterEncoding).downcase.gsub(/\s+/, "_").gsub(/\W+/, "")
        (remap_csv_headers[hc] || hc).to_sym
      }
    })
    headers = all.headers.to_csv
    winners = all.find_all { |row| row[:elected] == 'True' }
    output = winners.map { |row| row.to_hash.values.to_csv }.join
    File.write('winners.csv', headers + output)
  end
end

namespace :whittle do
  task :load => 'winners.csv' do
    @SOURCE = 'https://yournextmp.com/'
    @json = Popolo::CSV.new('winners.csv').data
  end

  task :write => :rename_party
  task :rename_party => :load do
    @json[:organizations].find_all { |o| o[:name] == 'Speaker seeking re-election' }.each do |o|
      o[:name] = 'Speaker'
    end
  end

end

