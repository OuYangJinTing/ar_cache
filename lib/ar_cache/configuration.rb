# frozen_string_literal: true

module ArCache
  class Configuration
    class << self
      attr_reader :cache_store
      attr_writer :enabled, :select, :cache_lock, :returning
      attr_accessor :expires_in

      def configure
        block_given? ? yield(self) : self
      end

      def returning?
        @returning
      end

      def cache_lock?
        @cache_lock
      end

      def enabled?
        @enabled
      end

      def select?
        @select
      end

      def redis?
        @redis
      end

      def memcached?
        @memcached
      end

      def cache_store=(cache_store)
        unless cache_store.is_a?(ActiveSupport::Cache::Store)
          raise CacheStoreError, 'The cache_store must be an ActiveSupport::Cache::Store object'
        end

        @redis = cache_store.class.name == 'ActiveSupport::Cache::RedisCacheStore'
        @memcached = cache_store.class.name == 'ActiveSupport::Cache::MemCacheStore'
        @cache_store = cache_store
      end

      def tables_config=(config)
        @tables_config = config.deep_symbolize_keys
      end

      def table_config(name)
        config = @tables_config[name.to_sym] || {}
        config[:enabled] = enabled? unless config.key?(:enabled)
        config[:select] = select? unless config.key?(:select)
        config[:unique_indexes] = Array(config[:unique_indexes]).map { |index| Array(index).map(&:to_s).uniq }.uniq
        config
      end

      def lock_statement
        @lock_statement ||= case ::ActiveRecord::Base.connection.adapter_name
                            when 'PostgreSQL'
                              'FOR SHARE'
                            when 'Mysql2'
                              'LOCK IN SHARE MODE'
                            when 'SQLite'
                              raise NotSupportLock, 'The SQLite3 do not support lock statement, please use cache lock'
                            else
                              raise UnknownDatabase, 'The ArCache does not recognize your database, please use cache lock'
                            end
      end
    end
  end
end
