# frozen_string_literal: true

# For more information, please see: https://github.com/OuYangJinTing/ar_cache/README.md
ArCache.configure do |config|
  # NOTE:
  #   Arcache default use database share lock to ensure that the cache is correct.
  #   Please change true if it cause some problems.
  config.cache_lock = false # Boolean

  # The cache tool.
  config.cache_store = defined?(Rails) ? Rails.cache : ActiveSupport::Cache::MemoryStore.new # ActiveSupport::Cache::Store

  # The cache key valid time.
  config.expires_in = 1.week # Integer

  # ArCache switch.
  config.disabled = false # Boolean

  # Whether to support select column sql.
  config.select_disabled = true # Boolean

  config.tables_options = {
    # table_name: {
    #   disabled: Boolean,
    #   select_disabled: Boolean,
    #   unique_indexes: Array # eg: [:id, [:name, :statue]], The default is the unique index column of the table.
    # },
    # ...
  }
end
