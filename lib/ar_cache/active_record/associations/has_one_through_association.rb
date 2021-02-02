# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Associations
      module HasOneThroughAssociation
        private def find_target
          return super if reflection.klass.ar_cache_model.disabled?
          return super if reflection.through_reflection.klass.ar_cache_model.disabled?

          if owner.strict_loading? && owner.validation_context.nil?
            Base.strict_loading_violation!(owner: owner.class, association: reflection.klass)
          end

          if reflection.strict_loading? && owner.validation_context.nil?
            Base.strict_loading_violation!(owner: owner.class, association: reflection.name)
          end

          # TODO: Should not instantiate AR
          through_record = owner.send(reflection.through_reflection.name)
          return nil unless through_record

          primary_key = reflection.source_reflection.active_record_primary_key
          foreign_key = reflection.source_reflection.foreign_key
          record = reflection.klass.find_by({ foreign_key => through_record.read_attribute(primary_key) })
          return nil unless record

          record.tap { |r| set_inverse_instance(r) }
        end
      end
    end
  end
end
