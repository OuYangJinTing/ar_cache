# frozen_string_literal: true

require 'active_support/cache'
require 'active_record'
require 'oj'

require 'ar_cache/version'
require 'ar_cache/errors'
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
  LOCK = ''

  @cache_reflections = {}

  class << self
    delegate :configure, :lock_statement, :cache_store, :table_config, :expires_in, :cache_lock?, :returning?, :memcached?, :redis?, to: ArCache::Configuration
    delegate :read, :read_multi, :write, :write_multi, :delete, :delete_multi, :exist?, :clear, to: :cache_store

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

    def cache_reflection?(reflection)
      @cache_reflections.fetch(reflection) { @cache_reflections[reflection] = yield }
    end

    def dump(attributes)
      memcached? || redis? ? Oj.dump(attributes) : attributes
    end

    def load(attributes)
      memcached? || redis? ? Oj.load(attributes) : attributes
    end

    def lock(key)
      ArCache.write(key, LOCK, raw: true, expires_in: 1.hour)
    end
  end
end

require_relative './generators/ar_cache/templates/configuration'
