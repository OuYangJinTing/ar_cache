# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module InsertAll
      def execute
        return super if model.ar_cache_table.disabled?

        super.tap do |result|
          if result.includes_column?(model.primary_key)
            primary_cache_keys = result.pluck(model.primary_key).map { |v| model.ar_cache_table.primary_cache_key(v) }
            if update_duplicates?
              onnection.current_transaction.delete_ar_cache_primary_keys(primary_cache_keys)
            else
              connection.transaction_manager.add_ar_cache_transactions(primary_cache_keys)
            end
          else
            if update_duplicates?
              connection.current_transaction.update_ar_cache_table(model.ar_cache_table)
            else
              connection.transaction_manager.add_ar_cache_transactions(model.table_name)
            end
          end
        end
      end
    end
  end
end
