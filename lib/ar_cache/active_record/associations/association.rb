# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Associations
      module Association
        def reload(...)
          loaded? ? ArCache.skip_cache { super } : super
        end
      end
    end
  end
end
