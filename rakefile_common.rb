require 'colorize'
require 'csv'
require 'open-uri'
require 'pry'
require 'rake/clean'
require 'yajl/json_gem'

require_relative 'rakefile_csvs.rb'
require_relative 'rakefile_transform.rb'
require_relative 'rakefile_whittle.rb'

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

def json_load(file)
  return unless File.exist? file
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

def instructions(key)
  @instructions ||= json_load(@INSTRUCTIONS_FILE) || raise("Can't read #{@INSTRUCTIONS_FILE}")
  @instructions[key]
end

desc "Rebuild from source data"
task :rebuild => [ :clobber, 'ep-popolo-v1.0.json' ]
task :default => :csvs
