
class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

namespace :merge_sources do

  task :fetch_missing do
    fetch_missing
  end

  desc "Combine Sources"
  task 'sources/merged.csv' => :fetch_missing do
    combine_sources
  end

  @recreatable = instructions(:sources).find_all { |i| i.key? :create }
  CLOBBER.include FileList.new(@recreatable.map { |i| i[:file] })

  CLEAN.include 'sources/merged.csv'

  def morph_select(src, qs)
    morph_api_key = ENV['MORPH_API_KEY'] or fail 'Need a Morph API key'
    key = ERB::Util.url_encode(morph_api_key)
    query = ERB::Util.url_encode(qs.gsub(/\s+/, ' ').strip)
    url = "https://api.morph.io/#{src}/data.csv?key=#{key}&query=#{query}"
    warn "Fetching #{url}"
    open(url).read
  end

  def fetch_missing
    @recreatable.each do |i|
      unless File.exist? i[:file]
        c = i[:create]
        FileUtils.mkpath File.dirname i[:file]
        if c.key? :url
          warn "Fetching #{c[:url]}"
          IO.copy_stream(open(c[:url]), i[:file])
        elsif c[:type] == 'morph'
          data = morph_select(c[:scraper], c[:query])
          File.write(i[:file], data)
        elsif c[:type] == 'ocd'
          remote = 'https://raw.githubusercontent.com/opencivicdata/ocd-division-ids/master/identifiers/' + c[:source]
          IO.copy_stream(open(remote), i[:file])
        else
          raise "Don't know how to fetch #{i[:file]}" unless c[:type] == 'morph'
        end
      end
    end 
  end

  REMAP = {
    area: %w(constituency region district place),
    area_id: %w(constituency_id region_id district_id place_id),
    biography: %w(bio blurb),
    birth_date: %w(dob date_of_birth),
    blog: %w(weblog),
    cell: %w(mob mobile cellphone),
    chamber: %w(house),
    death_date: %w(dod date_of_death),
    end_date: %w(end ended until to),
    executive: %w(post),
    family_name: %w(last_name surname lastname),
    fax: %w(facsimile),
    gender: %w(sex),
    given_name: %w(first_name forename),
    group: %w(party party_name faction faktion bloc block org organization organisation),
    group_id: %w( party_id faction_id faktion_id bloc_id block_id org_id organization_id organisation_id),
    image: %w(img picture photo photograph portrait),
    name: %w(name_en),
    patronymic_name: %w(patronym patronymic),
    phone: %w(tel telephone),
    source: %w(src),
    start_date: %w(start started from since),
    term: %w(legislative_period),
    website: %w(homepage href url site),
  }
  def remap(str)
    REMAP.find(->{[str]}) { |k, v| v.include? str.to_s }.first.to_sym
  end

  class Reconciler

    def initialize(existing_rows, instructions)
      @_existing_rows = existing_rows
      @_instructions  = instructions
      @_instructions[:overrides] ||= {}
      @_existing_field = instructions[:existing_field].to_sym rescue raise("Need an `existing_field` to match on")
      @_incoming_field = instructions[:incoming_field].to_sym rescue raise("Need an `incoming_field` to match on")
    end

    def fuzzer
      @_fuzzer ||= FuzzyMatch.new(@_existing_rows, read: @_existing_field)
    end

    def find_all(incoming_row)
      if incoming_row[@_incoming_field].to_s.empty?
        warn "#{incoming_row} has no #{@_incoming_field}" 
        return []
      end

      # Short-circuit if we've already been told who this matches
      if exact_match = @_instructions[:overrides][incoming_row[@_incoming_field].to_sym]
        return @_existing_rows.find_all { |r| r[:id] == exact_match }
      end

      # Approximate match?
      if @_instructions.key? :amatch_threshold
        match = fuzzer.find_with_score(incoming_row[@_incoming_field])
        confidence = match[1].to_f * 100

        if confidence < @_instructions[:amatch_threshold].to_f
          warn "Too low match for: %s (Best = %s @ %.2f%%)".cyan % [ incoming_row[@_incoming_field], match.first[@_existing_field], confidence ]
          return []
        end

        warn "Matched %s to %s @ %.2f%%".yellow % [incoming_row[@_incoming_field], match.first[@_existing_field], confidence ] if confidence < @_instructions[:amatch_warning].to_f
        return @_existing_rows.find_all { |r| r[@_existing_field] == match.first[@_existing_field] }
      end

      @_existing_rows.find_all { |r| r[@_existing_field] == incoming_row[@_incoming_field] } 
    end

  end

  # http://codereview.stackexchange.com/questions/84290/combining-csvs-using-ruby-to-match-headers
  def combine_sources

    # Build the master list of columns
    all_headers = instructions(:sources).find_all { |src|
      src[:type] != 'term'
    }. map { |src| src[:file] }.reduce([]) do |all_headers, file|
      header_line = File.open(file, &:gets)     
      all_headers | CSV.parse_line(header_line).map { |h| remap(h.downcase) } 
    end

    merged_rows = []

    # Make sure all instructions have a `type`
    if (no_type = instructions(:sources).find { |src| src[:type].to_s.empty? })
      raise "Missing `type` in #{no_type} file"
    end

    # First get all the `membership` rows. 
    # Assume for now that each is unique, and simply concat them
   
    instructions(:sources).find_all { |src| src[:type].to_s.downcase == 'membership' }.each do |src| 
      file = src[:file] 
      puts "Add memberships from #{file}".magenta
      csv_table(file).each do |row|
        merged_rows << row.to_hash
      end
    end

    # Then merge with Person data files
    #   existing_field: the field in the existing data to match to
    #   incoming_field: the field in the incoming data to match with
    #
    # For non-exact matching set 'amatch_threshold' to a minimum % score
    # We also warn on any fuzzy match under the 'amatch_warning' % score
    #
    # To override to an exact match, supply the ID of the existing record 
    # e.g. (with incoming_field='name')
    #    "overrides": { "Ian Paisley, Jr.": "13852" }

    instructions(:sources).find_all { |src| %w(wikidata person).include? src[:type].to_s.downcase }.each do |pd|
      puts "Merging with #{pd[:file]}".magenta
      raise "No merge instructions" unless pd.key?(:merge) 

      warn "  Match incoming #{pd[:merge][:incoming_field]} to #{pd[:merge][:existing_field]}"

      reconciler = Reconciler.new(merged_rows, pd[:merge])
      incoming_data = csv_table(pd[:file])
      incoming_data.each do |incoming_row|
        # TODO factor this out to a Patcher again
        to_patch = reconciler.find_all(incoming_row)
        if to_patch && !to_patch.size.zero?
          to_patch.keep_if { |r| r[:term].to_s == incoming_row[:term].to_s } if pd[:merge][:term_match] 
          to_patch.each do |existing_row|
            # For now, only set values that are not already set (or are set to 'unknown')
            # TODO: have a 'clobber' flag (or list of values to trust the latter source for)
            incoming_row.keys.each do |h| 
              existing_row[h] = incoming_row[h] if existing_row[h].to_s.empty? || existing_row[h].to_s.downcase == 'unknown' 
            end
          end
        else
          warn "Can't match row to existing data: #{incoming_row.to_hash.reject { |k,v| v.to_s.empty? } }".red
        end
      end
    end

    # Map Areas 
    if area = instructions(:sources).find { |src| src[:type].to_s.downcase == 'area' } 
      ocds = CSV.table(area[:file], converters: nil)

      all_headers |= [:area, :area_id]

      if area[:generate] == 'area'
        merged_rows.each do |r|
          ocd = ocds.find { |o| o[:id] == r[:area_id] } or warn "No area for #{r}"
          r[:area] = ocd[:name] if ocd
        end

      else 
        # Generate IDs from names
        # So far only tested with Australia, so super-simple logic. 
        # TOOD: Expand this later

        fuzzer = FuzzyMatch.new(ocds, read: :name)
        finder = ->(r) { fuzzer.find(r[:area], must_match_at_least_one_word: true) }

        override = ->(name) { 
          return unless area[:merge].key? :overrides
          return unless override_id = area[:merge][:overrides][name.to_sym] 
          return '' if override_id.empty?
          ocds.find { |o| o[:id] == override_id } or raise "no match for #{override_id}"
        }

        areas = {}
        merged_rows.each do |r|
          raise "existing Area ID: #{r[:area_id]}" if r.key? :area_id
          unless areas.key? r[:area]
            areas[r[:area]] = override.(r[:area]) || finder.(r) 
            if areas[r[:area]].to_s.empty?
              warn "No area match for #{r[:area]}"
            else
              warn "Matched Area %s to %s" % [ r[:area].to_s.yellow, areas[r[:area]][:name].to_s.green ] unless areas[r[:area]][:name].include? " #{r[:area]} "
            end
          end
          next if areas[r[:area]].to_s.empty?
          r[:area_id] = areas[r[:area]][:id] 
        end
      end
    end
    
    # Then write it all out
    CSV.open("sources/merged.csv", "w") do |out|
      out << all_headers
      merged_rows.each { |r| out << all_headers.map { |header| r[header.to_sym] } }
    end

  end

end
