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

      def update_all(...)
        ArCache.pre_expire { delete_ar_cache_keys ? super : 0 }
      end

      def delete_all
        ArCache.pre_expire { delete_ar_cache_keys ? super : 0 }
      end

      private def delete_ar_cache_keys
        return true if klass.ar_cache_table.disabled?

        where_clause = ArCache::WhereClause.new(klass, arel.constraints)
        keys = if where_clause.cacheable? && where_clause.primary_key_index?
                 where_clause.primary_cache_keys
               else
                 pluck(primary_key).map { |item| klass.ar_cache_table.primary_cache_key(item) }
               end

        return false if keys.empty?

        @klass.connection.current_transaction.delete_ar_cache_keys(keys)
        @klass.connection.current_transaction.add_changed_table(@klass.table_name)
        true
      end

      private def exec_queries(&block)
        @skip_ar_cache ? super : ArCache::Query.new(self).exec_queries(&block).freeze
      end
    end
  end
end
