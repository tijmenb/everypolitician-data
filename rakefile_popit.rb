
require_relative 'rakefile_common.rb'

desc "Reload the source data"
task :raw => 'popit.json'


@POPIT_RAW_FILE = 'sources/popit/raw.json'
CLOBBER.include(@POPIT_RAW_FILE)

def popit_source 
  @POPIT_URL || "https://#{@POPIT || @DEST}.popit.mysociety.org/api/v0.1/export.json"
end

namespace :raw do

  file @POPIT_RAW_FILE do
    File.write(@POPIT_RAW_FILE, open(popit_source).read) 
  end

end

namespace :whittle do

  @POPIT_CLEAN_FILE = 'clean.json'

  task :load => @POPIT_RAW_FILE do
    @SOURCE = popit_source.gsub('/api/.*','')
    file = File.exist?(@POPIT_CLEAN_FILE) ? @POPIT_CLEAN_FILE : @POPIT_RAW_FILE
    @json = JSON.load(File.read(file), lambda { |h|
      if h.class == Hash 
        h.reject! { |_, v| v.nil? or v.empty? }
        h.reject! { |k, v| (k == :url or k == :html_url) and v[/popit.mysociety.org/] }
      end
    }, { symbolize_names: true })
  end

end

