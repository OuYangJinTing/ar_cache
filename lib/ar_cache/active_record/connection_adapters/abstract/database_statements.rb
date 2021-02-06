# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module ConnectionAdapters
      module DatabaseStatements
        # TODO
        # def execute(sql, name = nil)
        # end

        # upsert_all use this method, so need update cache version
        def exec_insert_all(sql, name)
          super.tap { update_ar_cache_version(sql) }
        end

        def update(arel, name = nil, binds = [])
          super.tap { |num| update_ar_cache_version(arel) unless num.zero? }
        end

        def delete(arel, name = nil, binds = [])
          super.tap { |num| update_ar_cache_version(arel) unless num.zero? }
        end

        def truncate(table_name, name = nil)
          super.tap { update_ar_cache_version(table_name) }
        end

        def truncate_tables(*table_names)
          super.tap do
            table_names.each { |table_name| update_ar_cache_version(table_name) }
          end
        end

        private def update_ar_cache_version(arel_or_sql_or_table_name) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
          if arel_or_sql_or_table_name.is_a?(Arel::TreeManager)
            # arel.ast.relation may be of the following types:
            #   - Arel::Nodes::JoinSource
            #   - Arel::Table
            arel = arel_or_sql_or_table_name
            arel_table = arel.ast.relation.is_a?(Arel::Table) ? arel.ast.relation : arel.ast.relation.left
            model = arel_table.instance_variable_get(:@klass).ar_cache_model
            return if model.disabled?

            where_clause = ArCache::WhereClause.new(model, arel.ast.wheres)
            model.update_version unless where_clause.delete_cache_keys
          elsif arel_or_sql_or_table_name.include?(' ') # is sql
            sql = arel_or_sql_or_table_name.downcase
            ArCache::Model.all.each { |m| m.update_version if sql.include?(m.table_name) }
          else # is table_name
            table_name = arel_or_sql_or_table_name
            ArCache::Model.all.each { |m| m.update_version if m.table_name == table_name }
          end
        end
      end
    end
  end
end
