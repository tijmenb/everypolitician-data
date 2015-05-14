require_relative '../../rakefile_popit.rb'

@POPIT = 'za-peoples-assembly'

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

  # Don't fill in the defaults until we fill in ours
  task :ensure_behalf_of => :fill_behalfs

  task :add_legislative_periods_to_memberships => :ensure_term do
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

  task :fill_behalfs => :add_legislative_periods_to_memberships do
    leg     = @json[:organizations].find     { |h| h[:classification] == 'legislature' }
    parties = @json[:organizations].find_all { |h| h[:classification] == 'party' }
    partyids = parties.map { |p| p[:id] }.to_set
    terms    = leg[:legislative_periods]

    # All Memberships that have no :on_behalf_of
    gaps = @json[:memberships].find_all { |m| 
        m.has_key?(:legislative_period_id) and not m.has_key?(:on_behalf_of_id)
    }

    gaps.each do |missing|
      # What else was that Person a Member of during that Term?
      term = terms.find { |t| t[:id] == missing[:legislative_period_id] }
      start_date = missing[:start_date] || term[:start_date] 
      end_date   = missing[:end_date] || term[:end_date] 

      possibles = @json[:memberships].find_all { |m| 
        m[:person_id] == missing[:person_id] and m[:role] == 'Member' and m[:organization_id] != leg[:id]
      }.reject { |pmem|
        pmem[:start_date] and pmem[:start_date] > end_date
      }.reject { |pmem|
        pmem[:end_date]   and pmem[:end_date]   < start_date
      }

      party_mems = possibles.find_all { |m| partyids.include? m[:organization_id] }

      # No factions, but single party? That'll do
      if party_mems.count == 1
        missing[:on_behalf_of_id] = party_mems.first[:organization_id]

      # Multiple parties. Again, first for now, but TODO
      elsif party_mems.count > 1
        require 'colorize'
        warn "\nPerson #{missing[:person_id]} in multiple parties during Term #{term[:id]}".green
        warn "Missing #{missing}".magenta
        warn "Term Dates #{term}".cyan
        warn party_mems.join("\n").yellow
        missing[:on_behalf_of_id] = party_mems.first[:organization_id]

      # None? fall through to default (class as Independent)
      else
        warn "Person #{missing[:person_id]} in no parties during Term #{term[:id]}"
      end
    end
  end

end

