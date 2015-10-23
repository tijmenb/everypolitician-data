require 'json'
require 'pry'
require 'colorize'

def json_from(json_file)
  JSON.parse(File.read(json_file), symbolize_names: true)
end

cfile = ARGV.first || "countries.json" or abort "Usage: #$0 <countries file>"
@countries = json_from(cfile)

puts <<'eoheader'
{| class="wikitable sortable"
|-
! Country !! Legislature !! Total Members !! Matched to Wikidata !! Percentage
|-
eoheader

@countries.each do |c|
  c[:legislatures].each do |l|
    @json = json_from l[:popolo]
    wdid = @json[:organizations].find { |o| o[:classification] == 'legislature' }[:identifiers].find { |i| i[:scheme] == 'wikidata' }[:identifier]
    wd = @json[:persons].partition { |p| (p[:identifiers] || []).find { |i| i[:scheme] == 'wikidata' } }
    puts "|-"
    puts "| %s || {{Q|%s}} || %d || %d || %.0f%%" % [
      c[:name], wdid.sub('Q',''), @json[:persons].count, wd.first.count, wd.first.count * 100.to_f / @json[:persons].count
    ]
  end
end

puts "|}"
