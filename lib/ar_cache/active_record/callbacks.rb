# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Callbacks # :nodoc: all
      extend ActiveSupport::Concern

      included do
        after_commit(on: :create, prepend: true) do
          ArCache::Model.get(self.class).tap { |model| model.write(self) unless model.disabled? }
        end

        after_commit(on: :update, prepend: true) do
          ArCache::Model.get(self.class).tap { |model| model.update(self) unless model.disabled? }
        end

        after_commit(on: :destroy, prepend: true) do
          ArCache::Model.get(self.class).tap { |model| model.delete(self) unless model.disabled? }
        end
      end
    end
  end
end
