# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module ConnectionAdapters
      module Transaction
        def add_where_clause(where_clause)
          where_clause.cacheable? ? add_ar_cache_keys(where_clause.cache_keys) : add_ar_cache_table(where_clause.table)
        end

        def add_ar_cache_keys(cache_keys)
          if read_uncommitted?
            ArCache::Store.delete_multi(cache_keys)
          else
            @ar_cache_keys ||= []
            @ar_cache_keys.push(*cache_keys)
          end
        end

        def add_ar_cache_table(table)
          if read_uncommitted?
            table.update_version
          else
            @ar_cache_tables ||= []
            @ar_cache_tables.push(table)
          end
        end

        def read_uncommitted?
          is_a?(::ActiveRecord::ConnectionAdapters::NullTransaction) ||
            ArCache::Configuration.read_uncommitted ||
            isolation_level == :read_uncommitted ||
            !@has_unmaterialized_transactions
        end
      end

      module Commit
        def commit
          super.tap do
            @ar_cache_tables.uniq(&:table_name).each(&:update_version) if defined?(@ar_cache_tables)
            ArCache::Store.delete_multi(@ar_cache_keys.uniq) if defined?(@ar_cache_keys)
          end
        end
      end
    end
  end
end
