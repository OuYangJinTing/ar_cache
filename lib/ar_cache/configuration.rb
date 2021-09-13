# frozen_string_literal: true

module ArCache
  class Configuration
    class << self
      attr_reader :cache_store, :tables_options
      attr_accessor :disabled, :select_disabled, :expires_in, :cache_lock, :supports_returning

      def configure
        block_given? ? yield(self) : self
      end

      def supports_returning?
        @supports_returning
      end

      def cache_lock?
        @cache_lock
      end

      def redis?
        @redis
      end

      def memcached?
        @memcached
      end

      def cache_store=(cache_store)
        if !cache_store.is_a?(ActiveSupport::Cache::Store) # rubocop:disable Style/GuardClause
          raise ArgumentError, 'The cache_store must be an ActiveSupport::Cache::Store object'
        elsif cache_store.class.name == 'ActiveSupport::Cache::RedisCacheStore' # rubocop:disable Style/ClassEqualityComparison
          @redis = true
        elsif cache_store.class.name == 'ActiveSupport::Cache::MemCacheStore' # rubocop:disable Style/ClassEqualityComparison
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

      def lock_statement
        @lock_statement ||= case ::ActiveRecord::Base.connection.class.name
                            when 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'
                              'FOR SHARE'
                            when 'ActiveRecord::ConnectionAdapters::Mysql2Adapter'
                              'LOCK IN SHARE MODE'
                            when 'ActiveRecord::ConnectionAdapters::SQLite3Adapter'
                              raise 'SQLite3 do not support lock statement, please use cache lock.'
                            else
                              raise 'ArCache can not identify database, please use cache lock.'
                            end
      end
    end
  end
end
