
require_relative 'rakefile_common.rb'

namespace :raw do

  @PARLDATA_RAW_FILE = 'sources/parldata/raw.json'

  file @PARLDATA_RAW_FILE do
    venv_path = ENV['PARLDATA_VENV'] or raise "PARLDATA_VENV must be set to a virtualenv"
    venv_python = venv_path + "/bin/python"
    File.exist? venv_python or raise "No `python` binary found at #{venv_python}"

    [@PARLDATA].flatten.each_with_index do |house, i|
      fetcher = File.expand_path("../bin/parldataeu.py", __FILE__)
      cmd = [venv_python, fetcher, house].join ' '

      outfile = 'raw'
      outfile << "-#{house.split('/').last}" unless i.zero?

      data = %x[ #{cmd} ]
      File.write("sources/parldata/#{outfile}.json", data)
    end
  end

end
    
namespace :whittle do

  task :load => @PARLDATA_RAW_FILE do
    @SOURCE = 'http://api.parldata.eu/' + [@PARLDATA].flatten.first
    @json = JSON.load(File.read(@PARLDATA_RAW_FILE), lambda { |h|
      if h.class == Hash 
        h.reject! { |_, v| v.nil? or v.empty? }
        h.reject! { |k, v| [:created_at, :updated_at, :_links].include? k }
      end
    }, { symbolize_names: true })
  end

  task :no_orphaned_memberships => [:delete_unwanted_data, :switch_people_to_persons]

  task :switch_people_to_persons => :load do
    @json[:persons] = @json.delete :people
  end

  task :delete_unwanted_data => :load do
    @json[:organizations].delete_if { |o| o[:classification] == 'committee' }
    @json[:events].delete_if { |e| %w[session sitting].include? e[:type] } if @json[:events]
  end

  # TODO: push this up to a standardised way to rename any field
  task :write => :standardise_terminology
  task :standardise_terminology => :delete_unwanted_data do
    if @FACTION_CLASSIFICATION
      @json[:organizations].find_all { |o| o[:classification] == @FACTION_CLASSIFICATION }.each do |o|
        o[:classification] = 'faction'
      end
    end
  end

end

namespace :transform do

  # Don't merge in the term info until we've done this.
  task :ensure_term => :migrate_chambers_to_terms
  task :migrate_chambers_to_terms => :ensure_legislature do
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


  task :ensure_behalf_of => :fill_behalfs
  task :fill_behalfs => :ensure_term do

    house = @json[:organizations].find { |h| h[:classification] == 'legislature' }
    terms = house[:legislative_periods]

    # Which type of memberships do care about?
    want_type = @MEMBERSHIP_GROUPING || 'party'
    groups    = @json[:organizations].find_all { |h| h[:classification] == want_type }
    groupids  = groups.map { |p| p[:id] }.to_set


    # All Memberships that have no :on_behalf_of
    gaps = @json[:memberships].find_all { |m| 
      m[:organization_id] == house[:id] and m[:role] == 'member' and not m.has_key? :on_behalf_of_id 
    }

    gaps.each do |missing|
      # What else was that Person a Member of during that Term?
      term = terms.find { |t| t[:id] == missing[:legislative_period_id] }
      possibles = @json[:memberships].find_all { |m| 
        m[:person_id] == missing[:person_id] and m[:organization_id] != house[:id]
      }.reject { |pmem|
        term[:end_date] and pmem[:start_date] and pmem[:start_date] >= term[:end_date]
      }.reject { |pmem|
        term[:start_date] and pmem[:end_date] and pmem[:end_date] <= term[:start_date]
      }

      group_mems = possibles.find_all { |m| groupids.include? m[:organization_id] }
      possible_groups = group_mems.map { |m| m[:organization_id] }.uniq

      # Single group match? Excellent.
      if possible_groups.count == 1
        # warn "Single group: #{group_mems.first[:organization_id]}" 
        missing[:on_behalf_of_id] = possible_groups.first

      # More than one? Make new memberships
      elsif possible_groups.count > 1
        group_mems.each_with_index do |group_mem, i|
          raise "No membership ID in #{missing}" unless missing.key? :id
          leg_mem = missing.clone
          leg_mem[:id].concat("-#{i}")
          leg_mem[:on_behalf_if_id] = group_mem[:organization_id]
          # TODO: were they in no groups for a while in the middle?
          leg_mem[:start_date] = group_mem[:start_date] if group_mem.key?(:start_date) # && group_mem[:start_date] > leg_mem[:start_date]
          leg_mem[:end_date]   = group_mem[:end_date]   if group_mem.key?(:end_date)   # && group_mem[:end_date]   < leg_mem[:end_date]
          @json[:memberships] << leg_mem
        end
        @json[:memberships].delete_if { |m| m[:id] == missing[:id] }
      # None? class as Independent
      else
        warn "Person #{missing[:person_id]} in no suitable groups during Term #{term[:id]} (But in #{possibles})"
        # binding.pry
      end
    end
  end

end

