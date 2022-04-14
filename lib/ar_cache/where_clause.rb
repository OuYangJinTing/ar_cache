# frozen_string_literal: true

module ArCache
  class WhereClause
    attr_reader :klass, :predicates

    delegate :connection, :ar_cache_table, to: :klass
    delegate :type_cast, to: :connection
    delegate :primary_key, :unique_indexes, :primary_cache_key, to: :ar_cache_table

    def initialize(klass, predicates)
      @klass = klass
      @predicates = predicates
    end

    def missing_values
      @missing_values ||= []
    end

    def invalid_cache_keys
      @invalid_cache_keys ||= []
    end

    def cacheable?(strict: true)
      return @cacheable if defined?(@cacheable)
      @cacheable = predicates.any? && where_values_hash.size == predicates.size && hit_unique_index?(strict: strict)
    end

    def hit_unique_index?(strict: true)
      unique_indexes.each do |index|
        @hit_index = index
        @array_key = nil
        multi_values_key_count = 0

        hit = index.all? do |column|
          (strict ? where_values_hash[column] : where_values_hash.key?(column)).tap do
            next unless where_values_hash[column].is_a?(Array)
            @array_key = column
            multi_values_key_count += 1
          end
        end

        return true if hit && multi_values_key_count < 2
      end

      @hit_index = nil
      @array_key = nil
      false
    end

    def single?
      raise NonCacheable unless cacheable?
      @array_key.nil?
    end

    def primary_key_index?
      raise NonCacheable unless cacheable?
      @hit_index.first == primary_key
    end

    def cache_hash
      raise NonCacheable unless cacheable?
      return @cache_hash if defined?(@cache_hash)

      @cache_hash = {}
      array_key = @array_key || @hit_index.first

      Array.wrap(where_values_hash[array_key]).each do |v|
        @cache_hash[cache_key(where_values_hash, @hit_index, v)] = v
      end

      unless primary_key_index?
        @original_cache_hash = @cache_hash
        @cache_hash = ArCache.read_multi(*@cache_hash.keys, raw: true)
        @original_cache_hash.each { |k, v| missing_values << v unless @cache_hash.key?(k) }
        @cache_hash = @cache_hash.invert
      end

      @cache_hash.delete_if do |k, v|
        next unless klass.connection.transaction_manager.ar_cache_transactions?(k)
        missing_values << (primary_key_index? ? v : @original_cache_hash[v])
      end
    end

    def primary_cache_keys
      if primary_key_index?
        @primary_cache_keys ||= Array(where_values_hash[primary_key]).map { |v| primary_cache_key(v) }
      end
    end

    def missed_hash
      @missed_hash ||= missing_values.empty? ? {} : { (@array_key || @hit_index.first) => missing_values }
    end

    def add_missing_values(key)
      if primary_key_index?
        missing_values << cache_hash[key]
      else
        missing_values << @original_cache_hash[cache_hash[key]]
      end
    end

    def add_lock_key(key)
      invalid_cache_keys << key
    end

    def add_cache_invalid_key(key)
      invalid_cache_keys << cache_hash[key] unless primary_key_index?
    end

    def delete_invalid_cache_keys
      ArCache.delete_multi(invalid_cache_keys) if invalid_cache_keys.any?
    end

    def to_h
      # Don't support Arel::Nodes::NamedFunction.
      @where_values_hash ||= equalities(predicates).each_with_object({}) do |node, hash|
        next if ar_cache_table.name != node.left.relation.name
        name = node.left.name.to_s
        value = extract_node_value(node.right)
        hash[name] = value
      end
    rescue NoMethodError, ActiveModel::RangeError
      @where_values_hash = {}
    end
    alias where_values_hash to_h

    private def equalities(predicates)
      predicates.each_with_object([]) do |node, array|
        if !node.is_a?(String) && node.equality?
          array << node
        elsif node.is_a?(Arel::Nodes::And)
          array.concat equalities(node.children)
        end
      end
    end

    # Maybe raise ActiveModel::RangeError
    private def extract_node_value(node)
      case node
      when Array
        node.map { |v| extract_node_value(v) }
      when Arel::Nodes::BindParam
        type_cast(node.value.value_for_database)
      when Arel::Nodes::Casted, Arel::Nodes::Quoted
        type_cast(node.value_for_database)
      end
    end
  end
end
