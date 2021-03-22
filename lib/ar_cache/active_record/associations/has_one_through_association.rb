# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Associations
      module HasOneThroughAssociation
        PRELOADER = ::ActiveRecord::Associations::Preloader.new

        private def find_target
          return super if ArCache.skip?
          return super unless ArCache.cache_reflection?(reflection) do
            ArCache::Query.new(owner.association(through_reflection.name).scope).exec_queries_cacheable? &&
            ArCache::Query.new(source_reflection.active_record.new.association(source_reflection.name).scope)
                          .exec_queries_cacheable?
          end

          if (owner.strict_loading? || reflection.strict_loading?) && owner.validation_context.nil?
            ::ActiveRecord::Base.strict_loading_violation!(owner: owner.class, reflection: reflection)
          end

          PRELOADER.preload(owner, reflection.name)
          target
        end
      end
    end
  end
end
