
require_relative 'rakefile_common.rb'

namespace :raw do

  file 'parldata.json' do
    venv_path = ENV['PARLDATA_VENV'] or raise "PARLDATA_VENV must be set to a virtualenv"
    venv_python = venv_path + "/bin/python"
    File.exist? venv_python or raise "No `python` binary found at #{venv_python}"

    [@PARLDATA].flatten.each_with_index do |house, i|
      fetcher = File.expand_path("../bin/parldataeu.py", __FILE__)
      cmd = [venv_python, fetcher, house].join ' '

      outfile = 'parldata'
      outfile << "-#{house.split('/').last}" unless i.zero?

      data = %x[ #{cmd} ]
      File.write("#{outfile}.json", data)
    end
  end

end
    
namespace :whittle do

  task :load => 'parldata.json' do
    @SOURCE = 'http://api.parldata.eu/' + [@PARLDATA].flatten.first
    @json = JSON.load(File.read('parldata.json'), lambda { |h|
      if h.class == Hash 
        h.reject! { |_, v| v.nil? or v.empty? }
        h.reject! { |k, v| [:created_at, :updated_at, :_links].include? k }
      end
    }, { symbolize_names: true })
  end

  task :no_orphaned_memberships => [:delete_unwanted_orgs, :switch_people_to_persons]

  task :switch_people_to_persons => :load do
    @json[:persons] = @json.delete :people
  end

  task :delete_unwanted_orgs => :load do
    @json[:organizations].delete_if { |o| o[:classification] == 'committee' }
  end

  # TODO: push this up to a standardised way to rename any field
  task :write => :standardise_terminology
  task :standardise_terminology => :delete_unwanted_orgs do
    if @FACTION_CLASSIFICATION
      @json[:organizations].find_all { |o| o[:classification] == @FACTION_CLASSIFICATION }.each do |o|
        o[:classification] = 'faction'
      end
    end
  end

end

namespace :transform do

  # Don't do the core Term-based processing until we've done our own transformations 
  task :ensure_term => :fill_behalfs

  task :migrate_to_terms => :ensure_legislature do
    leg = @json[:organizations].find { |h| h[:classification] == 'legislature' }
    @json[:organizations].find_all { |h| h[:classification] == 'chamber' }.each do |c|
      (leg[:legislative_periods] ||= []) << c.merge({ 
        classification: "legislative period",
        start_date: c.delete(:founding_date),
        end_date: c.delete(:dissolution_date),
      }.reject { |_,v| v.nil? or v.empty? })

      @json[:memberships].find_all { |m| m[:organization_id] == c[:id] }.each do |m|
        m[:organization_id] = leg[:id]
        m[:legislative_period_id] = c[:id]
        m[:role] = 'member'
      end
    end

    @json[:organizations].delete_if { |h| h[:classification] == 'chamber' }
  end

  task :fill_behalfs => :migrate_to_terms do
    leg     = @json[:organizations].find     { |h| h[:classification] == 'legislature' }
    groups  = @json[:organizations].find_all { |h| h[:classification] == 'faction' }
    parties = @json[:organizations].find_all { |h| h[:classification] == 'party' }

    groupids = groups.map  { |p| p[:id] }.to_set
    partyids = parties.map { |p| p[:id] }.to_set
    terms    = leg[:legislative_periods]

    # All Memberships that have no :on_behalf_of
    gaps = @json[:memberships].find_all { |m| 
        m[:organization_id] == leg[:id] and m[:role] == 'member' and not m.has_key? :on_behalf_of_id 
    }

    gaps.each do |missing|
      # What else was that Person a Member of during that Term?
      term = terms.find { |t| t[:id] == missing[:legislative_period_id] }
      possibles = @json[:memberships].find_all { |m| 
        m[:person_id] == missing[:person_id] and m[:organization_id] != leg[:id]
      }.reject { |pmem|
        term[:end_date] and pmem[:start_date] and pmem[:start_date] >= term[:end_date]
      }.reject { |pmem|
        term[:start_date] and pmem[:end_date] and pmem[:end_date] <= term[:start_date]
      }

      group_mems = possibles.find_all { |m| groupids.include? m[:organization_id] }
      party_mems = possibles.find_all { |m| partyids.include? m[:organization_id] }

      # No factions, but single party? That'll do
      if party_mems.count == 1
        missing[:on_behalf_of_id] = party_mems.first[:organization_id]

      # Multiple parties. Again, first for now, but TODO
      elsif party_mems.count == 1
        warn "Person #{missing[:person_id]} in multiple parties during Term #{term[:id]}"
        missing[:on_behalf_of_id] = party_mems.first[:organization_id]

      # Single faction match? Perfect!
      elsif group_mems.count == 1
        missing[:on_behalf_of_id] = group_mems.first[:organization_id]

      # More than one? For now let's just take the first, though TODO take all
      elsif group_mems.count > 1
        require 'colorize'
        warn "Person #{missing[:person_id]} in multiple factions during Term #{term[:id]}"
        warn "#{term}".magenta
        warn "#{JSON.pretty_generate group_mems}".cyan
        # binding.pry
        missing[:on_behalf_of_id] = group_mems.first[:organization_id]

      # None? class as Independent
      else
      end
    end
  end
    

end

