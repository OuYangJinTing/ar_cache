# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Associations
      module Association
        PRELOADER = ::ActiveRecord::Associations::Preloader.new

        def reload(...)
          loaded? ? ArCache.skip { super } : super
        end

        # TODO: Implement CollectionAssociation cache
        private def find_target # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
          return super if ArCache.skip? || reflection.collection?
          return super unless ArCache.cache_reflection?(reflection) do
            if reflection.is_a?(::ActiveRecord::Reflection::ThroughReflection)
              ArCache::Query.new(owner.association(through_reflection.name).scope).exec_queries_cacheable? &&
              ArCache::Query.new(through_reflection.klass.new.association(reflection.source_reflection_name).scope)
                            .exec_queries_cacheable?
            else
              ArCache::Query.new(scope).exec_queries_cacheable?
            end
          end

          if (owner.strict_loading? || reflection.strict_loading?) && owner.validation_context.nil?
            ::ActiveRecord::Base.strict_loading_violation!(owner: owner.class, reflection: reflection)
          end

          PRELOADER.preload(owner, reflection.name)
          Array.wrap(owner.association(reflection.name).target)
        end
      end
    end
  end
end
