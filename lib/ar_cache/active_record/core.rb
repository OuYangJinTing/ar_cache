# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Core
      module ClassMethods
        # The #find use statement cache execute querying first, so need force skip.
        def find(...)
          ArCache.skip? || ar_cache_table.disabled? ? super : all.find(...)
        end

        # The #find_by use statement cache execute querying first, so need force skip.
        def find_by(...)
          ArCache.skip? || ar_cache_table.disabled? ? super : all.find_by(...)
        end
      end
    end
  end
end
