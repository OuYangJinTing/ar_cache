# frozen_string_literal: true

module ArCache
  class Configuration
    class << self
      attr_accessor :disabled, :select_disabled, :cache_key_prefix, :expires_in
      attr_reader :cache_store, :models_options

      def configure
        block_given? ? yield(self) : self
      end

      def get_model_options(table_name)
        options = models_options[table_name.to_sym] || {}
        options[:disabled] = !!disabled unless options.key?(:disabled)
        options[:cache_key_prefix] = cache_key_prefix.to_s unless options.key?(:cache_key_prefix)
        options[:expires_in] = expires_in.to_i unless options.key?(:expires_in)
        options[:expires_in] = !!select_disabled unless options.key?(:expires_in)

        options
      end

      def models_options=(options)
        options.each do |table_name, hash|
          raise ArgumentError, "The #{model.inspect} must be Symbol type" unless table_name.is_a?(Symbol)

          hash.assert_valid_keys(ArCache::Model::OPTIONS)
        end

        @models_options = options
      end

      def cache_store=(cache_store)
        unless cache_store.is_a?(ActiveSupport::Cache::Store)
          raise ArgumentError, 'The cache_store must be ActiveSupport::Cache::Store object'
        end

        @cache_store = cache_store

        # This method is based on ActiveSupport::Cache::Store#fetch_multi modified
        # The execution result of the block will not be written to the cache and collection when the cache is not found
        @cache_store.define_singleton_method(:ar_cache_fetch_multi) do |*names, &block|
          options = names.extract_options!
          options = merged_options(options)

          instrument :read_multi, names, options do |payload|
            reads = read_multi_entries(names, **options)

            names.each { |name| block.call(name) unless reads.key?(name) }

            payload[:hits] = reads.keys
            payload[:super_operation] = :ar_cache_fetch_multi # :fetch_multi

            reads
          end
        end
      end
    end

    # Initialize the default values
    @disabled = false
    @select_disabled = true
    @cache_key_prefix = ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'unknwon'
    @expires_in = 1.week
    @models_options = {}
    self.cache_store = if defined?(Rails) && Rails.cache.is_a?(ActiveSupport::Cache::Store)
                         Rails.cache
                       else
                         ActiveSupport::Cache::MemoryStore.new
                       end
  end
end
