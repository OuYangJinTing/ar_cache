# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module InsertAll
      def execute
        super.tap do
          if on_duplicate == :update
            connection.current_transaction.update_ar_cache_table(model.ar_cache_table)
          else # insert
            connection.transaction_manager.add_transaction_table(model.table_name)
          end
        end
      end
    end
  end
end
