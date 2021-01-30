# frozen_string_literal: true

# For more information, see: https://github.com/OuYangJinTing/ar_cache/README.md
ArCache.configure do |config|
  # Default: ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'unknwon'
  # config.env = String

  # Default: Rails.cache || ActiveSupport::Cache::MemoryStore.new
  # config.cache_store = ActiveSupport::Cache::Store

  # Default: { cache_key_prefix: 'arcache', expires_in: 1.week }
  # config.default_model_options = {
  #   disabled: Boolean, # Optional, default enabled ArCache
  #   cache_key_prefix: String,
  #   expires_in: Numeric
  # }

  # config.models_options = {
  #   table_name: {
  #     disabled: Boolean, # Optional, default enabled ArCache
  #     cache_key_prefix: String,
  #     expires_in: Numeric,
  #     unique_indexes: Array # The primary key is used by default
  #   }
  # }
end
