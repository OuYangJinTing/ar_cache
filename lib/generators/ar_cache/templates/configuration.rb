# frozen_string_literal: true

# For more information, please see: https://github.com/OuYangJinTing/ar_cache/README.md
ArCache.configure do |config|
  # The cache tool. It must be an instance of ActiveSupport::Cache::Store.
  config.cache_store = defined?(Rails) ? Rails.cache : ActiveSupport::Cache::MemoryStore.new

  # NOTE: Please enable cache lock if it casue database some errors.
  # ArCache default use database share lock to ensure that the cache is correct.
  # You must need check database share lock syntax.
  # For MySQL, it is 'LOCK IN SHARE MODE' if your mysql's version less than 8.
  # If database don't support lock (eg: SQLite3), please use cache lock.
  #
  # For more detail, please see official documentation.
  # MySQL: dev.mysql.com/doc/refman/en/innodb-locking-reads.html
  # PostgreSQL: www.postgresql.org/docs/current/interactive/sql-select.html#SQL-FOR-UPDATE-SHARE
  config.lock_statement = 'FOR SHARE' # or 'LOCK IN SHARE MODE'

  # If the cache store is not Redis nor Memcached, the cache lock is unreliable.
  config.cache_lock = false # Boolean

  # The cache key valid time.
  config.expires_in = 1.week # Integer

  # ArCache switch (default).
  config.disabled = false # Boolean

  # Whether to support select column sql (default)..
  config.select_disabled = true # Boolean

  # table_name: Database's table name.
  # disabled: ArCache switch.
  # select_disabled: Whether to support select column sql.
  # unique_indexes: Table's unique index (Arcache will query the unique index from database if not defined).
  # WARNING: If you use database lock, you should not custom unique index, otherwise may be happen lock table.
  config.tables_options = {
    # table_name: {
    #   disabled: Boolean,
    #   select_disabled: Boolean,
    #   unique_indexes: Array # eg: [:id, [:name, :statue]], The default is the unique index column of the table.
    # },
    # ...
  }
end
