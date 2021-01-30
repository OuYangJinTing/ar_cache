# frozen_string_literal: true

module ArCache
  class Model # :nodoc: all
    include Store

    OPTIONS = %i[disabled unique_indexes cache_key_prefix expires_in].freeze

    # Add '_TABLE' of suffix to avoid constant conflict
    def self.get(klass)
      table_name = klass.is_a?(String) ? klass : klass.table_name
      const_get("::#{name}::#{table_name.upcase}_TABLE")
    rescue ::NameError
      base_class = klass.base_class
      validation_sti!(base_class)

      model = new(base_class, ArCache::Configuration.get_model_options(klass.table_name))
      const_set("#{table_name.upcase}_TABLE", model)
    end

    # We need check ignored columns of ActiveRecord Single Table Inheritance Model,
    # because ArCache's cache is shared by between SubClass and BaseClass,
    # if SubClass need columns is in BaseClass ignored columns, read cache will be incomplete.
    def self.validation_sti!(klass)
      return if klass.ignored_columns.empty?

      subclass = klass.descendants.find { |sub| (klass.ignored_columns - sub.ignored_columns).any? }
      return unless subclass

      raise StiError, <<-MSG.strip_heredoc
        ArCache support ActiveRecord Single Table Inheritance, but BaseClass.ignored_columns must include all SubClass.ignored_columns.
        Here, (SubClass)#{subclass.name}.ignored_columns #{subclass.ignored_columns.inspect} is not in (BaseClass)#{klass.name}.ignored_columns #{klass.ignored_columns.inspect}.
        ArCache does not support this special case, but fortunately, you can handle it with the following operations:
        1. New common superclass #{klass.name}ArCache
          class #{klass.name}ArCache < #{(defined?(ApplicationRecord) ? ApplicationRecord : ::ActiveRecord::Base).name}
            self.ignored_columns = # if common ignore columns exists
          end
        2. Modify superclasses that ArCache do not support of model
          class #{klass.name} < #{klass.name}ArCache
            ...
          end
        OK, now you can use ArCache happily!
      MSG
    end

    attr_reader :klass, :version, *OPTIONS

    delegate :table_name, :primary_key, :columns, :column_names, :columns_hash, :ignored_columns, :inheritance_column,
             to: :klass

    def initialize(klass, options)
      @klass = klass

      normalize_unique_indexes(options[:unique_indexes])
      @disabled = !!options[:disabled] if options.key?(:disabled)
      @disabled = false if klass == ArCache::Monitor # ArCache::Monitor force disabled
      @expires_in = options[:expires_in].to_i if options.key?(:expires_in)
      @cache_key_prefix = options[:cache_key_prefix].to_s
      @version = ArCache::Monitor.activate(self).version

      klass.include(ArCache::ActiveRecord::Callbacks) unless disabled?
    end

    def update_version(version)
      @version = version
    end

    def disabled?
      @disabled
    end

    def cache_options
      @cache_options ||= expires_in ? { expires_in: expires_in } : nil
    end

    def index_columns
      @index_columns ||= unique_indexes.flatten.unshift(primary_key)
    end

    def whole_cache_key_prefix
      @whole_cache_key_prefix ||= begin
        short_sha = Digest::SHA1.hexdigest(columns.to_json).first(7)
        "#{ArCache::Configuration.env}:#{cache_key_prefix}:#{table_name}:#{short_sha}"
      end

      "#{@whole_cache_key_prefix}:#{version}"
    end

    def primary_cache_key(id)
      "#{whole_cache_key_prefix}:#{primary_key}=#{id}"
    end

    def cache_key(where_values_hash, index, multi_values_key = nil, key_value = nil)
      return primary_cache_key(key_value || where_values_hash[primary_key]) if index == primary_key

      digest = index.map do |column|
        value = column == multi_values_key ? key_value : where_values_hash[column]
        value = Digest::SHA1.hexdigest(value).first(7) if value.respond_to?(:size) && value.size > 40
        "#{column}=#{value}"
      end.sort.join('&') # The called #sort avoid key is inconsistent caused by order

      "#{whole_cache_key_prefix}:#{digest}"
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

    private def normalize_unique_indexes(unique_indexes) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
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
