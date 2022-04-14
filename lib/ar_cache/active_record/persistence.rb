# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Persistence
      def reload(...)
        ArCache.skip_cache { super }
      end
    end
  end
end
