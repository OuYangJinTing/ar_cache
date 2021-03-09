# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Associations
      module HasOneThroughAssociation
        private def find_target # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
          return super if reflection.klass.ar_cache_table.disabled?
          return super if reflection.through_reflection.klass.ar_cache_table.disabled?

          if owner.strict_loading? && owner.validation_context.nil?
            Base.strict_loading_violation!(owner: owner.class, association: reflection.klass)
          end

          if reflection.strict_loading? && owner.validation_context.nil?
            Base.strict_loading_violation!(owner: owner.class, association: reflection.name)
          end

          ::ActiveRecord::Associations::Preloader.new.preload(owner, reflection.name)

          through_recoed = owner.send(reflection.through_reflection.name)
          through_recoed.nil? || through_recoed.destroyed? ? nil : owner.send(reflection.name)
        rescue StandardError
          super
        end
      end
    end
  end
end
