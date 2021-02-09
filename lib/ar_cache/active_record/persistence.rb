# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Persistence
      module ClassMethods
        def upsert_all(...)
          super.tap { ar_cache_table.update_version }
        end
      end

      def self.prepended(klass)
        super.tap { klass.singleton_class.prepend(ClassMethods) }
      end

      def reload(options = nil)
        self.class.connection.clear_query_cache

        fresh_object =
          if options && options[:lock]
            self.class.unscoped { self.class.lock(options[:lock]).skip_ar_cache.find(id) }
          else
            self.class.unscoped { self.class.skip_ar_cache.find(id) }
          end

        @attributes = fresh_object.instance_variable_get(:@attributes)
        @new_record = false
        @previously_new_record = false
        self
      end
    end
  end
end
