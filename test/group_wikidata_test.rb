require 'test_helper'
require_relative '../lib/group_wikidata'

describe GroupWikidata do
  around { |test| VCR.use_cassette('group-wikidata', &test) }

  subject do
    GroupWikidata.new([
      { id: 'pnp', wikidata_id: 'Q1076562' },
      { id: 'ppd', wikidata_id: 'Q199319' }
    ])
  end

  describe '#to_hash' do
    it 'returns a hash' do
      subject.to_hash.is_a?(Hash).must_equal true
    end

    it 'has a key for each requested group' do
      subject.to_hash.key?('pnp').must_equal true
    end

    it 'has an other_names key for each group' do
      subject.to_hash['pnp'].key?(:other_names).must_equal true
    end
  end
end
