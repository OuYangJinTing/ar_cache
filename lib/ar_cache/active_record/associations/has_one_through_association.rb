# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Associations
      module HasOneThroughAssociation
        PRELOADER = ::ActiveRecord::Associations::Preloader.new

        private def find_target
          return super if ArCache.skip_cache?
          return super unless ArCache.cache_reflection?(reflection) do
            through_association = owner.association(through_reflection.name)
            if ArCache::Query.new(through_association.scope).exec_queries_cacheable?(strict: false)
              source_association = source_reflection.active_record.new.association(source_reflection.name)
              ArCache::Query.new(source_association.scope).exec_queries_cacheable?(strict: false)
            end
          end

          if strict_loading? && owner.validation_context.nil?
            ::ActiveRecord::Base.strict_loading_violation!(owner: owner.class, reflection: reflection)
          end

          PRELOADER.preload(owner, reflection.name)
          target
        end
      end
    end
  end
end
