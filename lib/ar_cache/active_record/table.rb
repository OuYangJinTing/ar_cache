# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Table
      module ClassMethods
        def table_name=(...)
          super.tap { @ar_cache_table = nil }
        end

        def ar_cache_table
          @ar_cache_table ||= begin
            if abstract_class? || self == ArCache::Record
              ArCache::MockTable
            else
              ArCache::Table.new(table_name)
            end
          end
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
