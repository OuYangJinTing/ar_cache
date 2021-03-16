# frozen_string_literal: true

# For more information, please see: https://github.com/OuYangJinTing/ar_cache/README.md
ArCache.configure do |config|
  # WARNING: The should uncomment only when your database default isolation level is "READ UNCOMMITTED"!
  # config.read_uncommitted = true # defaul false

  # config.cache_store = ActiveSupport::Cache::Store # default Rails.cache || ActiveSupport::Cache::MemoryStore.new

  # Cache key automatic expiration time.
  # config.expires_in = Numeric # default 1 week

  # Serialize and deserialize cached data.
  # config.coder = [YAML|JSON] # default YAML

  # Support the maximum length of index column value.
  # config.column_length = Integer # default 64

  # ArCache switch.
  # config.disabled = Boolean # default false

  # Whether to support selecct columns query
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
