# frozen_string_literal: true

require 'active_support/cache'
require 'active_record'

require 'ar_cache/version'
require 'ar_cache/configuration'
require 'ar_cache/record'
require 'ar_cache/store'
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
    delegate :configure, to: Configuration

    def skip?
      Thread.current[:ar_cache_skip]
    end

    def skip
      return yield if skip?

      begin
        Thread.current[:ar_cache_skip] = true
        yield
      ensure
        Thread.current[:ar_cache_skip] = false
      end
    end

    def expire?
      Thread.current[:ar_cache_expire]
    end

    def expire
      return yield if expire?

      begin
        Thread.current[:ar_cache_expire] = true
        yield
      ensure
        Thread.current[:ar_cache_expire] = false
      end
    end

    def cache_reflection?(reflection)
      @cache_reflection.fetch(reflection) { @cache_reflection[reflection] = yield }
    end
  end
end
