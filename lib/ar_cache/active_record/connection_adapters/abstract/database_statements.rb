# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module ConnectionAdapters
      module DatabaseStatements
        INSERT_REGEXP = /insert\s+into\s("[A-Za-z0-9_."\[\]\s]+"|[A-Za-z0-9_."\[\]]+)\s*/im.freeze
        DELETE_REGEXP = /delete\s+from\s("[A-Za-z0-9_."\[\]\s]+"|[A-Za-z0-9_."\[\]]+)\s*/im.freeze
        UPDATE_REGEXP = /update\s("[A-Za-z0-9_."\[\]\s]+"|[A-Za-z0-9_."\[\]]+)\s*/im.freeze

        def select_all(arel, ...)
          result = super
          klass, select_values = arel.try(:klass_and_select_values)
          return result if klass.nil?

          klass.ar_cache_table.write(result.to_a)

          if select_values
            result.each { |r| r.slice!(*select_values) }
            result.set_instance_variable(:@columns, select_values)
          elsif klass.ignored_columns.any?
            result.each { |r| r.except!(*klass.ignored_columns) }
            result.set_instance_variable(:@columns, result.columns - klass.ignored_columns)
          end

          result
        end

        def insert(arel, ...)
          super.tap do |id|
            table_name = arel.is_a?(String) ? arel.match(INSERT_REGEXP)[1] : arel.ast.relation.name
            ar_cache_table = ::ArCache::Table[table_name]
            cache_key = ar_cache_table.primary_cache_key(id)
            transaction_manager.add_ar_cache_transactions(cache_key)
          end
        end
        alias create insert

        def update(arel, name = nil, binds = [])
          if arel.is_a?(String)
            ar_cache_table = ::ArCache::Table[arel.match(UPDATE_REGEXP)[1]]
            super.tap { current_transaction.update_ar_cache_table(ar_cache_table) }
          elsif arel.ar_cache_table.disabled?
            super
          elsif arel.recognizable_ar_cache?
            super.tap { arel.delete_ar_cache_keys(self) }
          else
            if ArCache.enabled_returning_clause?
              update_with_ar_cache(arel, name, binds)
            else
              super.tap { current_transaction.update_ar_cache_table(arel.ar_cache_table) }
            end
          end
        end

        def delete(arel, name = nil, binds = [])
          if arel.is_a?(String)
            ar_cache_table = ::ArCache::Table[arel.match(DELETE_REGEXP)[1]]
            super.tap { current_transaction.update_ar_cache_table(ar_cache_table) }
          elsif arel.ar_cache_table.disabled?
            super
          elsif arel.recognizable_ar_cache?
            super.tap { arel.delete_ar_cache_keys(self) }
          else
            if ArCache.enabled_returning_clause?
              delete_with_ar_cache(arel, name, binds)
            else
              super.tap { current_transaction.update_ar_cache_table(arel.ar_cache_table) }
            end
          end
        end

        def truncate(table_name, ...)
          super.tap { current_transaction.update_ar_cache_table(::ArCache::Table[table_name]) }
        end

        def truncate_tables(*table_names)
          super.tap do
            table_names.each { |table_name| current_transaction.update_ar_cache_table(::ArCache::Table[table_name]) }
          end
        end

        private def delete_with_ar_cache(arel, name = nil, binds = [])
          sql, binds = to_sql_and_binds(arel, binds)
          sql = "#{sql} RETURNING #{quote_column_name(arel.ar_cache_table.primary_key)}"
          result = exec_query(sql, name, binds)
          cache_keys = result.rows.map { |row| arel.ar_cache_table.primary_cache_key(row.first) }
          current_transaction.delete_ar_cache_keys(cache_keys)
          result.length
        end
        alias :update_with_ar_cache :delete_with_ar_cache
      end
    end
  end
end
