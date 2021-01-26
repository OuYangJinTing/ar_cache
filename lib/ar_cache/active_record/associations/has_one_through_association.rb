# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Associations
      module HasOneThroughAssociation
        private def find_target # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
          return super if ArCache::Model.get(reflection.klass).disabled?
          return super if ArCache::Model.get(reflection.source_reflection.active_record).disabled?

          if owner.strict_loading? && owner.validation_context.nil?
            Base.strict_loading_violation!(owner: owner.class, association: klass)
          end

          if reflection.strict_loading? && owner.validation_context.nil?
            Base.strict_loading_violation!(owner: owner.class, association: reflection.name)
          end

          # TODO: Should not instantiate AR
          through_record = owner.send(reflection.options[:through])
          return nil unless through_record

          primary_key = reflection.source_reflection.options[:primary_key] || klass.primary_key
          record = klass.find_by({ primary_key => through_record.read_attribute(reflection.foreign_key) })
          return nil unless record

          record.tap { |r| set_inverse_instance(r) }
        end
      end
    end
  end
end
