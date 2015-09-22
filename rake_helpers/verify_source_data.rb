
# After generating the merged CSV, ensure that it contains what we need
# and is well-formed
#
# We don't need to check the raw source data as it may be overridden.

desc "Verify merged data"

namespace :verify do

  task :load => 'merge_sources:sources/merged.csv' do
    @csv = csv_table('sources/merged.csv')
  end

  task :check_data => :load do
    @csv.each do |r|
      abort "No `name` in #{r}" if r[:name].to_s.empty?

      r.keys.select { |k| k.to_s.include? '_date' }.each do |d|
        next if r[d].nil? || r[d].empty?
        abort "Badly formatted #{d} in #{r}" unless r[d].match /^\d{4}-\d{2}-\d{2}$/
        parsed_date = Date.parse(r[d]) rescue 'broken'
        abort "Invalid #{d} in #{r}" unless parsed_date.to_s == r[d]
      end
    end
  end  
end


