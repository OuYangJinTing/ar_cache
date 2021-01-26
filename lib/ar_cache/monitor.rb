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

    def self.activate(model)
      monitor = get(model.klass.table_name) || new(table_name: model.klass.table_name)

      if monitor.disabled? != model.disabled?
        !monitor.unique_indexes.all? { |index| model.unique_indexes.include?(index) } ||
          !monitor.ignored_columns.all? { |column| model.klass.ignored_columns.include?(column) }

        monitor.version = Time.now.to_i
      end

      monitor.disabled = model.disabled?
      monitor.unique_indexes = model.unique_indexes
      monitor.ignored_columns = model.klass.ignored_columns
      monitor.save! if monitor.changed?

      model.update_version(monitor.version)
    end

    def self.extract_table_from_sql(sql, type)
      sql = sql.downcase.split.join(' ') # Remove Newline and multiple consecutive spaces

      case type
      when :update
        sql.match(/^update.*(#{tables.join('|')}).*set/i).try(:[], 1)
      when :delete
        sql.match(/^delete.*from.*(#{tables.join('|')})/i).try(:[], 1)
      else
        raise SqlOperationError, "Unrecognized sql operation: #{sql}"
      end
    end

    def self.update_version(table_name)
      monitor = get(table_name)
      return unless monitor

      monitor.version = Time.now.to_i
      monitor.save!
      ArCache::Model.get(table_name).update_version(monitor.version)
    end

    def match_update_version(sql)
      # TODO: ...
    end
  end
end
