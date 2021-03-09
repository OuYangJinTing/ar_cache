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

          # TODO: Should not instantiate AR
          through_record = owner.send(reflection.through_reflection.name)
          through_record = through_record.first if through_record.is_a?(::ActiveRecord::Relation)
          return nil if through_record.nil? || through_record.destroyed?

          record = if reflection.scope
                     through_record.association(reflection.source_reflection_name).scope.merge(reflection.scope)
                   else
                     through_record.send(reflection.source_reflection_name)
                   end
          record = record.first if record.is_a?(::ActiveRecord::Relation)
          return nil unless record

          record.tap { |r| set_inverse_instance(r) }
        rescue StandardError
          super
        end
      end
    end
  end
end
