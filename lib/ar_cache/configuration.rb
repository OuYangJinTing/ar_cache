# frozen_string_literal: true

require 'yaml'

module ArCache
  class Configuration
    singleton_class.attr_accessor :disabled, :select_disabled, :expires_in, :read_uncommitted, :column_length
    singleton_class.attr_reader :cache_store, :tables_options, :coder

    def self.configure
      block_given? ? yield(self) : self
    end

    def self.cache_store=(cache_store)
      unless cache_store.is_a?(ActiveSupport::Cache::Store)
        raise ArgumentError, 'The cache_store must be an ActiveSupport::Cache::Store object'
      end

      @cache_store = cache_store
    end

    def self.tables_options=(options)
      options.each do |name, hash|
        raise ArgumentError, "The #{name.inspect} must be converted to Symbol type" unless name.is_a?(Symbol)

        hash.each_key do |k|
          raise ArgumentError, "The #{k.inspect} must be converted to Symbol type" unless k.is_a?(Symbol)
        end
      end

      @tables_options = options
    end

    def self.coder=(coder)
      raise ArgumentError, 'The coder only support use YAML or JSON' unless [::YAML, ::JSON].include?(coder)

      @coder = coder
    end

    def self.get_table_options(name)
      options = tables_options[name.to_sym] || {}
      options[:disabled] = disabled unless options.key?(:disabled)
      options[:select_disabled] = select_disabled unless options.key?(:select_disabled)
      options[:unique_indexes] = Array(options[:unique_indexes]).map { |index| Array(index).map(&:to_s).uniq }.uniq
      options
    end

    # The set default values
    @cache_store = defined?(Rails) ? Rails.cache : ActiveSupport::Cache::MemoryStore.new
    @tables_options = {}
    @coder = ::YAML
    @disabled = false
    @select_disabled = true
    @expires_in = 604_800 # 1 week
    @read_uncommitted = false
    @column_length = 64
  end
end
