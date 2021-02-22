# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Relation
      def skip_ar_cache
        tap { @skip_ar_cache = true }
      end

      def explain
        @skip_ar_cache = true
        super
      end

      private def exec_queries(&block) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/MethodLength
        skip_query_cache_if_necessary do
          records =
            if where_clause.contradiction?
              []
            elsif eager_loading?
              apply_join_dependency do |relation, join_dependency|
                if relation.null_relation?
                  []
                else
                  relation = join_dependency.apply_column_aliases(relation)
                  rows = connection.select_all(relation.arel, 'SQL')
                  join_dependency.instantiate(rows, strict_loading_value, &block)
                end.freeze
              end
            elsif @skip_ar_cache ||
                  klass.ar_cache_table.disabled? ||
                  connection.transaction_manager.changed_table?(table_name)
              klass.find_by_sql(arel, &block).freeze
            else
              ArCache::Query.new(self).exec_queries(&block).freeze
            end

          preload_associations(records) unless skip_preloading_value

          records.each(&:readonly!) if readonly_value
          records.each(&:strict_loading!) if strict_loading_value

          records
        end
      end
    end
  end
end
