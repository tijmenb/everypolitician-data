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

  # leg[:legislative_periods], @orgs[:organizations] = @orgs[:organizations].partition { |o| o[:classification] == 'chamber' }
  terms, orgs = @json[:organizations].partition { |o| o[:classification] == 'chamber' }
  require 'pry'
  binding.pry

  @json[:organizations] = orgs
  leg = @json[:organizations].find { |h| h[:classification] == 'legislature' } or raise "No legislature"
  leg[:legislative_periods] = terms.map do |t|
    t[:classification] == 'legislative_period_id'
    t[:start_date] = t.delete :founding_date
    t[:end_date] = t.delete :dissolution_date
    t
  end

end
