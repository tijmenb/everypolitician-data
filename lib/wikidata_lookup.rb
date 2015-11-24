require 'wikisnakker'

# Takes an array of hashes containing an 'id' and 'wikidata' then returns
# wikidata information about each item.
class WikidataLookup
  attr_reader :wikidata_id_lookup

  def initialize(mapping)
    @wikidata_id_lookup = Hash[
      mapping.map { |item| [item[:wikidata], item[:id]] }
    ]
  end

  def to_hash
    information = wikidata_results.map do |result|
      [wikidata_id_lookup[result.id], fields_for(result)]
    end
    Hash[information]
  end

  private

  def wikidata_results
    @wikidata_results ||= Wikisnakker::Item.find(wikidata_id_lookup.keys)
  end

  def fields_for(result)
    {
      identifiers: [
        {
          scheme: 'wikidata',
          identifier: result.id
        }
      ],
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