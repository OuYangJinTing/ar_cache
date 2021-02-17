# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module ConnectionAdapters
      module Transaction
        def rollback_records
          if records
            already_exists_records = {}
            keys = records.filter_map do |record|
              next if record.destroyed?
              next if already_exists_records.key?(record)

              already_exists_records[record] = true
              record.ar_cache_table.primary_cache_key(record_orignal_id(record))
            end

            ArCache::Store.delete_multi(keys) if keys.any?
          end

          super
        end

        def commit_records # rubocop:disable Metrics/CyclomaticComplexity
          if records && @run_commit_callbacks
            already_exists_records = {}
            keys = records.filter_map do |record|
              next if record.previously_new_record? && record.persisted?
              next if already_exists_records.key?(record)

              already_exists_records[record] = true
              record.ar_cache_table.primary_cache_key(record_orignal_id(record))
            end

            ArCache::Store.delete_multi(keys) if keys.any?
          end

          super
        end

        private def record_orignal_id(record)
          record.previous_changes[record.ar_cache_table.primary_key]&.first || record.id_was
        end
      end
    end
  end
end
