
require 'colorize'
require 'csv'
require 'erb'
require 'fileutils'
require 'fuzzy_match'
require 'json'
require 'open-uri'
require 'pry'
require 'rake/clean'

def json_load(file)
  return unless File.exist? file
  JSON.parse(File.read(file), symbolize_names: true)
end

@instructions = json_load('instructions.json') 
raise "No sources" if @instructions[:sources].count.zero?

@recreatable = @instructions[:sources].find_all { |i| i.key? :create }
CLOBBER.include FileList.new(@recreatable.map { |i| i[:file] })

# For now, write the merged file to manual/members.csv so we can then
# fall-back on the old-style rake task that looks there
# TODO: consolidate these
CLOBBER.include 'manual/members.csv'

def morph_select(src, qs)
  morph_api_key = ENV['MORPH_API_KEY'] or fail 'Need a Morph API key'
  key = ERB::Util.url_encode(morph_api_key)
  query = ERB::Util.url_encode(qs.gsub(/\s+/, ' ').strip)
  url = "https://api.morph.io/#{src}/data.csv?key=#{key}&query=#{query}"
  warn "Fetching #{url}"
  open(url).read
end

def fetch_missing
  @recreatable.each do |i|
    unless File.exist? i[:file]
      c = i[:create]
      raise "Don't know how to fetch #{i[:file]}" unless c[:type] == 'morph'
      data = morph_select(c[:scraper], c[:query])
      FileUtils.mkpath File.dirname i[:file]
      File.write(i[:file], data)
    end
  end 
end

# http://codereview.stackexchange.com/questions/84290/combining-csvs-using-ruby-to-match-headers
def combine_sources

  # build headers for everything
  all_headers = @instructions[:sources].find_all { |src|
    src[:type] != 'term'
  }. map { |src| src[:file] }.reduce([]) do |all_headers, file|
    puts "Headers from #{file}".cyan
    header_line = File.open(file, &:gets)     
    all_headers | CSV.parse_line(header_line) 
  end

  # First concat everything that's a "membership" (or default)
  all_rows = []
  @instructions[:sources].find_all { |src|
    src[:type].to_s.empty? || src[:type].to_s.downcase == 'membership'
  }.each do |src| 
    file = src[:file] 
    fuzzer = nil
    puts "Concat #{file}".cyan
    CSV.table(file).each do |row|
      if src.key? :merge
        field = src[:merge][:field].to_sym
        if src[:merge][:approximate] 
          fuzzer ||= FuzzyMatch.new(all_rows, read: field, must_match_at_least_one_word: true )
          found = fuzzer.find(row[field])
          puts "Matched #{row[field]} to #{found[field]}".yellow
        else
          raise "Not implemented yet"
        end

        if src[:merge][:clobber]
          row.headers.each do |h|
            found[h] = row[h] unless row[h].to_s.empty? || row[h].to_s.downcase == 'unknown'
          end
        else
          raise "Not implemented yet"
        end

      else # append
        all_rows << row.to_hash
      end
    end
  end

  # Then merge in Person files
  @instructions[:sources].find_all { |src| 
    src[:type].to_s.downcase == 'person' 
  }.each do |src|
    file = src[:file]
    puts "Merging #{file}".magenta
    field = (src[:merge][:field] || 'id').to_sym
    warn "Build by #{field}"
    CSV.table(file).each do |p|
      if src[:merge][:approximate]
        fuzzer ||= FuzzyMatch.new(all_rows, read: field, must_match_at_least_one_word: true )
        found = fuzzer.find(p[field]) or warn "No match for #{p[field]}"
        puts "Matched #{p[field]} to #{found}".yellow if found
      else
        found = all_rows.find { |r| r[field] == p[field] }.each 
      end

      if found
        if src[:merge][:clobber]
          p.headers.each { |h| found[h] = p[h] unless p[h].to_s.empty? || p[h].to_s.downcase == 'unknown' }
        else
          p.headers.each { |h| found[h] ||= p[h] }
        end
      end
    end
  end

  # Then write it all out
  FileUtils.mkpath "manual"
  CSV.open("manual/members.csv", "w") do |out|
    out << all_headers
    all_rows.each { |r| out << all_headers.map { |header| r[header.to_sym] } }
  end

  # Write a source file, if required
  # TODO remove this once we're doing everything ourselves

  unless File.exist? 'manual/instructions.json'
    source = { source: @instructions[:sources].first { |i| i[:source] }[:source] }
    File.write 'manual/instructions.json', JSON.pretty_generate(source)
  end

end

task :fetch_missing do
  fetch_missing
end

task 'manual/members.csv' => :fetch_missing do
  combine_sources
end

task :default => [ 'manual/members.csv' ]
