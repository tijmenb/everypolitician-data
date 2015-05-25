require_relative '../../rakefile_parldata.rb'

@PARLDATA = 'kv/kuvendi'
@LEGISLATURE = {
  name: 'Kuvendit',
  seats: 120,
}

@MEMBERSHIP_GROUPING = 'parliamentary_group'

namespace :transform do
  task :write => :rename_terms 
  task :rename_terms => :ensure_term do
    parl = @json[:organizations].find { |h| h[:classification] == 'legislature' } or raise "No legislature"
    parl[:legislative_periods].each do |t|
      t[:name] = t[:name].split(' - ').last
      puts "Rename #{t[:name]}" 
    end
  end
end

    

