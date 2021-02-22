# frozen_string_literal: true

# For more information, please see: https://github.com/OuYangJinTing/ar_cache/README.md
ArCache.configure do |config|
  # WARNING: The should uncomment only when your database default isolation level is "READ UNCOMMITTED"!
  # config.read_uncommitted = true # defaul false

  # config.cache_store = ActiveSupport::Cache::Store # default Rails.cache || ActiveSupport::Cache::MemoryStore.new

  # config.coder = [YAML|JSON] # default YAML

  # config.index_column_max_size = Integer # default 64

  # config.disabled = Boolean # default false

  # config.select_disabled = Boolean # default true

  # config.expires_in = Numeric # default 1 week

  # config.tables_options = {
  #   table_name: {
  #     disabled: Boolean,
  #     select_disabled: Boolean,
  #     unique_indexes: Array # The primary key is forced to be used
  #     ignored_columns: Array # The common ignored columns of single-table inheritance model
  #   }
  # }
end
