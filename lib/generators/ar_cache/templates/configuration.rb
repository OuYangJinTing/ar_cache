# frozen_string_literal: true

# For more information, please see: https://github.com/OuYangJinTing/ar_cache/README.md
ArCache.configure do |config|
  # The cache tool. It must be an instance of ActiveSupport::Cache::Store.
  config.cache_store = defined?(Rails) ? Rails.cache : ActiveSupport::Cache::MemoryStore.new

  # NOTE: ArCache default use database share lock('FOR SHARE' or 'LOCK IN SHARE MODE') to ensure that
  # the cache is correct. If your database don't support lock (eg: SQLite3), please use cache lock.
  #
  # WARNING: If the cache store is not Redis and Memcached and Memory, the cache lock may be unreliable.
  config.cache_lock = false # Boolean

  # The cache key valid time.
  config.expires_in = 1.week # Integer

  # ArCache switch (default).
  config.disabled = false # Boolean

  # Whether to support select column sql (default)..
  config.select_disabled = true # Boolean

  # WARNING: If you use database lock, you should not custom unique index, otherwise may be happen lock table.
  config.tables_options = {
    # table_name: { # Database's table name.
    #   disabled: Boolean, # sArCache switch.
    #   select_disabled: Boolean, # Whether to support select column sql.
    #   unique_indexes: Array # eg: [:id, [:name, :statue]], The default is the unique index column of the table.
    # },
    # ...
  }
end
