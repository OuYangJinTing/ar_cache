# frozen_string_literal: true

require 'active_support/cache'
require 'active_record'
require 'oj'

require 'ar_cache/version'
require 'ar_cache/configuration'
require 'ar_cache/marshal'
require 'ar_cache/table'
require 'ar_cache/mock_table'
require 'ar_cache/query'
require 'ar_cache/where_clause'
require 'ar_cache/log_subscriber'
require 'ar_cache/active_record'

require_relative './generators/ar_cache/install_generator' if defined?(Rails)

module ArCache
  @cache_reflection = {}

  class << self
    delegate :configure, :memcached?, :redis?, to: ArCache::Configuration
    delegate *ActiveSupport::Cache::Store.instance_methods(false), to: 'ArCache::Configuration.cache_store'

    def skip_cache?
      Thread.current[:ar_cache_skip_cache]
    end

    def skip_cache
      return yield if skip_cache?

      begin
        Thread.current[:ar_cache_skip_cache] = true
        yield
      ensure
        Thread.current[:ar_cache_skip_cache] = false
      end
    end

    def skip_expire?
      Thread.current[:ar_cache_skip_expire]
    end

    def skip_expire
      return yield if skip_expire?

      begin
        Thread.current[:ar_cache_skip_expire] = true
        yield
      ensure
        Thread.current[:ar_cache_skip_expire] = false
      end
    end

    def cache_reflection?(reflection)
      @cache_reflection.fetch(reflection) { @cache_reflection[reflection] = yield }
    end

    def dump(value)
      value && (memcached? || redis?) ? Oj.dump(value) : value
    end

    def load(value)
      value && (memcached? || redis?) ? Oj.load(value) : value
    end
  end
end
