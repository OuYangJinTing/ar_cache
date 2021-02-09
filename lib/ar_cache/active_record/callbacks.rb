# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Callbacks
      extend ActiveSupport::Concern

      included do
        after_commit(on: %i[update destroy], prepend: true) { ar_cache_table.delete(id) }
      end
    end
  end
end
