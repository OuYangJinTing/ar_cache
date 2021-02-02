# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Transactions
      def with_transaction_returning_status
        self.class.connection.disable_update_ar_cache_version
        super
      ensure
        self.class.connection.enable_update_ar_cache_version
      end
    end
  end
end
