# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module ModelSchema
      module ClassMethods
        def table_name=(...)
          super.tap { remove_instance_variable(:@ar_cache_table) if defined?(@ar_cache_table) }
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

      def ar_cache_table
        self.class.ar_cache_table
      end
    end
  end
end