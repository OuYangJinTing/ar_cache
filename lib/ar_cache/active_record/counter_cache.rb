# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module CounterCache
      module ClassMethods
        def update_counters(id, counters)
          connection.disable_update_ar_cache_version
          super.tap { ar_cache_model.delete_by_primary_key(id) }
        ensure
          connection.enable_update_ar_cache_version
        end
      end
    end
  end
end
