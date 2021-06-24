# frozen_string_literal: true

module ArCache
  class Table
    include Marshal

    singleton_class.attr_reader :all

    @lock = Mutex.new
    @all = []

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

    attr_reader :name, :primary_key, :unique_indexes, :column_indexes, :column_names, :identity_cache_key, :short_sha1

    def initialize(table_name)
      @name = table_name
      @primary_key = ::ActiveRecord::Base.connection.primary_key(@name)

      options = ArCache::Configuration.get_table_options(@name)
      @disabled = @primary_key.nil? ? true : options[:disabled] # ArCache can't work if primary key does not exist.
      @select_disabled = options[:select_disabled]

      columns = ::ActiveRecord::Base.connection.columns(@name)
      @unique_indexes = normalize_unique_indexes(options[:unique_indexes], columns).freeze
      @column_indexes = @unique_indexes.flatten.uniq.freeze
      @column_names = columns.map(&:name).freeze

      @identity_cache_key = "ar:cache:#{@name}"
      @short_sha1 = Digest::SHA1.hexdigest("#{@disabled}:#{columns.to_json}").first(7)

      # For avoid to skip Arcache read cache, must delete cache when disable Arcache.
      # For keep table's schema is consistent, must delete cache after modified the table.
      ArCache.delete(@identity_cache_key) if disabled? || !cache_key_prefix.start_with?("#{@identity_cache_key}:#{@short_sha1}") # rubocop:disable Layout/LineLength
    end

    def disabled?
      @disabled
    end

    def select_disabled?
      @select_disabled
    end

    def cache_key_prefix
      return '' if disabled?

      ArCache.read(identity_cache_key, raw: true) || update_cache
    end

    # In order to avoid cache avalanche, we must set cache_key_prefix never expired.
    def update_cache
      return '' if disabled?

      key = "#{identity_cache_key}:#{short_sha1}:#{Time.now.to_f}"
      ArCache.write(identity_cache_key, key, raw: true, expires_in: 20.years)
      key
    end

    def primary_cache_key(id)
      "#{cache_key_prefix}:#{primary_key}=#{id}"
    end

    def cache_key(where_values_hash, index, multi_values_key = nil, key_value = nil)
      where_value = index.map do |column|
        value = column == multi_values_key ? key_value : where_values_hash[column]
        "#{column}=#{value}"
      end.sort.join('&')

      "#{cache_key_prefix}:#{where_value}"
    end

    private def normalize_unique_indexes(indexes, columns)
      indexes = indexes.empty? ? query_unique_indexes(columns) : validate_unique_indexes(indexes, columns)
      (indexes - [primary_key]).sort_by(&:size).unshift([primary_key])
    end

    private def query_unique_indexes(columns)
      ::ActiveRecord::Base.connection.indexes(name).filter_map do |index|
        next unless index.unique
        next unless index.columns.is_a?(Array)

        index.columns.each do |column|
          next if columns.none? { |c| c.name == column }
        end

        index.columns
      end
    end

    private def validate_unique_indexes(indexes, columns)
      indexes.each do |attrs|
        attrs.each do |attr|
          column = columns.find { |c| c.name == attr }
          raise ArgumentError, "The #{name} table not found #{attr} column" if column.nil?
        end
      end
    end
  end
end
