require_relative '../../rakefile_popit.rb'

@POPIT = 'inatsisartut'
@DEST = 'greenland'
@LEGISLATURE = {
  name: 'Inatsisartut',
}

namespace :transform do
  # Overwrite the ones in PopIt with with ones in the termfile
  task :ensure_term do
    leg = @json[:organizations].find { |h| h[:classification] == 'legislature' } or raise "No legislature"
    leg[:legislative_periods] = termdata
  end
end
