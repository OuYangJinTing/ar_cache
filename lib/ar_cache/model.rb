# frozen_string_literal: true

module ArCache
  class Model # :nodoc: all
    include Store

    OPTIONS = %i[disabled unique_indexes cache_key_prefix expires_in].freeze

    # Add '_MODEL' of suffix to avoid constant conflict
    def self.get(klass)
      table_name = klass.is_a?(String) ? klass : klass.table_name
      const_get("::#{name}::#{table_name.upcase}_MODEL")
    rescue ::NameError
      base_class = klass.base_class
      validation_sti!(base_class)
      const_set("#{table_name.upcase}_MODEL", new(base_class))
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

    def initialize(klass)
      @klass = klass

      options = ArCache::Configuration.models_options[klass.table_name.to_sym] || {}
      options = ArCache::Configuration.default_model_options.merge(options)
      configure_options(options)
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
      @index_columns ||= unique_indexes.unshift(klass.primary_key).flatten
    end

    def whole_cache_key_prefix
      @whole_cache_key_prefix ||= begin
        short_sha = Digest::SHA1.hexdigest(klass.columns.to_json).first(7)
        "#{ArCache::Configuration.env}:#{cache_key_prefix}:#{klass.table_name}:#{short_sha}"
      end

      "#{@whole_cache_key_prefix}:#{version}"
    end

    def primary_cache_key(id)
      "#{whole_cache_key_prefix}:#{klass.primary_key}=#{id}"
    end

    def cache_key(where_values_hash, index, multi_values_key = nil, key_value = nil)
      return primary_cache_key(key_value || where_values_hash[klass.primary_key]) if index == klass.primary_key

      digest = index.map do |column|
        value = column == multi_values_key ? key_value : where_values_hash[column]
        value = Digest::SHA1.hexdigest(value).first(7) if value.respond_to?(:size) && value.size > 40
        "#{column}=#{value}"
      end.sort.join('&') # The called #sort avoid key is inconsistent caused by order

      "#{whole_cache_key_prefix}:#{digest}"
    end

    def attributes_for_database(record, columns, previous: false)
      if previous
        changes = record.previous_changes
        columns.each_with_object({}) do |column, attributes|
          attributes[column] = if changes.key?(column)
                                 record.instance_variable_get(:@attributes)
                                       .send(:attributes)[column].type.serialize(values.first)
                               else
                                 record.send(:attribute_for_database, column)
                               end
        end
      else
        columns.each_with_object({}) do |column, attributes|
          attributes[column] = record.send(:attribute_for_database, column)
        end
      end
    end

    def instantiate(attributes, &block)
      return klass.instantiate(attributes, &block) if attributes.key?(klass.inheritance_column)

      klass.send(:instantiate_instance_of, klass, attributes, &block)
    end

    private def configure_options(options)
      configure_unique_indexes(options[:unique_indexes])

      @disabled = !!options[:disabled] if options.key?(:disabled)
      @expires_in = options[:expires_in].to_i if options.key?(:expires_in)
      @cache_key_prefix = options[:cache_key_prefix].to_s

      ArCache::Monitor.activate(self)
    end

    private def configure_unique_indexes(unique_indexes) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      @unique_indexes = if unique_indexes
                          Array.wrap(unique_indexes).map do |index|
                            Array.wrap(index).map do |column|
                              column = column.to_s.tap do |name|
                                unless klass.column_names.include?(name)
                                  raise ArgumentError, "The #{column.inspect} is not in #{klass.name}.column_names"
                                end
                              end
                            end.uniq
                          end.uniq
                        else
                          ::ActiveRecord::Base.connection.indexes(klass.table_name).map do |index|
                            next unless index.unique
                            next if index.columns.any? { |column| klass.columns_hash[column].null }

                            index.columns
                          end.compact
                        end

      @unique_indexes = (@unique_indexes - [klass.primary_key]).sort_by(&:size).freeze
    end
  end
end
