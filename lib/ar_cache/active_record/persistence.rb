# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Persistence
      module ClassMethods
        def _update_record(_, constraints)
          ArCache.skip_expire do
            super
            delete_ar_cache_key(constraints[@primary_key])
          end
        end

        def _delete_record(constraints)
          ArCache.skip_expire do
            super
            delete_ar_cache_key(constraints[@primary_key])
          end
        end

        private def delete_ar_cache_key(id)
          key = ar_cache_table.primary_cache_key(id)
          connection.current_transaction.delete_ar_cache_primary_keys([key], ar_cache_table)
        end
      end

      def reload(...)
        ArCache.skip_cache { super }
      end
    end
  end
end
