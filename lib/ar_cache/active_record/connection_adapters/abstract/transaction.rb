# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module ConnectionAdapters
      module NullTransaction
        def delete_ar_cache_keys(keys, delay: false) # rubocop:disable Lint/UnusedMethodArgument
          ArCache::Store.delete_multi(keys)
        end

        def update_ar_cache_table(table, delay: false) # rubocop:disable Lint/UnusedMethodArgument
          table.update_version
        end

        def add_changed_table(...); end
      end

      module Transaction
        include NullTransaction

        def initialize(...)
          super
          @ar_cache_keys = []
          @ar_cache_tables = []
        end

        def delete_ar_cache_keys(keys, delay: false)
          super if !delay && read_uncommitted?
          @ar_cache_keys.push(*keys)
        end

        def update_ar_cache_table(table, delay: false)
          add_changed_table(table.name) unless delay

          super if !delay && read_uncommitted?
          @ar_cache_tables.push(table)
        end

        def add_changed_table(table_name)
          connection.transaction_manager.add_changed_table(table_name)
        end

        # FIXME: Cache update and transaction commit may cause dirty reads during this period!
        def commit
          super
        ensure
          if @run_commit_callbacks
            @ar_cache_tables.uniq(&:name).each(&:update_version) if @ar_cache_tables.any?
            ArCache::Store.delete_multi(@ar_cache_keys.uniq) if @ar_cache_keys.any?
          else
            transaction = connection.current_transaction
            @ar_cache_tables.each { |table| transaction.update_ar_cache_table(table, delay: true) }
            transaction.delete_ar_cache_keys(@ar_cache_keys, delay: true)
          end
        end

        def read_uncommitted?
          ArCache::Configuration.read_uncommitted ||
            isolation_level == :read_uncommitted ||
            !connection.transaction_manager.fully_joinable?
        end
      end

      module TransactionManager
        def initialize(...)
          super
          @changed_tables = {}
        end

        def add_changed_table(table_name)
          @changed_tables[table_name] = true if fully_joinable?
        end

        def changed_table?(table_name)
          @changed_tables.key?(table_name)
        end

        def fully_joinable?
          @stack.all?(&:joinable?)
        end

        def within_new_transaction(...)
          super
        ensure
          @changed_tables = {} if @stack.count(&:joinable?).zero?
        end
      end
    end
  end
end
