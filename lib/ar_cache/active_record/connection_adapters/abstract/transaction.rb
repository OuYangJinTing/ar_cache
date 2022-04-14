# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module ConnectionAdapters
      module NullTransaction
        def delete_ar_cache_keys(keys)
          expire_ar_cache_keys(keys)
        end

        def update_ar_cache_table(table)
          table.update_cache
        end

        private def expire_ar_cache_keys(keys)
          if ArCache::Configuration.cache_lock?
            keys.each { |k| ArCache.lock(k) }
          else
            ArCache.delete_multi(keys)
          end
        end
      end

      module Transaction
        include NullTransaction

        def ar_cache_keys
          @ar_cache_keys ||= []
        end

        def ar_cache_tables
          @ar_cache_tables ||= []
        end

        def delete_ar_cache_keys(keys)
          connection.transaction_manager.add_ar_cache_transactions(keys)
          ar_cache_keys.push(*keys)
        end

        def update_ar_cache_table(table)
          return if table.disabled?

          connection.transaction_manager.add_ar_cache_transactions(table.name)
          ar_cache_tables.push(table)
        end

        def commit
          super
        ensure
          if @run_commit_callbacks
            expire_ar_cache_keys(ar_cache_keys.uniq) if ar_cache_keys.any?
            ar_cache_tables.each(&:update_cache) if ar_cache_tables.any?
          else
            connection.current_transaction.ar_cache_tables.push(*ar_cache_tables)
            connection.current_transaction.ar_cache_keys.push(*ar_cache_keys)
          end
        end
      end

      module TransactionManager
        def initialize(...)
          super
          @ar_cache_transactions = {}
        end

        def add_ar_cache_transactions(keys)
          return if @stack.empty?

          if keys.is_a?(Array)
            keys.each { |k| @ar_cache_transactions[k] = true }
          else
            @ar_cache_transactions[keys] = true
          end
        end

        def ar_cache_transactions?(key)
          @ar_cache_transactions.key?(key)
        end

        def within_new_transaction(...)
          super
        ensure
          @ar_cache_transactions.clear if @stack.empty?
        end
      end
    end
  end
end
