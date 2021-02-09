# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Table
      module ClassMethods
        def table_name=(...)
          super.tap { @ar_cache_table = nil }
        end

        def ar_cache_table
          @ar_cache_table ||= ArCache::Table.new(table_name) unless abstract_class?
        end
      end

      def self.prepended(klass)
        super.tap { klass.singleton_class.prepend(ClassMethods) }
      end

      def ar_cache_table
        self.class.ar_cache_table
      end
    end
  end
end
