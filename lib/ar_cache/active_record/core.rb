# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Core
      module ClassMethods
        # The #find and #find_by use ActiveRecord::StatementCache to execute querying first.
        # For ArCache, we need force skip ActiveRecord::StatementCache.

        def find(...)
          ArCache.skip_cache? || ar_cache_table.disabled? ? super : all.find(...)
        end

        def find_by(...)
          ArCache.skip_cache? || ar_cache_table.disabled? ? super : all.find_by(...)
        end
      end
    end
  end
end
