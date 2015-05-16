require_relative '../../rakefile_common.rb'

require 'csv'
require 'csv_to_popolo'

@LEGISLATURE = {
  name: 'Northern Ireland Assembly',
  seats: 108,
}

@TERMS = [{ 
  id: 'term/2015',
  name: 'House of Commons 2015–',
  start_date: '2015'
}]


namespace :raw do
  file 'twfy.json' do
    warn "Refetching TWFY JSON"
    File.write('twfy.json', open('https://raw.githubusercontent.com/mysociety/parlparse/master/members/people.json').read)
  end
end

namespace :whittle do

  file 'clean.json' => 'twfy.json'
  task :load => 'twfy.json' do
    @SOURCE = "http://www.theyworkforyou.com/"
    @json = JSON.parse(File.read('twfy.json'), { symbolize_names: true })
    @json[:organizations] << {
      id: 'northern-ireland-assembly',
      classification: 'legislature',
    }
  end

  task :no_orphaned_memberships => :remove_unwanted_data
  task :remove_unwanted_data => :load do
    @json[:posts].keep_if { |p| p[:organization_id] == 'northern-ireland-assembly' }

    kept_posts = @json[:posts].map { |p| p[:id] }
    @json[:memberships].keep_if { |m| kept_posts.include? m[:post_id] }
    @json[:memberships].each do |m| 
      post = @json[:posts].find { |p| p[:id] = m[:post_id] }
      m[:organization_id] = post[:organization_id]
      m[:area] = post[:area]
      m[:role] = 'member'
    end
    @json.delete 'posts'

    keep_mlas = @json[:memberships].map { |m| m[:person_id] }
    @json[:persons].keep_if { |p| keep_mlas.include? p[:id] }
  end

end

namespace :transform do

  task :ensure_membership_terms => :set_membership_terms

  task :set_membership_terms => :load do
    leg = @json[:organizations].find { |h| h[:classification] == 'legislature' } or raise "No legislature"
    terms = leg[:legislative_periods]
    @json[:memberships].find_all { |m| m[:organization_id] == 'northern-ireland-assembly' and not m.has_key? :legislative_period_id }.each do |m|
      matched = terms.find_all { |t| 
        (m[:start_date] >= t[:start_date]) and ((m[:end_date] || ('2100-01-01')) <= (t[:end_date] || '2100-01-01')) }
      if matched.count == 1
        m[:legislative_period_id] = matched.first[:id]
      else 
        require 'colorize'
        warn "Invalid term intersection (#{matched.count} matches)"
        warn "#{m}".cyan
        warn "#{terms}".yellow
        m[:legislative_period_id] = 'term/2'
      end
    end
  end

end

