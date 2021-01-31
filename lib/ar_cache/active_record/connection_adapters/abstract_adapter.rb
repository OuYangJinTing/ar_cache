# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module ConnectionAdapters
      module AbstractAdapter # :nodoc: all
        module Connection
          def disable_update_ar_cache_version
            @update_ar_cache_version = false
          end

          def disable_update_ar_cache_version?
            !@update_ar_cache_version
          end

          def enable_update_ar_cache_version
            @update_ar_cache_version = true
          end

          def enable_update_ar_cache_version?
            @update_ar_cache_version
          end
        end

        delegate :disable_update_ar_cache_version, :disable_update_ar_cache_version?,
                 :enable_update_ar_cache_version, :enable_update_ar_cache_version?,
                 to: :@connection

        # def initialize(connection, ...) ... only support ruby 2.7+
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
