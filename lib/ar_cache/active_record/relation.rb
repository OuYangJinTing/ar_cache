# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Relation
      def reload
        loaded? ? ArCache.skip_cache { super } : super
      end

      def explain
        ArCache.skip_cache { super }
      end

      def update_all(...)
        return super if ar_cache_table.disabled?
        return super if ArCache.skip_cache?
        return super if ArCache.handle_cache_whitout_id.returning_clause?

        ArCache.skip_cache do
          if ArCache.handle_cache_whitout_id.query_id?
            ids, keys = extract_ids_and_primary_cache_keys
            unscoped.where(id: ids).update_all(...).tap do
              connection.current_transaction.delete_ar_cache_primary_keys(keys)
            end
          else
            super.tap { |num| connection.current_transaction.update_ar_cache_table(ar_cache_table) unless num.zero? }
          end
        end
      end

      def delete_all
        return super if ar_cache_table.disabled?
        return super if ArCache.skip_cache?
        return super if ArCache.handle_cache_whitout_id.returning_clause?

        ArCache.skip_cache do
          if ArCache.handle_cache_whitout_id.query_id?
            ids, keys = extract_ids_and_primary_cache_keys
            unscoped.where(id: ids).delete_all.tap do
              connection.current_transaction.delete_ar_cache_primary_keys(keys)
            end
          else
            super.tap { |num| connection.current_transaction.update_ar_cache_table(ar_cache_table) unless num.zero? }
          end
        end
      end

      private def extract_ids_and_primary_cache_keys
        where_clause = ArCache::WhereClause.new(klass, arel.constraints)
        if where_clause.cacheable? && where_clause.primary_key_index?
          [where_clause.primary_key_values, where_clause.primary_cache_keys]
        else
          ids = pluck(primary_key)
          primary_cache_keys = ids.map { |id| ar_cache_table.primary_cache_key(id) }
          [ids, primary_cache_keys]
        end
      end

      private def exec_queries(&block)
        ArCache.skip_cache? ? super : ArCache::Query.new(self).exec_queries(&block).freeze
      end
    end
  end
end
