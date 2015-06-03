require_relative '../../rakefile_morph.rb'

@MORPH = 'pudo/de-bundestag-mdbs' 
@MORPH_QUERY = 'SELECT * FROM data ORDER BY last_update DESC LIMIT 1'

@LEGISLATURE = {
  name: 'Bundestag',
  seats: 620,
}

# https://de.wikipedia.org/wiki/18._Deutscher_Bundestag
@TERMS = [{
  id: 'de.bundestag.data:wahlperiode:18',
  name: '18th Bundestag',
  start_date: '2013-10-22',
}]

namespace :whittle do

  task :load => 'morph.csv' do
    @json = JSON.parse( CSV.read('morph.csv').last.last, symbolize_names: true )

    # Move memberships from in-place on Person
    @json[:memberships] ||= []
    @json[:persons].each do |p|
      @json[:memberships] << p.delete(:memberships)
    end
    @json[:memberships].flatten!

  end

end

