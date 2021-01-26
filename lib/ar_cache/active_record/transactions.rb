# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Transactions
      def with_transaction_returning_status
        self.class.connection.skip_update_ar_cache_model_version
        super
      ensure
        self.class.connection.cancel_update_ar_cache_model_version
      end
    end
  end
end
