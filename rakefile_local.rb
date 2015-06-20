require_relative 'rakefile_common.rb'

require 'csv_to_popolo'

namespace :whittle do
  task :load do
    @json = Popolo::CSV.new('sources/manual/members.csv').data
  end
end
