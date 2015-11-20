module Reconciliation
  class LegacyCsv
    def self.try_to_upgrade(reconciler, reconciled, incoming_data)
      if reconciled.any? && reconciled.headers != [:id, :uuid]
        warn 'Legacy reconciliation CSV detected'.red
        reconciled_rows = incoming_data.map do |row|
          found = reconciler.find_all(row, false).uniq { |r| r[:id] }
          next unless found.any?
          binding.pry if found.size != 1
          unless row[:id]
            warn "Can't automatically migrate legacy reconciliation for incoming data with no :id #{row}"
            break
          end
          CSV::Row.new([:id, :uuid], [row[:id], found.first[:uuid]])
        end
        if reconciled_rows
          reconciled = CSV::Table.new(reconciled_rows.compact)
          File.write(csv_file, reconciled.to_csv)
        end
      end
    end
  end
end
