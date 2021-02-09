# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Querying
      module ClassMethods
        delegate :skip_ar_cache, to: :all

        # The #find use statement cache execute querying first, so need force skip.
        def find(...)
          @ar_cache_table&.enabled? ? all.find(...) : super
        end

        # The #find_by use statement cache execute querying first, so need force skip.
        def find_by(...)
          @ar_cache_table&.enabled? ? all.find_by(...) : super
        end

        def find_by_sql(sql, binds = [], preparable: nil, &block)
          result_set = connection.select_all(sanitize_sql(sql), "#{name} Load", binds, preparable: preparable)
          column_types = result_set.column_types
          column_types = column_types.reject { |k, _| attribute_types.key?(k) } unless column_types.empty?

          message_bus = ActiveSupport::Notifications.instrumenter

          payload = {
            record_count: result_set.length,
            class_name: name
          }

          message_bus.instrument("instantiation.active_record", payload) do
            if result_set.includes_column?(inheritance_column)
              result_set.map { |record| instantiate(record, column_types, &block) }
            else
              # Instantiate a homogeneous set
              result_set.map { |record| instantiate_instance_of(self, record, column_types, &block) }
            end
          end.tap { ar_cache_table.write(result_set.send(:hash_rows)) if result_set.any? }
        end
      end

      def self.prepended(klass)
        super.tap { klass.singleton_class.prepend(ClassMethods) }
      end
    end
  end
end
