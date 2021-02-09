# frozen_string_literal: true

module ArCache
  class Store
    @options = { raw: true, expires_in: ArCache::Configuration.expires_in }.freeze

    class << self
      def write(name, value)
        ArCache::Configuration.cache_store.write(name, dump(value), @options)
      end

      def write_multi(hash)
        hash.each { |k, v| hash[k] = dump(v) }
        ArCache::Configuration.cache_store.write_multi(hash, @options)
      end

      def read(name)
        load(ArCache::Configuration.cache_store.read(name, @options))
      end

      def read_multi(names)
        entries = ArCache::Configuration.cache_store.read_multi(*names, @options)
        entries.each { |k, v| entries[k] = load(v) }
        entries
      end

      def delete(name)
        ArCache::Configuration.cache_store.delete(name)
      end

      def delete_multi(names)
        ArCache::Configuration.cache_store.delete_multi(names)
      end

      def fetch(name, &block)
        ArCache::Configuration.cache_store.fetch(name, @options, &block)
      end

      def fetch_multi(names, &block)
        ArCache::Configuration.cache_store.fetch(*names, @options, &block)
      end

      private def dump(value)
        ArCache::Configuration.coder.dump(value)
      end

      private def load(value)
        ArCache::Configuration.coder.load(value)
      end
    end
  end
end
