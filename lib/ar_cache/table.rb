# frozen_string_literal: true

module ArCache
  class Table
    include Marshal

    OPTIONS = %i[disabled select_disabled unique_indexes ignored_columns].freeze

    singleton_class.attr_reader :all

    attr_reader :name, :primary_key, :unique_indexes, :column_indexes, :column_names, :md5,
                :ignored_columns, :cache_key_prefix

    delegate :connection, to: ActiveRecord::Base, private: true

    @lock = Mutex.new

    @all = []

    def self.new(table_name)
      @lock.synchronize do
        @all.find { |table| table.name == table_name } || super
      end
    end

    def initialize(table_name)
      @name = table_name
      @cache_key_prefix = "arcache:#{@name}:version"
      @primary_key = connection.primary_key(@name)
      columns = connection.columns(@name)
      options = ArCache::Configuration.get_table_options(@name)
      @unique_indexes = normalize_unique_indexes(options.delete(:unique_indexes), columns).freeze
      options.each { |k, v| instance_variable_set("@#{k}", v) }
      @disabled = true if @primary_key.nil? # ArCache is depend on primary key implementation.
      @column_names = (columns.map(&:name) - @ignored_columns).freeze
      @column_indexes = @unique_indexes.flatten.uniq.freeze
      @md5 = Digest::MD5.hexdigest("#{@disabled}-#{columns.to_json}")

      ArCache::Record.store(self)

      self.class.all << self
    end

    def disabled?
      @disabled
    end

    def enabled?
      !disabled?
    end

    def select_disabled?
      @select_disabled
    end

    def select_enabled?
      !@select_disabled
    end

    def version
      version = ArCache::Store.read(cache_key_prefix)
      unless version
        version = ArCache::Record.version(self)
        ArCache::Store.write(cache_key_prefix, version)
      end

      version
    end

    def update_version
      return -1 if disabled?

      version = ArCache::Record.update_version(self)
      ArCache::Store.write(cache_key_prefix, version)
      version
    end

    def primary_cache_key(id)
      "#{cache_key_prefix}:#{version}:#{primary_key}=#{id}"
    end

    def cache_key(where_values_hash, index, multi_values_key = nil, key_value = nil)
      where_value = index.map do |column|
        value = column == multi_values_key ? key_value : where_values_hash[column]
        value = Digest::MD5.hexdigest(value) if value.respond_to?(:size) && value.size > 64
        "#{column}=#{value}"
      end.sort.join('&')

      "#{cache_key_prefix}:#{version}:#{where_value}"
    end

    private def normalize_unique_indexes(indexes, columns)
      indexes = indexes.empty? ? query_unique_indexes(columns) : custom_unique_indexes(indexes, columns)
      (indexes - [primary_key]).sort_by(&:size).unshift([primary_key])
    end

    private def query_unique_indexes(columns) # rubocop:disable Metrics/CyclomaticComplexity
      connection.indexes(name).filter_map do |index|
        next unless index.unique

        index.columns.each do |column|
          column = columns.find { |c| c.name == column }
          next if column.null
          next if column.type == :datetime
        end

        index.columns
      rescue NoMethodError # The index.columns maybe isn't Array type
        next
      end
    end

    private def custom_unique_indexes(indexes)
      indexes.each do |index|
        index.each do |column|
          column = columns.find { |c| c.name == column }
          raise ArgumentError, "The #{name} table not found #{column.inspect} column" if column.nil?

          if column.type == :datetime
            raise ArgumentError, "The #{column.inspect} is datetime type, ArCache do't support datetime type"
          end
        end
      end
    end
  end
end
