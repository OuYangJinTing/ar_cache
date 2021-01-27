# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Callbacks # :nodoc: all
      extend ActiveSupport::Concern

      included do
        after_commit(on: :create, prepend: true) { ArCache::Model.get(self.class).write(self) }
        after_commit(on: :update, prepend: true) { ArCache::Model.get(self.class).update(self) }
        after_commit(on: :destroy, prepend: true) { ArCache::Model.get(self.class).delete(self) }
      end
    end
  end
end
