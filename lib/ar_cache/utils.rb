# frozen_string_literal: true

module ArCache
  module Utils
    module_function

    def model(table_name)
      klass = table_name.classify.safe_constantize
      unless klass && klass < ActiveRecord::Base
        klass = ActiveRecord::Base.descendants.find { |k| k.table_name == table_name }
      end

      klass&.ar_cache_model
    end

    def extract_table_from_sql(sql, type)
      sql = sql.downcase.split.join(' ') # Remove Newline
      table_names = ActiveRecord::Base.descendants.filter_map { |klass| klass.table_name if klass.table_name }

      case type
      when :update
        sql.match(/^update.*(#{table_names.join('|')}).*set/).try(:[], 1)
      when :delete
        sql.match(/^delete.*from.*(#{table_names.join('|')})/).try(:[], 1)
      else
        raise SqlOperationError, "Unrecognized sql operation: #{sql}"
      end
    end
  end
end
