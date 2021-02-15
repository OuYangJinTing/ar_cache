# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Associations
      module SingularAssociation
        private def skip_statement_cache?(...)
          # Polymorphic associations do not support computing the class, so can't judge ArCache status.
          # But SingularAssociation query usually can hit the unique index, so here return true directly.
          return true if is_a?(::ActiveRecord::Associations::BelongsToPolymorphicAssociation)
          return true if reflection.klass.ar_cache_table.enabled?

          super
        end
      end
    end
  end
end
