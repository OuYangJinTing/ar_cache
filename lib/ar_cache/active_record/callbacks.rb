# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Callbacks
      extend ActiveSupport::Concern

      included do
        after_commit(on: :create, prepend: true) { ar_cache_model.write([self]) if ar_cache_model.enabled? }
      end
    end
  end
end
