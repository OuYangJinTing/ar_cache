# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Querying
      delegate :skip_ar_cache, to: :all

      def find(*ids)
        defined?(@ar_cache_model) && ar_cache_model.enabled? ? all.find(*ids) : super # force skip statement cache
      end

      def find_by(*args)
        defined?(@ar_cache_model) && ar_cache_model.enabled? ? all.find_by(*args) : super # force skip statement cache
      end
    end
  end
end
