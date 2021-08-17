# frozen_string_literal: true

module ArCache
  class CacheRecord
    class << self
      attr_accessor :read, :read_multi, :write, :write_multi, :delete, :delete_multi

      def clear_log
        self.read = []
        self.read_multi = []
        self.write = []
        self.write_multi = []
        self.delete = []
        self.delete_multi = []
      end

      def any_read
        (read + read_multi).flatten
      end

      def any_write
        (write + write_multi).flatten
      end

      def any_delete
        (delete + delete_multi).flatten
      end
    end

    clear_log

    def call(name, _, _, _, values)
      case name
      when 'cache_read.active_support'
        self.class.read << values[:key]
      when 'cache_read_multi.active_support'
        self.class.read_multi << values[:key]
      when 'cache_write.active_support'
        self.class.write << values[:key]
      when 'cache_write_multi.active_support'
        self.class.write_multi << values[:key].keys
      when 'cache_delete.active_support'
        self.class.delete << values[:key]
      when 'cache_delete_multi.active_support'
        self.class.delete_multi << values[:key]
      end
    end
  end

  ActiveSupport::Notifications.subscribe(/^cache_(.)+.active_support$/, CacheRecord.new)
end
