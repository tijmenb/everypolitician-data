require_relative 'rakefile_common.rb'

require 'erb'
require 'csv_to_popolo'
require 'fileutils'

@SOURCE_DIR = 'sources/morph'
@MORPH_DATA_FILE = @SOURCE_DIR + '/data.csv'
@MORPH_TERM_FILE = @SOURCE_DIR + '/terms.csv'

def morph_select(qs)
  morph_api_key = ENV['MORPH_API_KEY'] or fail 'Need a Morph API key'
  key = ERB::Util.url_encode(morph_api_key)
  query = ERB::Util.url_encode(qs.gsub(/\s+/, ' ').strip)
  url = "https://api.morph.io/#{@MORPH}/data.csv?key=#{key}&query=#{query}"
  STDERR.puts "Fetching #{url}"
  open(url).read
end

namespace :raw do
  @DEFAULT_MORPH_DATA_QUERY = 'SELECT * FROM data'
  @DEFAULT_MORPH_TERM_QUERY = 'SELECT * FROM terms'
  FileUtils.mkpath @SOURCE_DIR

  file @MORPH_DATA_FILE do
    File.write(@MORPH_DATA_FILE, morph_select(@MORPH_QUERY || @DEFAULT_MORPH_DATA_QUERY)) unless File.exist? @MORPH_DATA_FILE
  end

  file @MORPH_DATA_FILE => :get_terms
  task :get_terms do
    if @MORPH_TERMS and not File.exist? @MORPH_TERM_FILE
      File.write(@MORPH_TERM_FILE, morph_select(@MORPH_TERM_QUERY || @DEFAULT_MORPH_TERM_QUERY))
    end
  end
end

namespace :whittle do
  CLOBBER.exclude 'clean.json'

  task load: @MORPH_DATA_FILE do
    @SOURCE = "https://morph.io/#{@MORPH}"
    @json = Popolo::CSV.new(@MORPH_DATA_FILE).data
  end
end
