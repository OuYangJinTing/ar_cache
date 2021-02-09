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
          through_record = begin
            if reflection.scope
              owner.association(reflection.through_reflection.name).scope.merge(reflection.scope).first
            else
              owner.send(reflection.through_reflection.name)
            end
          # NOTE: If scope depend on other table, the query will raise ActiveRecord::StatementInvalid.
          rescue ActiveRecord::StatementInvalid
            super
          end
          return nil if !through_record || through_record.destroyed?

          record = through_record.send(reflection.source_reflection.name)
          return nil unless record

          record.tap { |r| set_inverse_instance(r) }
        end
      end
    end
  end
end
