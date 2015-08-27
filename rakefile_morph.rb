require_relative 'rakefile_common.rb'
require_relative 'lib/fetcher.rb'

require 'csv_to_popolo'
require 'pry'
require 'rake/clean'
require 'colorize'

@SOURCE_DIR = 'sources/morph'
CLOBBER.include(FileList.new('sources/morph/*.csv'))

@MORPH_DATA_FILE   = @SOURCE_DIR + '/data.csv'
@INSTRUCTIONS_FILE = @SOURCE_DIR + '/instructions.json'

namespace :raw do
  file 'sources/morph/data.csv' do
    EveryPolitician::Fetcher::Morph.new(
      instructions(:source), 
      get_terms: instructions(:fetch_terms),
      data_query: instructions(:query),
      term_query: instructions(:term_query),
    ).fetch! 
  end
end

namespace :whittle do
  task load: @MORPH_DATA_FILE do
    @SOURCE = "https://morph.io/#{instructions(:source)}"
    @json = Popolo::CSV.new(@MORPH_DATA_FILE).data
  end
end

task :migrate_rakefile do
  outfile = 'sources/instructions.json'
  raise "#{outfile} already exists" if File.exist? outfile

  data = { 
    file: "morph/data.csv",
    create: {
      type: 'morph',
      scraper: instructions(:source),
      query: instructions(:query) || 'SELECT * FROM data',
    },
    source: "https://morph.io/#{instructions(:source)}",
    type: 'membership'
  }

  terms = {
   file: FileList.new('**/terms.csv').first.to_s.sub('sources/',''),
   type: 'term',
  }
  if instructions(:fetch_terms)
    terms[:create] = {
      file: 'morph/terms.csv',
      type: 'morph',
      scraper: instructions(:source),
      query: instructions(:term_query) || 'SELECT * FROM terms'
    }
  end

  info = { 
    sources: [ data, terms ]
  }
  File.write(outfile, JSON.pretty_generate(info))
  File.write("sources/Rakefile.rb", "require_relative '../../../../rakefile_merged.rb'")
  File.write("Rakefile.rb",         "require_relative '../../../rakefile_local.rb'")
  File.delete(@INSTRUCTIONS_FILE)
  puts "OK".green
end


