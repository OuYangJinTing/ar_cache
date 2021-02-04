# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Querying
      module ClassMethods
        delegate :skip_ar_cache, to: :all

        def find(*ids)
          @ar_cache_model&.enabled? ? all.find(*ids) : super # force skip statement cache
        end

        def find_by(*args)
          @ar_cache_model&.enabled? ? all.find_by(*args) : super # force skip statement cache
        end
      end

      def self.prepended(klass)
        super.tap { klass.singleton_class.prepend(ClassMethods) }
      end
    end
  end
end
