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
            keys.each { |k| ArCache.write(k, ArCache::PLACEHOLDER, raw: true, expires_in: 1.day) }
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
          connection.transaction_manager.add_transaction_table(table.name)
          return if table.disabled?

          super if read_uncommitted?
          ar_cache_primary_keys.push(*keys)
        end

        def update_ar_cache_table(table)
          connection.transaction_manager.add_transaction_table(table.name)
          return if table.disabled?

          super if read_uncommitted?
          ar_cache_tables.push(table)
        end

        # FIXME: The cache is removed after transaction commited, so dirty read may occur.
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

        def read_uncommitted?
          isolation_level == :read_uncommitted || !connection.transaction_manager.fully_joinable?
        end
      end

      module TransactionManager
        def initialize(...)
          super
          @transaction_tables = {}
        end

        def add_transaction_table(table_name)
          @transaction_tables[table_name] = true if fully_joinable?
        end

        def transaction_table?(table_name)
          @transaction_tables.key?(table_name)
        end

        def fully_joinable?
          @stack.all?(&:joinable?)
        end

        def within_new_transaction(...)
          super
        ensure
          @transaction_tables.clear if @stack.count(&:joinable?).zero?
        end
      end
    end
  end
end
