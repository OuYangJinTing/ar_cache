# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module InsertAll
      def execute
        ar_cache_table = ::ArCache::Table[model.table_name]
        return super if ar_cache_table.disabled?

        super.tap do |result|
          if result.includes_column?(ar_cache_table.primary_key)
            cache_keys = result.map { |h| ar_cache_table.primary_cache_key(h[ar_cache_table.primary_key]) }
            if update_duplicates?
              connection.current_transaction.delete_ar_cache_keys(cache_keys)
            else
              connection.transaction_manager.add_ar_cache_transactions(cache_keys)
            end
          else
            if update_duplicates?
              connection.current_transaction.update_ar_cache_table(ar_cache_table)
            else
              connection.transaction_manager.add_ar_cache_transactions(ar_cache_table.name)
            end
          end
        end
      end
    end
  end
end
