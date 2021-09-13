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

      def update_all(updates)
        return super if ar_cache_table.disabled?
        return super.tap { |rows| delete_ar_cache_primary_keys if rows.positive? } unless ArCache.support_returning?

        raise ArgumentError, "Empty list of attributes to change" if updates.blank?

        if eager_loading?
          relation = apply_join_dependency
          return relation.update_all(updates)
        end

        stmt = Arel::UpdateManager.new
        stmt.table(arel.join_sources.empty? ? table : arel.source)
        stmt.key = table[primary_key]
        stmt.take(arel.limit)
        stmt.offset(arel.offset)
        stmt.order(*arel.orders)
        stmt.wheres = arel.constraints

        if updates.is_a?(Hash)
          if klass.locking_enabled? &&
              !updates.key?(klass.locking_column) &&
              !updates.key?(klass.locking_column.to_sym)
            attr = table[klass.locking_column]
            updates[attr.name] = _increment_attribute(attr)
          end
          stmt.set _substitute_values(updates)
        else
          stmt.set Arel.sql(klass.sanitize_sql_for_assignment(updates, table.name))
        end

        delete_ar_cache_primary_keys_by_returning(stmt, "#{@klass} Update All")
      end

      def delete_all
        return super if ar_cache_table.disabled?
        return super.tap { |rows| delete_ar_cache_primary_keys if rows.positive? } unless ArCache.support_returning?

        invalid_methods = INVALID_METHODS_FOR_DELETE_ALL.select do |method|
          value = @values[method]
          method == :distinct ? value : value&.any?
        end
        if invalid_methods.any?
          raise ActiveRecordError.new("delete_all doesn't support #{invalid_methods.join(', ')}")
        end

        if eager_loading?
          relation = apply_join_dependency
          return relation.delete_all
        end

        stmt = Arel::DeleteManager.new
        stmt.from(arel.join_sources.empty? ? table : arel.source)
        stmt.key = table[primary_key]
        stmt.take(arel.limit)
        stmt.offset(arel.offset)
        stmt.order(*arel.orders)
        stmt.wheres = arel.constraints
        reset

        delete_ar_cache_primary_keys_by_returning(stmt, "#{@klass} Destroy")
      end

      private def delete_ar_cache_primary_keys
        where_clause = ArCache::WhereClause.new(klass, arel.constraints)
        if where_clause.cacheable? && where_clause.primary_key_index?
          keys = where_clause.primary_cache_keys
          connection.current_transaction.delete_ar_cache_primary_keys(keys)
        else
          connection.current_transaction.update_ar_cache_table(ar_cache_table)
        end
      end

      private def delete_ar_cache_primary_keys_by_returning(arel, name)
        result = connection.exec_query("#{arel.to_sql} RETURNING #{connection.quote_column_name(primary_key)}", name)
        keys = result.map { |r| ar_cache_table.primary_cache_key(r[primary_key]) }
        connection.current_transaction.delete_ar_cache_primary_keys(keys)
        result.length
      end

      private def exec_queries(&block)
        ArCache.skip_cache? ? super : ArCache::Query.new(self).exec_queries(&block).freeze
      end
    end
  end
end
