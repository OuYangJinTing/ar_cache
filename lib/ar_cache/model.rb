# frozen_string_literal: true

module ArCache
  class Model
    include Store

    OPTIONS = %i[disabled select_disabled cache_key_prefix expires_in unique_indexes].freeze

    attr_reader :klass, *OPTIONS

    delegate :table_name, :primary_key, :columns, :column_names, :columns_hash, :ignored_columns, :inheritance_column,
             to: :klass

    def initialize(klass)
      @klass = klass.base_class

      options = ArCache.get_model_options(table_name)
      (OPTIONS - [:unique_indexes]).each { |ivar| instance_variable_set("@#{ivar}", options[ivar]) }
      @disabled = false if @klass == ArCache::Monitor # The ArCache::Monitor force disabled ArCache feature
      normalize_unique_indexes(options[:unique_indexes])

      monitor = ArCache::Monitor.enable(self)
      update_version(monitor.version)
    end

    def disabled?
      @disabled
    end

    def enabled?
      !@disabled
    end

    def select_disabled?
      @select_disabled
    end

    def select_enabled?
      !@select_disabled
    end

    def version
      cache_store.fetch(version_cache_key, expires_in: 1.year) { ArCache::Monitor.version(table_name) }
    end

    def update_version(version = nil)
      return if disabled?
      version ||= ArCache::Monitor.update_version(table_name)
      cache_store.write(version_cache_key, version, expires_in: 1.year)
    end

    def whole_cache_key_prefix
      @whole_cache_key_prefix ||= begin
        short_sha = Digest::SHA1.hexdigest(columns.to_json).first(7)
        "#{cache_key_prefix}:arcache:#{table_name}:#{short_sha}"
      end
    end

    def version_cache_key
      "#{whole_cache_key_prefix}:version"
    end

    def primary_cache_key(id)
      "#{whole_cache_key_prefix}:#{version}:#{primary_key}=#{id}"
    end

    def cache_key(where_values_hash, index, multi_values_key = nil, key_value = nil)
      return primary_cache_key(key_value || where_values_hash[primary_key]) if index == primary_key

      digest = index.map do |column|
        value = column == multi_values_key ? key_value : where_values_hash[column]
        value = Digest::SHA1.hexdigest(value).first(7) if value.respond_to?(:size) && value.size > 40
        "#{column}=#{value}"
      end.sort.join('&') # The called #sort avoid key is inconsistent caused by order

      "#{whole_cache_key_prefix}:#{version}:#{digest}"
    end

    def index_columns
      @index_columns ||= unique_indexes.flatten.unshift(primary_key)
    end

    def attributes_for_database(record, columns, previous: false)
      return columns.index_with { |column| record.send(:attribute_for_database, column) } unless previous

      changes = record.previous_changes
      columns.index_with do |column|
        if changes.key?(column)
          record.instance_variable_get(:@attributes).send(:attributes)[column].type.serialize(values.first)
        else
          record.send(:attribute_for_database, column)
        end
      end
    end

    def instantiate(attributes, &block)
      return klass.instantiate(attributes, &block) if attributes.key?(inheritance_column)

      klass.send(:instantiate_instance_of, klass, attributes, &block)
    end

    private def normalize_unique_indexes(unique_indexes)
      @unique_indexes = if unique_indexes
                          Array.wrap(unique_indexes).map do |index|
                            Array.wrap(index).map do |column|
                              column = column.to_s.tap do |name|
                                unless column_names.include?(name)
                                  raise ArgumentError, "The #{column.inspect} is not in #{klass.name}.column_names"
                                end
                              end
                            end.uniq
                          end.uniq
                        else
                          ::ActiveRecord::Base.connection.indexes(table_name).map do |index|
                            next unless index.unique
                            next if index.columns.any? { |column| columns_hash[column].null }

                            index.columns
                          end.compact
                        end

      @unique_indexes = (@unique_indexes - [primary_key]).sort_by(&:size).freeze
    end
  end
end
