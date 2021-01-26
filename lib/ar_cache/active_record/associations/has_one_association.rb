# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Associations
      module HasOneAssociation
        private def skip_statement_cache?(scope)
          !ArCache::Model.get(reflection.klass).disabled? || super
        end
      end
    end
  end
end
