require_relative '../rakefile_kvapi.rb'

@DEST = 'albania'
@KVAPI = 'al/kuvendi'

@current_term = { 
  id: 'term/44',
  name: '44th Parliament',
  start_date: '2013-09-07',
}

task :ensure_legislative_period => :cleanup 

task :cleanup => :ensure_legislature_exists do
  @json[:organizations].delete_if { |o| o[:classification] == 'committee' }

  leg = @json[:organizations].find { |h| h[:classification] == 'legislature' } or raise "No legislature"
  leg[:legislative_periods], @orgs[:organizations] = @orgs[:organizations].partition { |o| o[:classification] == 'chamber' }
end
