# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module CounterCache
      module ClassMethods
        # def update_counters(id, ...) ... only support ruby 2.7+
        def update_counters(id, counters)
          self.connection.skip_update_ar_cache_model_version
          super.tap { ArCache::Model.get(self).delete_by_primary_key(id) }
        end
      end
    end
  end
end
