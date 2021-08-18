# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module ConnectionAdapters
      module NullTransaction
        def delete_ar_cache_primary_keys(keys, table)
          handle_ar_cache_primary_keys(keys) unless table.disabled?
        end

        def update_ar_cache_table(table)
          table.update_cache
        end

        def handle_ar_cache_primary_keys(keys)
          if ArCache::Configuration.cache_lock?
            keys.each { |k| ArCache.lock(k) }
          else
            ArCache.delete_multi(keys)
          end
        end
      end

      module Transaction
        include NullTransaction

        attr_reader :ar_cache_primary_keys, :ar_cache_tables

        def initialize(...)
          super
          @ar_cache_primary_keys = []
          @ar_cache_tables = []
        end

        def delete_ar_cache_primary_keys(keys, table)
          return if table.disabled?

          connection.transaction_manager.add_transaction_table(table.name)
          ar_cache_primary_keys.push(*keys)
        end

        def update_ar_cache_table(table)
          return if table.disabled?

          connection.transaction_manager.add_transaction_table(table.name)
          ar_cache_tables.push(table)
        end

        # FIXME: The cache is removed after transaction commited, so may read dirty record.
        #
        # SOLUTION: The lock cache key before operation, and then unlock it at the right time.
        # This need an extra cache operation, and it is expensive when delete a large number
        # of records. Don't fix for now.
        def commit
          super
        ensure
          if @run_commit_callbacks
            handle_ar_cache_primary_keys(ar_cache_primary_keys.uniq) if ar_cache_primary_keys.any?
            ar_cache_tables.uniq(&:name).each(&:update_cache) if ar_cache_tables.any?
          else
            connection.current_transaction.ar_cache_tables.push(*ar_cache_tables)
            connection.current_transaction.ar_cache_primary_keys.push(*ar_cache_primary_keys)
          end
        end
      end

      module TransactionManager
        def initialize(...)
          super
          @transaction_tables = {}
        end

        def add_transaction_table(table_name)
          @transaction_tables[table_name] = true if @stack.any?
        end

        def transaction_table?(table_name)
          @transaction_tables.key?(table_name)
        end

        def within_new_transaction(...)
          super
        ensure
          @transaction_tables.clear if @stack.zero?
        end
      end
    end
  end
end
