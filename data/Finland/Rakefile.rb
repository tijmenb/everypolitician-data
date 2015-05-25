require_relative '../../rakefile_common.rb'

@SOURCE = 'https://github.com/tmtmtmtm/eduskunta-popolo'
@LEGISLATURE = {
  name: 'Eduskunta',
  seats: 200,
}

namespace :raw do
  @GITHUB_SOURCE = 'https://raw.githubusercontent.com/tmtmtmtm/eduskunta-popolo/master/eduskunta.json'
  file 'github.json' do
    File.write('github.json', open(@GITHUB_SOURCE).read)
  end
end

# Can remove this once EduPop fixes this
namespace :whittle do
  task :load => 'github.json' do
    @json = JSON.parse(File.read('github.json'), symbolize_names: true)
  end
end

