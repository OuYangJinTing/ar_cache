# frozen_string_literal: true

# For more information, see: https://github.com/OuYangJinTing/ar_cache/README.md
ArCache.configure do |config|
  # Default: Rails.cache || ActiveSupport::Cache::MemoryStore.new
  # config.cache_store = ActiveSupport::Cache::Store

  # Default: false
  # config.disabled = Boolean

  # Default: true
  # config.select_disabled = Boolean

  # Default: 1.week
  # config.expires_in = Numeric

  # config.tables_options = {
  #   table_name: {
  #     disabled: Boolean,
  #     select_disabled: Boolean,
  #     expires_in: Numeric,
  #     unique_indexes: Array # The primary key is used by default
  #   }
  # }
end
