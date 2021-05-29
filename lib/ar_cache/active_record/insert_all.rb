# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module InsertAll
      def execute
        super.tap do
          connection.current_transaction.update_ar_cache_table(model.ar_cache_table) if on_duplicate == :update
        end
      end
    end
  end
end
