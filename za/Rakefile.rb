require_relative '../rakefile_popit.rb'

@POPIT = 'za-peoples-assembly'
@DEST = 'za'

# https://en.wikipedia.org/wiki/26th_South_African_Parliament etc
@TERMS = [
  { 
    id: 'term/26',
    name: '26th Parliament',
    start_date: '2014-05-21',
    end_date: '2019-05-21',
  },
  { 
    id: 'term/25',
    name: '25th Parliament',
    start_date: '2009-05-06',
    end_date: '2014-05-20',
  },
  { 
    id: 'term/24',
    name: '24th Parliament',
    start_date: '2004-05-21',
    end_date: '2009-04-22',
  }  
]

@KEEP_ORG_TYPES = %w(executive parliament party)

namespace :whittle do

  task :no_orphaned_memberships => :clean_orphaned_people
    
  task :delete_unwanted_orgs => :load do
    puts "Starting with #{@json[:organizations].count} orgs"
    keep = @json[:organizations].find_all { |o| @KEEP_ORG_TYPES.include? o[:classification].downcase }
    keepids = keep.map { |o| o[:id] }
    @json[:memberships].keep_if   { |m| keepids.include? m[:organization_id] }
    @json[:organizations].keep_if { |o| keepids.include? o[:id] }
    @json[:organizations].each do |o| 
      o[:classification].downcase!
      o[:classification] = 'legislature' if o[:classification] == 'parliament'
    end
    @json[:organizations].delete_if { |o| o[:classification] == 'legislature' and o[:name] != 'National Assembly' }
    puts "Ending with #{@json[:organizations].count} orgs"
  end

  # Delete everyone whose only Membership is to a Party
  task :clean_orphaned_people => :delete_unwanted_orgs do
    puts "Starting with #{@json[:persons].count} people"
    orgt = Hash[@json[:organizations].map { |o| [ o[:id], o[:classification] ] } ]
    @json[:persons].delete_if { |p| 
      @json[:memberships].find_all { |m| 
        m[:person_id] == p[:id] and orgt[ m[:organization_id] ]!= 'party' 
      }.count.zero?
    }
    puts "Ending with #{@json[:persons].count} people"
  end

  task :write => :remove_interest_register
  task :remove_interest_register => :clean_orphaned_people do
    @json[:persons].each { |p| p.delete :interests_register }
  end

end

namespace :transform do

  task :write => :add_legislative_periods_to_memberships

  task :add_legislative_periods_to_memberships => :add_term_dates do
    leg  = @json[:organizations].find     { |h| h[:classification] == 'legislature' }
    terms = leg[:legislative_periods]
    gaps = @json[:memberships].find_all { |m| 
      m[:organization_id] == leg[:id] and m[:role].to_s.downcase == 'member' and not m.has_key? :legislative_period_id 
    }

    gaps.each do |missing|
      overlapping_terms = terms.find_all { |term|
        (missing[:start_date].nil? || (term[:end_date] >= missing[:start_date])) and (missing[:end_date].nil? || (term[:start_date] <= missing[:end_date]))
      } 
      if overlapping_terms.count == 1
        missing[:legislative_period_id] = overlapping_terms.first[:id]
      elsif overlapping_terms.count > 1
        #TODO split 
        missing[:legislative_period_id] = overlapping_terms.first[:id]
      else
        warn "No possible terms for #{missing}" 
      end
    end
  end

end

