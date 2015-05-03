
require_relative 'rakefile_common.rb'

file 'kvapi.json' do
  raise "Shell out to python here"
end
CLOBBER.include('kvapi.json')
  
file 'clean.json' => 'kvapi.json' do
  json = JSON.load(File.read('kvapi.json'), lambda { |h|
    if h.class == Hash 
      h.reject! { |_, v| v.nil? or v.empty? }
      h.reject! { |k, v| [:created_at, :updated_at, :_links].include? k }
    end
  }, { symbolize_names: true })

  File.write('clean.json', JSON.pretty_generate(json))
end
CLEAN.include('clean.json')

