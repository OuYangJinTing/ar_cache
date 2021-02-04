# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module ConnectionAdapters
      module DatabaseStatements
        # TODO
        # def execute(sql, name = nil)
        # end

        # upsert_all use this method
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

        private def update_ar_cache_version(arel_or_sql_or_table_name)
          if arel_or_sql_or_table_name.is_a?(Arel::TreeManager)
            update_ar_cache_version_by_arel(arel_or_sql_or_table_name)
          elsif arel_or_sql_or_table_name.include?(' ')
            update_ar_cache_version_by_sql(arel_or_sql_or_table_name)
          else # is table_name
            update_ar_cache_version_by_table_name(arel_or_sql_or_table_name)
          end
        end

        private def update_ar_cache_version_by_arel(arel)
          # arel.ast.relation may be of the following types:
          #   - Arel::Nodes::JoinSource
          #   - Arel::Table
          arel_table = arel.ast.relation.is_a?(Arel::Table) ? arel.ast.relation : arel.ast.relation.left
          ar_cache_model = arel_table.instance_variable_get(:@klass).ar_cache_model
          return if ar_cache_model.disabled?

          where_clause = ArCache::WhereClause.new(ar_cache_model, arel.ast.wheres)
          ar_cache_model.update_version unless where_clause.delete_cache_keys
        end

        private def update_ar_cache_version_by_sql(sql)
          sql = sql.downcase

          ::ActiveRecord::Base.descendants.each do |klass|
            next unless klass.table_name
            next unless klass.base_class?
            next unless sql.include?(klass.table_name)

            klass.ar_cache_model.update_version
          end
        end

        private def update_ar_cache_version_by_table_name(table_name)
          klass = table_name.classify.safe_constantize
          unless klass && klass < ActiveRecord::Base
            klass = ActiveRecord::Base.descendants.find { |k| k.table_name == table_name }
          end

          klass&.ar_cache_model&.update_version
        end
      end
    end
  end
end
