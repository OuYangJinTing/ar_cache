# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Associations
      module SingularAssociation
        private def skip_statement_cache?(...)
          return super if ArCache.skip_cache?
          return true if ArCache.cache_reflection?(reflection) do
            ArCache::Query.new(scope).exec_queries_cacheable?(strict: false)
          end

          super
        end
      end
    end
  end
end
