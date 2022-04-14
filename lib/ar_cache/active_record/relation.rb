# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Relation
      def reload
        loaded? ? ArCache.skip_cache { super } : super
      end

      def explain
        ArCache.skip_cache { super }
      end

      private def exec_queries(&block)
        ArCache.skip_cache? ? super : ArCache::Query.new(self).exec_queries(&block).freeze
      end
    end
  end
end
