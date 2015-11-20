module Reconciliation
  # Interface for reconciling incoming data
  class Interface
    attr_reader :merged_rows
    attr_reader :incoming_data
    attr_reader :merger

    def initialize(merged_rows, incoming_data, merger)
      @merged_rows = merged_rows
      @incoming_data = incoming_data
      @merger = merger
    end

    def generate!
      return unless merger[:reconciliation_file]

      # FIXME: Remove this once all CSVs have 'id,uuid' headers.
      LegacyCsv.try_to_upgrade(reconciler, reconciled, incoming_data)

      FileUtils.mkdir_p(File.dirname(csv_file))
      File.write(html_file, render)
      if need_reconciling.any?
        warn "#{need_reconciling.size} out of #{incoming_data.size} rows " \
          'not reconciled'.red
      end
      return if File.exist?(csv_file)
      warn "Need to create #{csv_file}".cyan
      abort "Created #{html_file} — please check it and re-run".green
    end

    def reconciled
      reconciled = CSV::Table.new([])
      reconciled = CSV.table(csv_file, converters: nil) if File.exist?(csv_file)
      reconciled
    end

    private

    def need_reconciling
      @need_reconciling ||= incoming_data.find_all do |d|
        reconciler.find_all(d).to_a.empty? && !reconciled.any? do |r|
          r[:id].to_s == d[:id]
        end
      end
    end

    def csv_file
      @csv_file ||= File.join('sources', merger[:reconciliation_file])
    end

    def render
      template.result(binding)
    end

    def html_file
      @html_file ||= csv_file.gsub('.csv', '.html')
    end

    def fuzzer
      @fuzzer ||= Fuzzer.new(merged_rows, need_reconciling, merger)
    end

    def matched
      @matched ||= fuzzer.find_all.sort_by(&:last).reverse
    end

    def reconciler
      @reconciler ||= Reconciler.new(merged_rows, merger, reconciled)
    end

    def existing_people
      @existing_people ||= merged_rows
                           .uniq { |row| row[:uuid] }
                           .sort_by { |row| row[:name] }
    end

    def incoming_field
      merger[:incoming_field]
    end

    def existing_field
      merger[:existing_field]
    end

    def template
      ERB.new(reconciliation_html)
    end

    def templates_dir
      @templates_dir ||= File.expand_path('../../../templates', __FILE__)
    end

    def reconciliation_html
      @reconciliation_html ||= File.read(
        File.join(templates_dir, 'reconciliation.html.erb')
      )
    end

    def reconciliation_js
      @reconciliation_js ||= File.read(
        File.join(templates_dir, 'reconciliation.js')
      )
    end

    def reconciliation_scss
      @reconciliation_scss ||= File.read(
        File.join(templates_dir, 'reconciliation.scss')
      )
    end

    def reconciliation_css
      @reconciliation_css ||= sass_engine.render
    end

    def sass_engine
      @sass_engine ||= Sass::Engine.new(
        reconciliation_scss, syntax: :scss, load_paths: [templates_dir]
      )
    end
  end
end
