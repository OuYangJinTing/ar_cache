# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Table
      module ClassMethods
        def table_name=(...)
          super.tap { remove_instance_variable(:@ar_cache_table) if defined?(@ar_cache_table) }
        end

        def ar_cache_table
          return @ar_cache_table if defined?(@ar_cache_table)

          @ar_cache_table = begin
            abstract_class? ? ArCache::MockTable : ArCache::Table.new(table_name)
          rescue ::ActiveRecord::StatementInvalid # The table may not exist
            ArCache::MockTable
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
