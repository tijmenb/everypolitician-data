
require_relative 'rakefile_common.rb'

file 'popit.json' do
  popit_src = @POPIT_URL || "https://#{@POPIT || @DEST}.popit.mysociety.org/api/v0.1/export.json"
  File.write('popit.json', open(popit_src).read) 
end
CLOBBER.include('popit.json')
  
file 'clean.json' => 'popit.json' do
  json = JSON.load(File.read('popit.json'), lambda { |h|
    if h.class == Hash 
      h.reject! { |_, v| v.nil? or v.empty? }
      h.reject! { |k, v| (k == :url or k == :html_url) and v[/popit.mysociety.org/] }
    end
  }, { symbolize_names: true })
  File.write('clean.json', JSON.pretty_generate(json))
end
CLOBBER.include('clean.json')

