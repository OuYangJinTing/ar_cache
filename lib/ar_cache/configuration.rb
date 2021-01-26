# frozen_string_literal: true

# env set
module ArCache
  class Configuration # :nodoc: all
    class << self
      attr_reader :cache_store
      attr_writer :env

      def configure
        block_given? ? yield(self) : self
      end

      def env
        @env || ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'unknwon'
      end

      def models_options
        @models_options || {}
      end

      def models_options=(options)
        options.each do |model, hash|
          raise ArgumentError, "The #{model.inspect} must be Symbol type" unless model.is_a?(Symbol)

          hash.assert_valid_keys(ArCache::Model::OPTIONS)
        end

        @models_options = options.freeze
      end

      def default_model_options
        @default_model_options || { cache_key_prefix: 'arcache', expires_in: 1.week }
      end

      def default_model_options=(options)
        options.assert_valid_keys(ArCache::Model::OPTIONS)
        @default_model_options = options.freeze
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

    self.cache_store = if defined?(Rails) && Rails.cache.is_a?(ActiveSupport::Cache::Store)
                         Rails.cache
                       else
                         ActiveSupport::Cache::MemoryStore.new
                       end
  end
end
