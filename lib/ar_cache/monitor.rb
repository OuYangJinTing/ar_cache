# frozen_string_literal: true

module ArCache
  class Monitor < ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord
    self.table_name = 'ar_cache_monitors'

    serialize :unique_indexes,  Array, default: []

    default_scope { skip_ar_cache }

    def self.get(table_name)
      find_by(table_name: table_name)
    end

    def self.version(table_name)
      get(table_name).version
    end

    def self.update_version(table_name)
      monitor = get(table_name)
      monitor.update_version
      monitor.version
    end

    def self.record(model)
      monitor = get(model.table_name) || new(table_name: model.table_name)
      monitor.record(model)
      monitor
    end

    def record(model)
      with_optimistic_retry do
        if disabled != model.disabled || unique_indexes.any? { |index| model.unique_indexes.exclude?(index) }
          self.version += 1
        end

        self.disabled = model.disabled
        self.unique_indexes = model.unique_indexes
        save! if changed?
      end
    end

    def update_version
      with_optimistic_retry do
        self.version += 1
        save!
      end
    end

    def with_optimistic_retry
      yield
    rescue ::ActiveRecord::StaleObjectError
      reload
      retry
    end
  end
end
