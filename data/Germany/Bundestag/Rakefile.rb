require_relative '../../rakefile_morph.rb'

@MORPH = 'pudo/de-bundestag-mdbs' 
@MORPH_QUERY = 'SELECT * FROM data ORDER BY last_update DESC LIMIT 1'

@LEGISLATURE = {
  name: 'Bundestag',
  seats: 620,
}

# https://de.wikipedia.org/wiki/18._Deutscher_Bundestag
@TERMS = [{
  id: 'de.bundestag.data/wahlperiode/18',
  name: '18th Bundestag',
  start_date: '2013-10-22',
}]

namespace :whittle do

  task :load => @MORPH_DATA_FILE do
    @json = JSON.load(
      CSV.read(@MORPH_DATA_FILE).last.last, 
      lambda { |h| 
        if h.class == Hash 
          h.each do |k,v|
            # de.bundestag.data:mdb:1701 → de.bundestag.data/mdb/1701
            # We shouldn't really need to do this — the viewer should
            # just handle them cleanly. But this is simpler for now.
            v.tr!(':','/') if (k == :id) || k.to_s.end_with?('_id')
          end
        end
      }, 
      symbolize_names: true 
    )

    # Move memberships from in-place on Person
    @json[:memberships] ||= []
    @json[:persons].each do |p|
      @json[:memberships] << p.delete(:memberships)
    end
    @json[:memberships].flatten!

  end

end

