# frozen_string_literal: true

# For more information, please see: https://github.com/OuYangJinTing/ar_cache/README.md
ArCache.configure do |config|
  # Default: false
  # config.disabled = Boolean

  # Default: true
  # config.select_disabled = Boolean

  # Default: 1.week
  # config.expires_in = Numeric

  # Default: Rails.cache || ActiveSupport::Cache::MemoryStore.new
  # config.cache_store = ActiveSupport::Cache::Store

  # Default: YAML
  # config.coder = [YAML|JSON]

  # config.tables_options = {
  #   table_name: {
  #     disabled: Boolean,
  #     select_disabled: Boolean,
  #     unique_indexes: Array # The primary key is used by default
  #     ignored_columns: Array # The common ignored columns of single-table inheritance model
  #   }
  # }
end
