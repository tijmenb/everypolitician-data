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
    entity[:labels][lang.to_sym][:value] rescue nil
  end

  def all_labels
    # sorted by how often it appears
    entity[:labels].group_by { |k, v| v[:value] }.sort_by { |n, ns| ns.count }.reverse.map { |n, _| n }
  end

end


def snakdate(c)
  v = c[:mainsnak][:datavalue][:value]
  # https://www.wikidata.org/wiki/Special:ListDatatypes
  if v[:precision] == 8  # decade
    v[:time][1..3] + "0s"
  elsif v[:precision] == 9  # year
    v[:time][1..4]
  elsif v[:precision] == 10  # month
    v[:time][1..7]
  elsif v[:precision] == 11  # day
    v[:time][1..10]
  else
    abort "unknown precision in #{v}"
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

# Location = Jurisdiction (1001) || Administrative territory (131) or Country (17)
location_c = house.claim(1001) || house.claim(131) || house.claim(17) || raise("No country or territory")
location = location_c[:mainsnak][:datavalue][:value][:"numeric-id"]

party_json = json_from(PARTIES_IN_COUNTRY % location)
party_ids = party_json[:items] or abort "No parties"

puts "PARTIES".yellow

parties = party_ids.map { |pid|
  party = Item.new(pid)
  data = { 
    name__en: party.label(:en),
    # labels: party.all_labels.join("  //  "),
    url: party.url,
  }
  if dfrom = party.claim(571)
    data[:start_date] = snakdate(dfrom)
  end
  if dto = party.claim(576)
    data[:end_date] = snakdate(dto)
  end
  data
}

puts parties.sort_by { |p| [p[:end_date] || '9999-99-00', p[:start_date] || '0000-00-00'] }.reverse



