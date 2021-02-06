# frozen_string_literal: true

module ArCache
  class WhereClause
    attr_reader :model, :predicates

    def initialize(model, predicates)
      @model = model
      @predicates = predicates
      @missed_values = []
    end

    def cacheable? # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      return @cacheable if defined?(@cacheable)

      if predicates.any? && where_values_hash.length == predicates.length
        model.unique_indexes.each do |index|
          @index = index
          @multi_values_key = nil
          count = 0

          bool = index.all? do |column|
            where_values_hash[column].tap do |value|
              if value.is_a?(Array)
                @multi_values_key = column
                count += 1
              end
            end
          end

          next unless bool
          return @cacheable = true if count < 2
        end
      end

      @cacheable = false
    end

    def single?
      @multi_values_key.nil?
    end

    def multi?
      @multi_values_key
    end

    def primary_key_index?
      @primary_key_index ||= (@multi_values_key || @index.first) == model.primary_key
    end

    # Please use this method if is single?
    def cache_key
      return @cache_key if defined?(@cache_key)
      return @cache_key = model.primary_cache_key(where_values_hash[model.primary_key]) if primary_key_index?

      @cache_key = model.cache_key(where_values_hash, @index)
      @original_cache_key = @cache_key
      @cache_key = cache_store.read(@cache_key)
      @cache_key
    end

    # Please use this method if is multi?
    def cache_keys_hash
      return @cache_keys_hash if defined?(@cache_keys_hash)

      @cache_keys_hash = {}

      if primary_key_index?
        where_values_hash[model.primary_key].each { |v| @cache_keys_hash[model.primary_cache_key(v)] = v }
      else
        where_values_hash[@multi_values_key].each do |v|
          @cache_keys_hash[model.cache_key(where_values_hash, @index, @multi_values_key, v)] = v
        end
        @original_cache_keys_hash = @cache_keys_hash
        @cache_keys_hash = cache_store.read_multi(*@cache_keys_hash.keys)
        @original_cache_keys_hash.each { |k, v| @missed_values << v unless @cache_keys_hash.key?(k) }
        @cache_keys_hash = @cache_keys_hash.invert
      end

      @cache_keys_hash
    end

    def missed_hash
      @missed_hash ||= @missed_values.empty? ? {} : { @multi_values_key => @missed_values }
    end

    def add_missed_values(key)
      if primary_key_index?
        @missed_values << @cache_keys_hash[key]
      else
        @missed_values << @original_cache_keys_hash[@cache_keys_hash[key]]
      end
    end

    def add_invalid_keys(key)
      @invalid_keys ||= []
      @invalid_keys << key
      @invalid_keys << (single? ? @original_cache_key : @cache_keys_hash[key]) unless primary_key_index?
      @invalid_keys
    end

    def delete_invalid_keys
      cache_store.delete_multi(@invalid_keys) if @invalid_keys
    end

    def delete_cache_keys
      return false unless cacheable?

      keys = []

      if single?
        keys << cache_key
        keys << @original_cache_key unless primary_key_index?
      else # is multi
        keys += cache_keys_hash.keys
        keys += cache_keys_hash.values unless primary_key_index?
      end

      cache_store.delete_multi(keys)

      true
    end

    private def cache_store
      ArCache::Configuration.cache_store
    end

    # This module is based on ActiveRecord::Relation::WhereClause modified
    module Raw
      def where_values_hash
        @where_values_hash ||= equalities(predicates).each_with_object({}) do |node, hash|
          next if model.table_name != node.left.relation.name

          name = node.left.name.to_s
          value = extract_node_value(node.right)
          hash[name] = value
        end
      rescue ActiveModel::RangeError
        @where_values_hash = {}
      end
      alias to_h where_values_hash

      private def equalities(predicates)
        equalities = []

        predicates.each do |node|
          if equality_node?(node)
            equalities << node
          elsif node.is_a?(Arel::Nodes::And)
            equalities.concat equalities(node.children)
          end
        end

        equalities
      end

      private def equality_node?(node)
        !node.is_a?(String) && node.equality?
      end

      private def extract_node_value(node)
        case node
        when Array
          node.map { |v| extract_node_value(v) }
        when Arel::Nodes::BindParam
          node.value.value_for_database # Maybe raise ActiveModel::RangeError
        when Arel::Nodes::Casted, Arel::Nodes::Quoted
          node.value_for_database # Maybe raise ActiveModel::RangeError
        end
      end
    end
    include Raw
  end
end
