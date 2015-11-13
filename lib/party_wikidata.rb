require 'wikisnakker'

# Takes an array of hashes containing party 'id' and 'wikidata_id' then returns
# wikidata information about each party.
class PartyWikidata
  attr_reader :wikidata_id_lookup

  def initialize(mapping)
    @wikidata_id_lookup = Hash[
      mapping.map { |item| [item[:wikidata_id], item[:id]] }
    ]
  end

  def to_hash
    party_information = wikidata_results.map do |result|
      [wikidata_id_lookup[result.id], fields_for(result)]
    end
    Hash[party_information]
  end

  def wikidata_results
    @wikidata_results ||= Wikisnakker::Item.find(wikidata_id_lookup.keys)
  end

  private

  def fields_for(result)
    {
      other_names: result.labels.values.map do |label|
        {
          lang: label['language'],
          name: label['value'],
          note: 'multilingual'
        }
      end
    }
  end
end
