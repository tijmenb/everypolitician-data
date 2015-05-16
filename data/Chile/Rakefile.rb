require_relative '../../rakefile_morph.rb'

@MORPH = 'tmtmtmtm/chile-opendata'
@LEGISLATURE = { 
  name: 'National Congress',
  seats: 120,
}

namespace :whittle do

  task :write => :clean_zero_districts

  task :clean_zero_districts => :load do
    @json[:memberships].each do |m|
      m.delete(:area) if m.has_key?(:area) and m[:area][:name] == '0'
    end
  end
end


