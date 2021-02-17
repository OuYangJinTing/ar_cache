# frozen_string_literal: true

module ArCache
  class Store
    @options = { raw: true, expires_in: ArCache::Configuration.expires_in }.freeze

    class << self
      delegate :delete, :delete_multi, :clear, :exist?, to: 'ArCache::Configuration.cache_store'

      def write(name, value)
        ArCache::Configuration.cache_store.write(name, dump(value), @options)
      end

      def write_multi(hash)
        hash.each { |k, v| hash[k] = dump(v) }
        ArCache::Configuration.cache_store.write_multi(hash, @options)
      end

      def read(name)
        value = ArCache::Configuration.cache_store.read(name, @options)
        value ? load(value) : value
      end

      def read_multi(names)
        entries = ArCache::Configuration.cache_store.read_multi(*names, @options)
        entries.each { |k, v| entries[k] = load(v) }
        entries
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
