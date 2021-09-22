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
            ar_cache_table = extract_ar_cache_table(arel, :insert)
            primary_cache_key = ar_cache_table.primary_cache_key(id)
            transaction_manager.add_ar_cache_transactions(primary_cache_key)
          end
        end
        alias create insert

        def update(arel, name = nil, binds = [])
          return super if ArCache.skip_expire?

          ar_cache_table = extract_ar_cache_table(arel, :update)
          if ar_cache_table.disabled?
            super
          elsif ArCache.handle_cache_whitout_id.returning_clause?
            ar_cache_update(arel, name, binds, ar_cache_table)
          else
            super.tap { |num| current_transaction.update_ar_cache_table(ar_cache_table) unless num.zero? }
          end
        end

        def delete(arel, name = nil, binds = [])
          return super if ArCache.skip_expire?

          ar_cache_table = extract_ar_cache_table(arel, :delete)
          if ar_cache_table.disabled?
            super
          elsif ArCache.handle_cache_whitout_id.returning_clause?
            ar_cache_delete(arel, name, binds, ar_cache_table)
          else
            super.tap { |num| current_transaction.update_ar_cache_table(ar_cache_table) unless num.zero? }
          end
        end

        def truncate(table_name, ...)
          super.tap { update_ar_cache_by_table(table_name) }
        end

        def truncate_tables(*table_names)
          super.tap do
            table_names.each { |table_name| update_ar_cache_by_table(table_name) }
          end
        end

        private def extract_ar_cache_table(arel, mode)
          if arel.is_a?(String)
            table_name = if mode == :insert
              arel.match(INSERT_REGEXP)[1]
            elsif mode == :delete
              arel.match(DELETE_REGEXP)[1]
            else # update
              arel.match(UPDATE_REGEXP)[1]
            end
            ArCache::Table.find(table_name)
          else # Arel::TreeManager
            arel_table = arel.ast.relation.is_a?(Arel::Table) ? arel.ast.relation : arel.ast.relation.left
            arel_table.instance_variable_get(:@klass).ar_cache_table
          end
        end

        private def ar_cache_update(arel, name, binds, ar_cache_table)
          sql, binds = to_sql_and_binds(arel, binds)
          sql = "#{sql} RETURNING #{quote_column_name(ar_cache_table.primary_key)}"
          result = exec_query(sql, name)
          keys = result.map { |r| ar_cache_table.primary_cache_key(r[ar_cache_table.primary_key]) }
          current_transaction.delete_ar_cache_primary_keys(keys)
          result.length
        end
        alias ar_cache_delete ar_cache_update

        private def update_ar_cache_by_table(table_name)
          ar_cache_table = ArCache::Table.find(table_name)
          current_transaction.update_ar_cache_table(ar_cache_table)
        end
      end
    end
  end
end
