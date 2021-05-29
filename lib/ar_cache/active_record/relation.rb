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
        ArCache.skip_expire { delete_ar_cache_primary_keys ? super : 0 }
      end

      def delete_all
        ArCache.skip_expire { delete_ar_cache_primary_keys ? super : 0 }
      end

      private def delete_ar_cache_primary_keys
        return true if klass.ar_cache_table.disabled?

        where_clause = ArCache::WhereClause.new(klass, arel.constraints)
        keys = if where_clause.cacheable? && where_clause.primary_key_index?
                 where_clause.primary_cache_keys
               else
                 pluck(primary_key).map { |item| klass.ar_cache_table.primary_cache_key(item) }
               end

        return false if keys.empty?

        @klass.connection.current_transaction.delete_ar_cache_primary_keys(keys, @klass.ar_cache_table)
        true
      end

      private def exec_queries(&block)
        ArCache.skip_cache? ? super : ArCache::Query.new(self).exec_queries(&block).freeze
      end
    end
  end
end
