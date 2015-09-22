
# We take various steps to convert all the incoming data into the output
# formats. Each of these steps uses a different rake_helper:
#

# Step 1: combine_sources.rb
# This takes all the incoming data (mostly as CSVs) and joins them
# together into 'sources/merged.csv'

# Step 2: turn_csv_to_popolo
# This turns the 'merged.csv' into a 'sources/merged.json'

# Step 3: generate_ep_popolo
# This turns the generic 'merged.json' into the EP-specific
# 'ep-popolo.json' 

# Step 4: generate_term_csvs
# Generates term-by-term CSVs from the ep-popolo

require 'colorize'
require 'csv'
require 'csv_to_popolo'
require 'erb'
require 'fileutils'
require 'fuzzy_match'
require 'json'
require 'open-uri'
require 'pry'
require 'rake/clean'
require 'set'
require 'yajl/json_gem'

Numeric.class_eval { def empty?; false; end }


def deep_sort(element)
  if element.is_a?(Hash)
    element.keys.sort.each_with_object({}) { |k, newhash| newhash[k] = deep_sort(element[k]) }
  elsif element.is_a?(Array)
    element.map { |v| deep_sort(v) }
  else
    element
  end
end

def csv_table(file)
  rows = []
  CSV.table(file, converters: nil).each do |row|
    # Need to make a copy in case there are multiple source columns
    # mapping to the same term (e.g. with areas)
    rows << Hash[ row.headers.each.map { |h| [ remap(h), row[h].nil? ? nil : row[h].tidy ] } ]
  end
  rows
end

def json_load(file)
  raise "No such file #{file}" unless File.exist? file
  JSON.parse(File.read(file), symbolize_names: true)
end

def json_write(file, json)
  # TODO remove the need for the .to_s here, by ensuring all People and Orgs have names
  json[:persons].sort_by!       { |p| [ p[:name].to_s, p[:id] ] }
  json[:organizations].sort_by! { |o| [ o[:name].to_s, o[:id] ] }
  json[:memberships].sort_by!   { |m| [ m[:person_id], m[:organization_id] ] }
  json[:events].sort_by!        { |e| [ e[:start_date] || '', e[:id] ] } if json.key? :events
  json[:areas].sort_by!         { |a| [ a[:id] ] } if json.key? :areas
  final = Hash[deep_sort(json).sort_by { |k, _| k }.reverse]
  File.write(file, JSON.pretty_generate(final))
end

@SOURCE_DIR = 'sources/manual'
@DATA_FILE = @SOURCE_DIR + '/members.csv'
@INSTRUCTIONS_FILE = 'sources/instructions.json'

def load_instructions_file
  json = json_load(@INSTRUCTIONS_FILE) || raise("Can't read #{@INSTRUCTIONS_FILE}")
  json[:sources].each do |s|
    s[:file] = "sources/%s" % s[:file] unless s[:file][/sources/]
  end
  json
end

def instructions(key)
  @instructions ||= load_instructions_file
  @instructions[key]
end

desc "Rebuild from source data"
task :rebuild => [ :clobber, 'ep-popolo-v1.0.json' ]
task :default => :csvs

require_relative 'rake_helpers/combine_sources.rb'
require_relative 'rake_helpers/turn_csv_to_popolo.rb'
require_relative 'rake_helpers/generate_ep_popolo.rb'
require_relative 'rake_helpers/generate_term_csvs.rb'

