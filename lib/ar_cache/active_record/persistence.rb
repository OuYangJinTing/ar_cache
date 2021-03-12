# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Persistence
      module ClassMethods
        def _update_record(_, constraints)
          ArCache.expire do
            delete_ar_cache_key(constraints[@primary_key])
            super
          end
        end

        def _delete_record(constraints)
          ArCache.expire do
            delete_ar_cache_key(constraints[@primary_key])
            super
          end
        end

        private def delete_ar_cache_key(id)
          key = ar_cache_table.primary_cache_key(id)
          connection.current_transaction.delete_ar_cache_keys([key])
          connection.current_transaction.add_changed_table(table_name)
        end
      end

      def reload(...)
        ArCache.skip { super }
      end
    end
  end
end
