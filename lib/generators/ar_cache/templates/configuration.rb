# frozen_string_literal: true

# For more information, please see: https://github.com/OuYangJinTing/ar_cache/README.md
ArCache.configure do |config|
  config.cache_store = defined?(Rails) ? Rails.cache : ActiveSupport::Cache::MemoryStore.new

  config.cache_lock = false # Boolean

  config.returning = false # Boolean

  config.enabled = false # Boolean

  config.select = false # Boolean

  config.expires_in = 1.week # Integer

  config.tables_config = {
    # table_name: {
    #   enabled: Boolean,
    #   select: Boolean,
    #   expires_in: Integer,
    #   unique_indexes: Array
    # },
    # ...
  }
end
