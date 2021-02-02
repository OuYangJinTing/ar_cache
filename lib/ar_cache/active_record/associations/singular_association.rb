# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Associations
      module SingularAssociation
        private def skip_statement_cache?(scope)
          reflection.klass.ar_cache_model.enabled? || super
        end
      end
    end
  end
end
