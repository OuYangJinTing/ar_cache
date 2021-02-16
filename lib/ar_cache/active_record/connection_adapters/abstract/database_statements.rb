# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module ConnectionAdapters
      module DatabaseStatements
        # TODO
        # def execute(sql, name = nil)
        # end

        def insert(...)
          super.tap { Thread.current[:skip_update_ar_cache_version] = false }
        end
        alias create insert

        def update(arel, ...)
          super.tap { |num| update_ar_cache_version(arel) unless num.zero? }
        end

        def delete(arel, ...)
          super.tap { |num| update_ar_cache_version(arel) unless num.zero? }
        end

        def truncate(table_name, ...)
          super.tap { update_ar_cache_version_by_table(table_name) }
        end

        def truncate_tables(*table_names)
          super.tap do
            table_names.each { |table_name| update_ar_cache_version_by_table(table_name) }
          end
        end

        private def update_ar_cache_version(arel_or_sql_string)
          if current_transaction.try(:isolation_level) == :read_uncommitted
            Thread.current[:skip_update_ar_cache_version] = false
          end

          if Thread.current[:skip_update_ar_cache_version]
            Thread.current[:skip_update_ar_cache_version] = false
          elsif arel_or_sql_string.is_a?(String)
            update_ar_cache_version_by_sql(arel_or_sql_string)
          else # is Arel::TreeManager
            update_ar_cache_version_by_arel(arel_or_sql_string)
          end
        end

        private def update_ar_cache_version_by_arel(arel)
          # arel.ast.relation may be of the following types:
          #   - Arel::Nodes::JoinSource
          #   - Arel::Table
          arel_table = arel.ast.relation.is_a?(Arel::Table) ? arel.ast.relation : arel.ast.relation.left
          klass = arel_table.instance_variable_get(:@klass)
          table = klass.ar_cache_table
          return if table.disabled?

          where_clause = ArCache::WhereClause.new(klass, arel.ast.wheres)
          table.update_version unless where_clause.delete_cache_keys
        end

        private def update_ar_cache_version_by_sql(sql)
          sql = sql.downcase
          ArCache::Table.all.each { |table| table.update_version if sql.include?(table.name) }
        end

        private def update_ar_cache_version_by_table(table_name)
          ArCache::Table.all.each { |table| table.update_version if table_name.casecmp?(table.name) }
        end
      end
    end
  end
end
