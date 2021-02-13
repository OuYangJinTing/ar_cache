# frozen_string_literal: true

module ArCache
  class Record < ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord
    self.table_name = 'ar_cache_records'

    serialize :unique_indexes, Array, default: []
    serialize :ignored_columns, Array, default: []

    default_scope { skip_ar_cache }

    def self.get(table_name)
      find_by(table_name: table_name)
    end

    def self.version(table)
      (get(table.name) || store(table)).version
    end

    def self.update_version(table)
      record = get(table.name)
      return store(table).version unless record

      record.update_version
      record.version
    end

    def self.store(table)
      record = get(table.name) || new(table_name: table.name)
      record.store(table)
      record
    end

    def store(table)
      with_optimistic_retry do
        if table_md5 != table.md5 ||
           (unique_indexes - table.unique_indexes).any? ||
           (ignored_columns - table.ignored_columns).any?

          self.version += 1
        end

        self.table_md5 = table.md5
        self.unique_indexes = table.unique_indexes
        self.ignored_columns = table.ignored_columns

        save! if changed?
      end
    end

    def update_version
      with_optimistic_retry do
        self.version += 1
        save!
      end
    end

    private def with_optimistic_retry
      yield
    rescue ::ActiveRecord::StaleObjectError
      reload
      retry
    end
  end
end
