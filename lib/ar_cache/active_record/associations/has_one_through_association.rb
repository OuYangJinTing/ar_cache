# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Associations
      module HasOneThroughAssociation
        private def find_target # rubocop:disable Metrics/CyclomaticComplexity
          return super if ArCache.skip?
          return super if reflection.klass.ar_cache_table.disabled?
          return super if reflection.through_reflection.klass.ar_cache_table.disabled?

          if (owner.strict_loading? || reflection.strict_loading?) && owner.validation_context.nil?
            Base.strict_loading_violation!(owner: owner.class, reflection: reflection)
          end

          ArCache::PRELOADER.preload(owner, reflection.name)
          owner.send(reflection.name)
        rescue StandardError
          super
        end
      end
    end
  end
end
