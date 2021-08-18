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

        ArCache.skip_expire do
          keys = ar_cache_primary_keys
          if keys.any?
            super
            connection.current_transaction.delete_ar_cache_primary_keys(keys)
          else
            0
          end
        end
      end

      def delete_all
        return super if ar_cache_table.disabled?

        ArCache.skip_expire do
          keys = ar_cache_primary_keys
          if keys.any?
            super
            connection.current_transaction.delete_ar_cache_primary_keys(keys)
          else
            0
          end
        end
      end

      private def ar_cache_primary_keys
        where_clause = ArCache::WhereClause.new(klass, arel.constraints)
        if where_clause.cacheable? && where_clause.primary_key_index?
          where_clause.primary_cache_keys
        else
          pluck(primary_key).map { |id| klass.ar_cache_table.primary_cache_key(id) }
        end
      end

      private def exec_queries(&block)
        ArCache.skip_cache? ? super : ArCache::Query.new(self).exec_queries(&block).freeze
      end
    end
  end
end
