# frozen_string_literal: true

module ArCache
  class Table
    include Marshal

    singleton_class.attr_reader :all, :tables

    @lock = Mutex.new
    @all = []
    @tables = {}

    def self.[](table_name)
      table_name.downcase!
      @tables.fetch(table_name) { @tables[table_name] = new(table_name) }
    end

    def self.new(table_name)
      @lock.synchronize do
        table = @all.find { |t| t.name == table_name }

        unless table
          table = super
          @all << table
        end

        table
      end
    end

    attr_reader :name, :primary_key, :unique_indexes, :index_column_names, :column_names, :identity_cache_key, :short_sha1

    def initialize(table_name)
      @name = table_name.downcase
      config = ArCache.table_config(@name)

      primary_keys = ::ActiveRecord::Base.connection.primary_keys(@name)
      validate_primary_keys(primary_keys)
      @primary_key = primary_keys.first
      @enabled = config[:enabled]
      @select = config[:select]
      @unique_indexes = normalize_unique_indexes(config[:unique_indexes]).freeze
      @index_column_names = @unique_indexes.flatten.uniq.freeze
      @column_names = columns.map(&:name).freeze
      @identity_cache_key = "ArCache:#{@name}"
      @short_sha1 = Digest::SHA1.hexdigest("#{@enabled}:#{columns.to_json}").first(7)

      update_cache unless cache_key_prefix.start_with?("#{@identity_cache_key}:#{@short_sha1}")
    end

    def columns
      ::ActiveRecord::Base.connection.schema_cache.columns(name)
    end

    def enabled?
      @enabled
    end

    def disabled?
      !@enabled
    end

    def select?
      @select
    end

    def cache_key_prefix
      return '' if disabled?

      ArCache.read(identity_cache_key, raw: true) || update_cache
    end

    def update_cache
      return '' if disabled?

      key = "#{identity_cache_key}:#{short_sha1}:#{Process.clock_gettime(Process::CLOCK_REALTIME, :millisecond)}"
      ArCache.write(identity_cache_key, key, raw: true, expires_in: 20.years)
      key
    end

    def primary_cache_key(id)
      "#{cache_key_prefix}:#{primary_key}=#{id}"
    end

    def cache_key(where_values_hash, index, array_key_value = nil)
      where_value = index.map do |column|
        value = where_values_hash[column]
        value = array_key_value if value.is_a?(Array)
        "#{column}=#{value}"
      end.sort.join('&')

      "#{cache_key_prefix}:#{where_value}"
    end

    private def normalize_unique_indexes(indexes)
      indexes = indexes.empty? ? query_unique_indexes : validate_unique_indexes(indexes)
      (indexes - [primary_key]).sort_by(&:size).unshift([primary_key])
    end

    private def query_unique_indexes
      ::ActiveRecord::Base.connection.schema_cache.indexes(name).filter_map do |index|
        next unless index.unique
        next unless index.columns.is_a?(Array)
        next unless index.columns.all? do |column|
          columns.find { |c| c.name == column }
        end

        index.columns
      end
    end

    private def validate_unique_indexes(indexes)
      indexes.each do |attrs|
        attrs.each do |attr|
          column = columns.find { |c| c.name == attr }
          next if column
          raise IndexError, "The #{name} table cannot find the #{attr} column, you may have set the wrong index"
        end
      end
    end

    private def validate_primary_keys(primary_keys)
      if !primary_keys.one?
        raise CompositePrimaryKey, "The ArCache does not support composite primary key. Please remove #{name} from tables_config"
      elsif primary_keys.blank?
        raise MissingPrimaryKey, "The #{name} table missing a primary key. Please remove #{name} from tables_config"
      end
    end
  end
end
