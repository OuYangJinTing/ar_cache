# frozen_string_literal: true

module ArCache
  class Monitor < ::ActiveRecord::Base # :nodoc: all
    self.table_name = 'ar_cache_monitors'

    serialize :unique_indexes, Array, default: []
    serialize :ignored_columns, Array, default: []

    default_scope { skip_ar_cache }

    def self.get(table_name)
      find_by(table_name: table_name)
    end

    def self.activate(model) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      monitor = get(model.table_name) || new(table_name: model.table_name)

      if monitor.version.blank? ||
         !!monitor.disabled != !!model.disabled ||
         !monitor.unique_indexes.all? { |index| model.unique_indexes.include?(index) } ||
         !monitor.ignored_columns.all? { |column| model.ignored_columns.include?(column) }

        monitor.update_version
      end

      monitor.disabled = model.disabled?
      monitor.unique_indexes = model.unique_indexes
      monitor.ignored_columns = model.ignored_columns
      monitor.save! if monitor.changed?
      monitor
    end

    def self.extract_table_from_sql(sql, type)
      sql = sql.downcase.split.join(' ') # Remove Newline
      table_names = ::ActiveRecord::Base.descendants.map(&:table_name).compact

      case type
      when :update
        sql.match(/^update.*(#{table_names.join('|')}).*set/i).try(:[], 1)
      when :delete
        sql.match(/^delete.*from.*(#{table_names.join('|')})/i).try(:[], 1)
      else
        raise SqlOperationError, "Unrecognized sql operation: #{sql}"
      end
    end

    def self.update_version(table_name)
      monitor = get(table_name)
      return unless monitor

      monitor.update_version
      monitor.save!
      ArCache::Model.get(table_name).update_version(monitor.version)
    end

    # TODO
    # def match_update_version(sql)
    # end

    def update_version
      self.version = Time.now.to_f
    end
  end
end
