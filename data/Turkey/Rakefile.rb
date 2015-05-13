require_relative '../../rakefile_morph.rb'

@DEST = 'turkey'
@MORPH = 'tmtmtmtm/turkey-tbmm-wp'
@LEGISLATURE = {
  name: 'Grand National Assembly'
}

@TERMS = CSV.read("terms.csv", headers:true).map do |row|
  {
    id: "term/#{row['id']}",
    name: row['name'],
    start_date: row['start_date'],
    end_date: row['end_date'],
  }.reject { |_,v| v.nil? or v.empty? }
end
