
desc "Verify merged data"

namespace :verify do

  task :load => 'merge_sources:sources/merged.csv' do
    @csv = csv_table('sources/merged.csv')
  end

  task :check_data => :load do
    @csv.each do |r|
      abort "No `name` in #{r}" if r[:name].to_s.empty?
    end
  end  
end


