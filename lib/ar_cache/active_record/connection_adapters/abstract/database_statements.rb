# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module ConnectionAdapters
      module DatabaseStatements
        def select_all(arel, ...)
          result = super
          klass, select_values = arel.try(:klass_and_select_values)
          return result if klass.nil?

          klass.ar_cache_table.write(result.to_a)

          # TODO: Should filter result.columns and result.rows
          if select_values
            result.to_a.each { |r| r.slice!(*select_values) }
          elsif klass.ignored_columns.any?
            result.to_a.each { |r| r.except!(*klass.ignored_columns) }
          end

          result
        end

        # def insert(arel, ...)
        # end
        # alias create insert

        def update(arel, ...)
          super.tap { |num| update_ar_cache(arel) unless num.zero? }
        end

        def delete(arel, ...)
          super.tap { |num| update_ar_cache(arel) unless num.zero? }
        end

        def truncate(table_name, ...)
          super.tap { update_ar_cache_by_table(table_name) }
        end

        def truncate_tables(*table_names)
          super.tap do
            table_names.each { |table_name| update_ar_cache_by_table(table_name) }
          end
        end

        private def update_ar_cache(arel_or_sql_string)
          if arel_or_sql_string.is_a?(String)
            update_ar_cache_by_sql(arel_or_sql_string)
          else # is Arel::TreeManager
            update_ar_cache_by_arel(arel_or_sql_string)
          end
        end

        private def update_ar_cache_by_arel(arel)
          return if ArCache.skip_expire?

          arel_table = arel.ast.relation.is_a?(Arel::Table) ? arel.ast.relation : arel.ast.relation.left
          klass = arel_table.instance_variable_get(:@klass)
          current_transaction.update_ar_cache_table(klass.ar_cache_table)
        end

        private def update_ar_cache_by_sql(sql)
          sql = sql.downcase

          ArCache::Table.all.each do |table|
            current_transaction.update_ar_cache_table(table) if sql.include?(table.name)
          end
        end

        private def update_ar_cache_by_table(table_name)
          ArCache::Table.all.each do |table|
            break current_transaction.update_ar_cache_table(table) if table_name == table.name
          end
        end
      end
    end
  end
end
