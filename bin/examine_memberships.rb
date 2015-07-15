require 'json'
require 'pry'

file = ARGV.shift
person_id = ARGV.shift

@json = JSON.load(File.read(file), lambda { |h|
  if h.class == Hash 
    h.reject! { |_, v| v.nil? or v.empty? }
    h.reject! { |k, v| [:created_at, :updated_at, :_links].include? k }
  end
}, { symbolize_names: true })

mems = @json[:memberships].find_all { |m| m[:person_id] == person_id }
mems.each do |m| 
  m[:organization] = @json[:organizations].find { |o| o[:id] == m[:organization_id] }
  m[:organization].delete :contact_details
  m[:organization].delete :sources
  m.delete :sources
end
puts JSON.pretty_generate mems

binding.pry

