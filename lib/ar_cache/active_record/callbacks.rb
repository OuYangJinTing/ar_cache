# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Callbacks
      extend ActiveSupport::Concern

      included do
        after_commit(on: :create, prepend: true) { ar_cache_model.write(self) }
      end
    end
  end
end
