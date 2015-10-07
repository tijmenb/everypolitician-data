require 'json'
require 'pry'
require 'colorize'

total = 0
if ARGV.last.match /\d{4}-\d{2}-\d{2}/
  date = ARGV.pop
end

ARGV.each do |file|
  statements = 0
  @json = JSON.load(File.read(file), lambda { |h|
    statements += h.values.select { |v| v.class == String }.count if h.class == Hash 
  })
  # puts "#{file}: #{statements} statements"
  total += statements
end

puts [ date, ARGV.count, total ].compact.join("\t")
