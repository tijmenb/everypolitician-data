require 'json'
require 'pry'
require 'colorize'
require 'open-uri'
require 'open-uri/cached'

PARTIES_IN_COUNTRY = 'https://wdq.wmflabs.org/api?q=claim[31:7278]%%20AND%%20claim[17:%d]'

def json_from(json_file)
  JSON.parse(open(json_file).read, symbolize_names: true)
end

def json_write(file, json)
  File.write(file, JSON.pretty_generate(json))
end

class Item

  WIKIDATA_ITEM = 'https://www.wikidata.org/wiki/Special:EntityData/%s'

  def initialize(qid)
    @_qid = "Q#{qid}".sub('QQ','Q')
  end

  def id
    @_qid
  end

  def url
    WIKIDATA_ITEM % id
  end

  def json_url
    url + '.json'
  end

  def entity
    @_entity ||= _json[:entities][id.to_sym]
  end

  def _json
    @_json ||= json_from(json_url)
  end

  def claims(p_id)
    pid = "P#{p_id}".sub('PP','P')
    entity[:claims][pid.to_sym] || []
  end

  def claim(p_id)
    cs = claims(p_id)
    raise "#{cs.count} results for #{p_id}: #{cs}" if cs.count > 1
    cs.first
  end

  def label(lang)
    entity[:labels][lang.to_sym][:value]
  end

  def all_labels
    # sorted by how often it appears
    entity[:labels].group_by { |k, v| v[:value] }.sort_by { |n, ns| ns.count }.reverse.map { |n, _| n }
  end

end



meta = json_from('meta.json')
house = Item.new(meta[:wikidata])

puts house.url.to_s.cyan

puts "Name (en): #{house.label(:en)}"

# Seat Count 
if seat = house.claim(1342)
  puts "Seats: #{seat[:mainsnak][:datavalue][:value]}"
else
  warn "Seats: undefined".red 
end

# Website 
house.claims(856).each do |c|
  puts "Site: #{c[:mainsnak][:datavalue][:value]}"
end

# Location = Administrative territory (P131) or Country (P17)
# TODO: "applies to jurisdiction" 1001? (e.g. https://www.wikidata.org/wiki/Q217799)
location_c = house.claim(131) || house.claim(17) || raise("No country or territory")
location = location_c[:mainsnak][:datavalue][:value][:"numeric-id"]

party_json = json_from(PARTIES_IN_COUNTRY % location)
party_ids = party_json[:items] or abort "No parties"

puts "PARTIES".yellow

party_ids.each do |pid|
  party = Item.new(pid)
  puts party.url.to_s.magenta
  puts party.label(:en)
  # puts party.all_labels.join(" // ")
end



