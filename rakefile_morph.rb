
require_relative 'rakefile_common.rb'

require 'erb'
require 'csv'
require 'csv_to_popolo'


def morph_select(qs)
  morph_api_key = ENV['MORPH_API_KEY'] or raise "Need a Morph API key"
  key = ERB::Util.url_encode(morph_api_key)
  query = ERB::Util.url_encode(qs.gsub(/\s+/, ' ').strip)
  url = "https://api.morph.io/#{@MORPH}/data.csv?key=#{key}&query=#{query}"
  STDERR.puts "Fetching #{url}"
  return open(url).read
end

namespace :raw do

  @DEFAULT_MORPH_QUERY = 'SELECT * FROM data'

  file 'morph.csv' do
    File.write('morph.csv', morph_select(@MORPH_QUERY || @DEFAULT_MORPH_QUERY))
  end

end
   
namespace :whittle do
  CLOBBER.exclude 'clean.json'

  task :load => 'morph.csv' do
    @SOURCE = "https://morph.io/#{@MORPH}"
    @json = Popolo::CSV.new(@CSV_FILE || 'morph.csv').data
  end


end
