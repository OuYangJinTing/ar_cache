# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module ConnectionAdapters
      module DatabaseStatements
        # TODO
        # def execute(sql, name = nil)
        # end

        def update(arel, name = nil, binds = [])
          super.tap { update_ar_cache_version(arel, :update) }
        end

        def delete(arel, name = nil, binds = [])
          super.tap { update_ar_cache_version(arel, :delete) }
        end

        # def truncate(table_name, ...) ... only support ruby 2.7+
        def truncate(table_name, name = nil)
          super.tap { ArCache::Utils.model(table_name)&.update_version }
        end

        def truncate_tables(*table_names)
          super.tap do
            table_names.each { |table_name| ArCache::Utils.model(table_name)&.update_version }
          end
        end

        private def update_ar_cache_version(arel_or_sql_string, type)
          if disabled_update_ar_cache_version?
            enable_update_ar_cache_version
          elsif arel_or_sql_string.is_a?(Arel)
            arel_or_sql_string.ast.relation.instance_variable_get(:@klass).ar_cache_model.update_version
          else
            table_name = ArCache::Utils.extract_table_from_sql(arel_or_sql_string, type)
            ArCache::Utils.model(table_name)&.update_version if table_name
          end
        end
      end
    end
  end
end
