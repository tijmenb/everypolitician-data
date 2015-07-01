require_relative 'rakefile_common.rb'
require_relative 'lib/builder.rb'

require 'erb'
require 'csv_to_popolo'
require 'fileutils'
require 'json'
require 'pry'

def json_load(file)
  return unless File.exist? file
  JSON.parse(File.read(file), symbolize_names: true)
end


@SOURCE_DIR = 'sources/morph'

if instructions = json_load("#{@SOURCE_DIR}/instructions.json")
  @MORPH = instructions[:source] or raise "No `source` in instructions.json"
  @MORPH_TERMS = instructions[:fetch_terms]
  @MORPH_QUERY = instructions[:query]
  @MORPH_TERM_QUERY = instructions[:term_query]
end

@MORPH_DATA_FILE = @SOURCE_DIR + '/data.csv'

namespace :raw do
  file 'sources/morph/data.csv' do
    builder = EveryPolitician::Builder::Morph.new(
      @MORPH, 
      get_terms: @MORPH_TERMS, 
      data_query: @MORPH_QUERY,
      term_query: @MORPH_TERM_QUERY,
    )
    builder.fetch! 
  end
end

namespace :whittle do
  task load: @MORPH_DATA_FILE do
    @SOURCE = "https://morph.io/#{@MORPH}"
    @json = Popolo::CSV.new(@MORPH_DATA_FILE).data
  end
end
