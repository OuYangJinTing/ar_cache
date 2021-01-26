# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module ConnectionAdapters
      module AbstractAdapter
        module RawConnection
          def skip_update_ar_cache_model_version
            @skip_update_ar_cache_model_version = true
          end

          def skip_update_ar_cache_model_version?
            @skip_update_ar_cache_model_version
          end

          def cancel_update_ar_cache_model_version
            @skip_update_ar_cache_model_version = false
          end
        end

        delegate :skip_update_ar_cache_model_version?,
                 :skip_update_ar_cache_model_version,
                 :cancel_update_ar_cache_model_version,
                 to: :@connection

        # def initialize(connection, ...) ... only support ruby 2.7+
        def initialize(connection, logger = nil, config = {})
          connection.class.include(RawConnection) unless connection.respond_to?(:skip_update_ar_cache_model_version)
          super
        end
      end
    end
  end
end
