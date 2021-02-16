# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Callbacks
      extend ActiveSupport::Concern

      included do
        after_commit(on: %i[update destroy], prepend: true) do
          ar_cache_table.delete(previous_changes[ar_cache_table.primary_key].try(:first) || id_was)
        end

        after_rollback(prepend: true) do
          ar_cache_table.delete(previous_changes[ar_cache_table.primary_key].try(:first) || id_was) unless destroyed?
        end
      end
    end
  end
end
