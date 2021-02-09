# frozen_string_literal: true

module ArCache
  class MockTable
    class << self
      def disabled?
        true
      end

      def enabled?
        false
      end

      def select_disabled?
        true
      end

      def select_enabled?
        false
      end

      def version
        -1
      end

      def update_version(...)
        -1
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
