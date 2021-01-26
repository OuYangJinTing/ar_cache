# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Relation # :nodoc: all
      def skip_ar_cache
        tap { @skip_ar_cache = true }
      end

      private def ar_cache_query
        @ar_cache_query ||= ArCache::Query.new(self, ar_cache_model)
      end

      private def ar_cache_model
        @ar_cache_model ||= ArCache::Model.get(klass)
      end

      private def exec_queries(&block) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
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
            elsif @skip_ar_cache # || ::ActiveRecord::ExplainRegistry.collect?
              klass.find_by_sql(arel, &block).freeze
            else
              ar_cache_query.exec_queries(&block).freeze
            end

          ar_cache_model.write(*records) unless @skip_ar_cache || ar_cache_model.disabled?

          preload_associations(records) unless skip_preloading_value

          records.each(&:readonly!) if readonly_value
          records.each(&:strict_loading!) if strict_loading_value

          records
        end
      end
    end
  end
end
