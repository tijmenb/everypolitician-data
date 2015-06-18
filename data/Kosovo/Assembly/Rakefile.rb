require_relative '../../../rakefile_parldata.rb'

@PARLDATA = 'kv/kuvendi'
@LEGISLATURE = {
  name: 'Kuvendit',
  seats: 120,
}

@MEMBERSHIP_GROUPING = 'parliamentary_group'

namespace :transform do
  task :write => :rename_terms 
  task :rename_terms => :ensure_term do
    @json[:events].find_all { |h| h[:classification] == 'legislative period' }.each do |t|
      t[:name] = t[:name].split(' - ').last
      puts "Rename #{t[:name]}" 
    end
  end
end

    

