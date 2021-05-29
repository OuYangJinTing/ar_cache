# frozen_string_literal: true

module ArCache
  class MockTable
    class << self
      def disabled?
        true
      end

      def select_disabled?
        true
      end

      def cache_key_prefix
        ''
      end

      def update_cache
        ''
      end

      def primary_key
        ''
      end

      def primary_cache_key(...)
        ''
      end

      def cache_key(...)
        ''
      end

      def write(...)
        -1
      end

      def delete(...)
        -1
      end

      def read(...)
        []
      end
    end
  end
end
