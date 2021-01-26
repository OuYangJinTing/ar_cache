# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Persistence
      # def reload(...) ... only support ruby 2.7+
      def reload(options = nil)
        ArCache::Model.get(self.class).delete(self)
        super
      end
    end
  end
end
