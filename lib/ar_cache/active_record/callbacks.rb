# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Callbacks
      extend ActiveSupport::Concern

      included do
        after_commit(on: :create, prepend: true) { ar_cache_model.write(self) }
        after_commit(on: [:update, :destroy], prepend: true) { ar_cache_model.delete(self, previous: true) }
      end
    end
  end
end
