# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module ConnectionAdapters
      module AbstractAdapter
        module Connection
          def disable_update_ar_cache_version
            @update_ar_cache_version = false
          end

          def disabled_update_ar_cache_version?
            !@update_ar_cache_version
          end

          def enable_update_ar_cache_version
            @update_ar_cache_version = true
          end

          def enabled_update_ar_cache_version?
            @update_ar_cache_version
          end
        end

        delegate :disable_update_ar_cache_version, :disabled_update_ar_cache_version?,
                 :enable_update_ar_cache_version, :enabled_update_ar_cache_version?,
                 to: :@connection

        def initialize(connection, logger = nil, config = {})
          unless connection.respond_to?(:enable_update_ar_cache_version)
            connection.class.include(Connection)
            connection.enable_update_ar_cache_version
          end

          super
        end
      end
    end
  end
end
