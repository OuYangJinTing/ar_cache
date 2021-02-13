# frozen_string_literal: true

class ArCacheHelper
  class << self
    def savepoint
      ActiveRecord::Base.connection.begin_transaction(joinable: false)
      yield
    ensure
      ActiveRecord::Base.connection.rollback_transaction
    end
  end
end
