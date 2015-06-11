require_relative '../../rakefile_common.rb'

require 'colorize'

@LEGISLATURE = {
  name: 'Scottish Parliament',
  seats: 129,
}

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
      id: 'scottish-parliament',
      classification: 'legislature',
    }
  end

  task :no_orphaned_memberships => :remove_unwanted_data
  task :remove_unwanted_data => :load do
    @json[:posts].keep_if { |p| p[:organization_id] == 'scottish-parliament' }

    kept_posts = @json[:posts].map { |p| p[:id] }
    @json[:memberships].keep_if { |m| kept_posts.include? m[:post_id] }
    @json[:memberships].each do |m| 
      post = @json[:posts].find { |p| p[:id] == m[:post_id] }
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
    @json[:memberships].find_all { |m| m[:organization_id] == 'scottish-parliament' and not m.has_key? :legislative_period_id }.each do |m|
      matched = terms.find_all { |t| 
        (m[:start_date] >= t[:start_date]) and ((m[:end_date] || ('2100-01-01')) <= (t[:end_date] || '2100-01-01')) }
      if matched.count == 1
        m[:legislative_period_id] = matched.first[:id]
      elsif m[:id] == 'uk.org.publicwhip/member/80277'
        # David Steel as Presiding Officer
        m[:legislative_period_id] = 'term/1'
      elsif m[:id] == 'uk.org.publicwhip/member/80272'
        # George Reid as Presiding Officer
        m[:legislative_period_id] = 'term/2'
      else 
        warn "Invalid term intersection (#{matched.count} matches)"
        warn "#{m}".cyan
        warn "#{terms}".yellow
      end
    end
  end

  task :write => :ensure_names
  task :ensure_names => :set_membership_terms do
    @json[:persons].find_all { |p| not p.has_key? 'name' }.each do |p|
      # TODO cope better with name changes
      main_names = p[:other_names].find_all { |n| n[:note] == 'Main' }
      name = main_names.find { |n| n[:end_date].nil? } || main_names.sort_by { |n| n[:end_date] }.last
      raise "Uncertain name for #{JSON.pretty_generate p}" unless name
      if name.key? :lordname
        p[:name] = "#{name[:honorific_prefix]} #{name[:lordname]}"
        p[:name] += " of #{name[:lordofname]}" unless name[:lordofname].to_s.empty?
      else 
        p[:name] = name[:given_name] + " " + name[:family_name]
      end
    end
  end

end

