# frozen_string_literal: true

module ArCache
  class Configuration
    @cache_store      = defined?(Rails) ? Rails.cache : ActiveSupport::Cache::MemoryStore.new
    @tables_options   = {}
    @read_uncommitted = false
    @disabled         = false
    @select_disabled  = true
    @expires_in       = 1.week

    class << self
      attr_reader :cache_store, :tables_options
      attr_writer :read_uncommitted
      attr_accessor :disabled, :select_disabled, :expires_in

      def configure
        block_given? ? yield(self) : self
      end

      def read_uncommitted?
        @read_uncommitted
      end

      def redis?
        @redis
      end

      def memcached?
        @memcached
      end

      def cache_store=(cache_store)
        if !cache_store.is_a?(ActiveSupport::Cache::Store)
          raise ArgumentError, 'The cache_store must be an ActiveSupport::Cache::Store object'
        elsif 'ActiveSupport::Cache::RedisCacheStore' == cache_store.class.name
          @reids = true
        elsif 'ActiveSupport::Cache::MemCacheStore' == cache_store.class.name
          @memcached = true
        end

        @cache_store = cache_store
      end

      def tables_options=(options)
        @tables_options = options.deep_symbolize_keys
      end

      def get_table_options(name)
        options = tables_options[name.to_sym] || {}
        options[:disabled] = disabled unless options.key?(:disabled)
        options[:select_disabled] = select_disabled unless options.key?(:select_disabled)
        options[:unique_indexes] = Array(options[:unique_indexes]).map { |index| Array(index).map(&:to_s).uniq }.uniq
        options
      end
    end
  end
end
