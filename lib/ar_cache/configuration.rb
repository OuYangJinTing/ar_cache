# frozen_string_literal: true

require 'ar_cache/model'

module ArCache
  class Configuration
    class << self
      attr_accessor(*ArCache::Model::OPTIONS)
      attr_reader :cache_store, :models_options
    end

    def self.configure
      block_given? ? yield(self) : self
    end

    def self.get_model_options(table_name)
      options = models_options[table_name.to_sym] || {}
      options[:disabled] = !!disabled unless options.key?(:disabled)
      options[:select_disabled] = !!select_disabled unless options.key?(:select_disabled)
      options[:cache_key_prefix] = cache_key_prefix.to_s unless options.key?(:cache_key_prefix)
      options[:expires_in] = expires_in.to_i unless options.key?(:expires_in)
      options
    end

    def self.models_options=(options)
      options.each do |table_name, hash|
        raise ArgumentError, "The #{model.inspect} must be Symbol type" unless table_name.is_a?(Symbol)

        hash.assert_valid_keys(ArCache::Model::OPTIONS)
      end

      @models_options = options
    end

    def self.cache_store=(cache_store)
      unless cache_store.is_a?(ActiveSupport::Cache::Store)
        raise ArgumentError, 'The cache_store must be ActiveSupport::Cache::Store object'
      end

      @cache_store = cache_store
    end

    # The set default values
    @cache_store = defined?(Rails) ? Rails.cache : ActiveSupport::Cache::MemoryStore.new
    @models_options = {}

    @disabled = false
    @select_disabled = true
    @cache_key_prefix = ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'unknwon'
    @expires_in = 604800 # 1 week
  end
end
