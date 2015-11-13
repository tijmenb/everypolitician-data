require 'wikisnakker'

# Takes an array of hashes containing group 'id' and 'wikidata_id' then returns
# wikidata information about each group.
class GroupWikidata
  attr_reader :wikidata_id_lookup

  def initialize(mapping)
    @wikidata_id_lookup = Hash[
      mapping.map { |item| [item[:wikidata_id], item[:id]] }
    ]
  end

  def to_hash
    group_information = wikidata_results.map do |result|
      [wikidata_id_lookup[result.id], fields_for(result)]
    end
    Hash[group_information]
  end

  def wikidata_results
    @wikidata_results ||= Wikisnakker::Item.find(wikidata_id_lookup.keys)
  end

  private

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
