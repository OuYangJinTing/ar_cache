# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module ConnectionAdapters
      module DatabaseStatements # :nodoc: all
        # def update(sql, ...) ... only support ruby 2.7+
        # def execute(sql, name = nil)
        #   super.tap { ArCache::Monitor.match_update_version(sql) }
        # end

        # def update(arel, ...) ... only support ruby 2.7+
        def update(arel, name = nil, binds = [])
          super.tap { update_ar_cache_model_version(arel, :update) }
        end

        # def delete(arel, ...) ... only support ruby 2.7+
        def delete(arel, name = nil, binds = [])
          super.tap { update_ar_cache_model_version(arel, :delete) }
        end

        # def truncate(table_name, ...) ... only support ruby 2.7+
        def truncate(table_name, name = nil)
          super.tap { ArCache::Monitor.update_version(table_name) }
        end

        def truncate_tables(*table_names)
          super.tap do
            table_names.each { |table_name| ArCache::Monitor.update_version(table_name) }
          end
        end

        private def update_ar_cache_model_version(arel_or_sql_string, type)
          return cancel_update_ar_cache_model_version if skip_update_ar_cache_model_version?

          if arel_or_sql_string.is_a?(Arel)
            ArCache::Monitor.update_version(arel_or_sql_string.ast.relation.name)
          else
            ArCache::Monitor.update_version(ArCache::Monitor.extract_table_from_sql(arel_or_sql_string, type))
          end
        end
      end
    end
  end
end
