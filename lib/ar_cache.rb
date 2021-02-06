# frozen_string_literal: true

require 'active_support/cache'
require 'active_record'

require 'ar_cache/version'
require 'ar_cache/monitor'
require 'ar_cache/store'
require 'ar_cache/model'
require 'ar_cache/mock_model'
require 'ar_cache/query'
require 'ar_cache/where_clause'
require 'ar_cache/log_subscriber'
require 'ar_cache/configuration'
require 'ar_cache/active_record'

require_relative './generators/ar_cache/install_generator' if defined?(Rails)

module ArCache
  singleton_class.delegate :configure, to: Configuration
end
