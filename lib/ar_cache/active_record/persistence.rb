# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Persistence
      def reload(options = nil)
        ar_cache_model.delete(id)
        super
      end
    end
  end
end
