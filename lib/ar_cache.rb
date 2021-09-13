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
  LOCK = ''

  @cache_reflection = {}

  class << self
    delegate :configure, :cache_lock?, :supports_returning?, :memcached?, :redis?, :cache_store, to: ArCache::Configuration
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

    def allow_blank_index?
      Thread.current[:ar_cache_allow_blank_index]
    end

    def allow_blank_index
      return yield if allow_blank_index?

      begin
        Thread.current[:ar_cache_allow_blank_index] = true
        yield
      ensure
        Thread.current[:ar_cache_allow_blank_index] = false
      end
    end

    def cache_reflection?(reflection)
      @cache_reflection.fetch(reflection) do
        ArCache.allow_blank_index do
          yield
        end
      end
    end

    def dump_attributes(attributes)
      memcached? || redis? ? Oj.dump(attributes) : attributes
    end

    def load_attributes(attributes)
      memcached? || redis? ? Oj.load(attributes) : attributes
    end

    def lock(key)
      ArCache.write(key, LOCK, raw: true, expires_in: 1.hour)
    end
  end
end

require_relative './generators/ar_cache/templates/configuration'
