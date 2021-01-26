# frozen_string_literal: true

require 'active_support/all'
require 'active_record'

require 'ar_cache/active_record'
require 'ar_cache/active_record/persistence'
require 'ar_cache/active_record/transactions'
require 'ar_cache/active_record/callbacks'
require 'ar_cache/active_record/relation'
require 'ar_cache/active_record/querying'
require 'ar_cache/active_record/counter_cache'
require 'ar_cache/active_record/associations/has_one_association'
require 'ar_cache/active_record/associations/has_one_through_association'
require 'ar_cache/active_record/connection_adapters/abstract_adapter'
require 'ar_cache/active_record/connection_adapters/abstract/database_statements'

require 'ar_cache/version'
require 'ar_cache/configuration'
require 'ar_cache/monitor'
require 'ar_cache/query'
require 'ar_cache/store'
require 'ar_cache/model'
require 'ar_cache/log_subscriber'

require_relative './generators/ar_cache/install_generator' if defined?(Rails)

module ArCache
  class Error < StandardError; end
  class ArgumentError < Error; end
  class StiError < Error; end
  class SqlOperationError < Error; end

  class << self
    delegate :env, :cache_store, to: Configuration
  end
end
