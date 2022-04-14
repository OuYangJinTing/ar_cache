# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module ModelSchema
      module ClassMethods
        def ar_cache_table
          ::ArCache::Table[table_name]
        end
      end

      def ar_cache_table
        self.class.ar_cache_table
      end
    end
  end
end
