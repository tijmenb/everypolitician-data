require 'test_helper'
require_relative '../lib/party_wikidata'

describe PartyWikidata do
  around { |test| VCR.use_cassette('party-wikidata', &test) }

  subject do
    PartyWikidata.new([
      { id: 'pnp', wikidata_id: 'Q1076562' },
      { id: 'ppd', wikidata_id: 'Q199319' }
    ])
  end

  describe '#to_hash' do
    it 'returns a hash' do
      subject.to_hash.is_a?(Hash).must_equal true
    end

    it 'has a key for each requested party' do
      subject.to_hash.key?('pnp').must_equal true
    end

    it 'has an other_names key for each party' do
      subject.to_hash['pnp'].key?(:other_names).must_equal true
    end
  end
end
