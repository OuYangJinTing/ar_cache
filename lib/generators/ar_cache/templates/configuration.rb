# frozen_string_literal: true

# For more information, please see: https://github.com/OuYangJinTing/ar_cache/README.md
ArCache.configure do |config|
  # WARNING: The must uncomment only when your database default isolation level is "READ UNCOMMITTED"!
  # config.read_uncommitted = true # defaul false

  # The cache tool.
  # config.cache_store = ActiveSupport::Cache::Store # default Rails.cache || ActiveSupport::Cache::MemoryStore.new

  # Cache key automatic expiration time.
  # config.expires_in = Numeric # default 1 week

  # Serialize and deserialize cached data.
  # This setting only takes effect when using redis or memcached cache.
  # config.coder = [YAML|JSON] # default YAML

  # ArCache switch.
  # config.disabled = Boolean # default false

  # Whether to support selecct columns query use cache.
  # config.select_disabled = Boolean # default true

  # config.tables_options = {
  #   table_name: {
  #     disabled: Boolean,
  #     select_disabled: Boolean,
  #     unique_indexes: Array # eg: [:id, [:name, :statue]], The default is the unique index column of the table.
  #   },
  #   ...
  # }
end
