require_relative 'rakefile_common.rb'
require_relative 'lib/builder.rb'

require 'erb'
require 'csv_to_popolo'
require 'fileutils'

@SOURCE_DIR = 'sources/morph'
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
