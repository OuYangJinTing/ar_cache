# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Transactions
      def with_transaction_returning_status
        @skip_update_ar_cache_version = true
        super
      ensure
        @skip_update_ar_cache_version = false
      end
    end
  end
end
