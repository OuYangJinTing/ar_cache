# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Callbacks
      extend ActiveSupport::Concern

      included do
        after_rollback -> { ar_cache_table.delete(id) unless destroyed? }
      end
    end
  end
end
