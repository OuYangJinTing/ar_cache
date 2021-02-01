# frozen_string_literal: true

module ArCache
  class Monitor < ::ActiveRecord::Base # :nodoc: all
    self.table_name = 'ar_cache_monitors'

    serialize :unique_indexes,  Array, default: []
    serialize :ignored_columns, Array, default: []

    default_scope { skip_ar_cache }

    class << self
      def get(table_name)
        find_by(table_name: table_name)
      end

      def extract_table_from_sql(sql, type)
        sql = sql.downcase.split.join(' ') # Remove Newline
        table_names = ::ActiveRecord::Base.descendants.map(&:table_name).compact

        case type
        when :update
          sql.match(/^update.*(#{table_names.join('|')}).*set/).try(:[], 1)
        when :delete
          sql.match(/^delete.*from.*(#{table_names.join('|')})/).try(:[], 1)
        else
          raise SqlOperationError, "Unrecognized sql operation: #{sql}"
        end
      end

      def activate(model)
        monitor = get(model.table_name) || new(table_name: model.table_name)
        monitor.activate(model)
        monitor
      end

      def update_version(table_name)
        get(table_name)&.update_version if table_name.present?
      end
    end

    def activate(model)
      with_optimistic_retry do
        if disabled != model.disabled ||
           unique_indexes.any? { |index| model.unique_indexes.exclude?(index) } ||
           ignored_columns.any? { |column| model.ignored_columns.exclude?(column) }

          increment('version')
        end

        self.disabled = model.disabled
        self.unique_indexes = model.unique_indexes
        self.ignored_columns = model.ignored_columns
        save! if changed?
      end
    end

    def update_version
      with_optimistic_retry do
        increment('version')
        save!
      end

      ArCache::Model.get(table_name).update_version(version)
    end

    def with_optimistic_retry
      yield
    rescue ::ActiveRecord::StaleObjectError
      reload
      retry
    end
  end
end
