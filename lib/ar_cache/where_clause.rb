# frozen_string_literal: true

module ArCache
  class WhereClause
    attr_reader :klass, :table, :predicates

    def initialize(klass, predicates)
      @klass = klass
      @table = klass.ar_cache_table
      @predicates = predicates
      @missed_values = []
    end

    def cacheable?
      return @cacheable if defined?(@cacheable)

      @cacheable = predicates.any? && where_values_hash.length == predicates.length && hit_unique_index?
    end

    def hit_unique_index?
      table.unique_indexes.each do |index|
        @index = index
        @multi_values_key = nil
        count = 0

        bool = index.all? do |column|
          where_values_hash.key?(column).tap do
            if where_values_hash[column].is_a?(Array)
              @multi_values_key = column
              count += 1
            end
          end
        end

        return true if bool && count < 2
      end

      false
    end

    def single?
      @multi_values_key.nil?
    end

    def primary_key_index?
      (@multi_values_key || @index.first) == table.primary_key
    end

    def cache_hash
      return @cache_hash if defined?(@cache_hash)

      @cache_hash = {}
      multi_values_key = @multi_values_key || @index.first

      Array.wrap(where_values_hash[multi_values_key]).each do |v|
        @cache_hash[table.cache_key(where_values_hash, @index, multi_values_key, v)] = v
      end

      return @cache_hash if primary_key_index?

      @original_cache_hash = @cache_hash
      @cache_hash = ArCache::Store.read_multi(@cache_hash.keys)
      @original_cache_hash.each { |k, v| @missed_values << v unless @cache_hash.key?(k) }
      @cache_hash = @cache_hash.invert

      @cache_hash
    end

    def primary_cache_keys
      raise 'Does not detect primary key index' unless primary_key_index?

      @primary_cache_keys ||= Array(where_values_hash[table.primary_key]).map { |v| table.primary_cache_key(v) }
    end

    def missed_hash
      @missed_hash ||= @missed_values.empty? ? {} : { (@multi_values_key || @index.first) => @missed_values }
    end

    def add_missed_values(key)
      if primary_key_index?
        @missed_values << cache_hash[key]
      else
        @missed_values << @original_cache_hash[cache_hash[key]]
      end
    end

    def add_invalid_keys(key)
      @invalid_keys ||= []
      @invalid_keys << key
      @invalid_keys << cache_hash[key] unless primary_key_index?
      @invalid_keys
    end

    def delete_invalid_keys
      ArCache::Store.delete_multi(@invalid_keys) if @invalid_keys
    end

    # This module is based on ActiveRecord::Relation::WhereClause modified
    module Raw
      def where_values_hash
        @where_values_hash ||= equalities(predicates).each_with_object({}) do |node, hash|
          # Don't support Arel::Nodes::NamedFunction.
          # But we don't judge it, because it will raise exception if it is Arel::Nodes::NamedFunction object.
          next if table.name != node.left.relation.name

          name = node.left.name.to_s
          value = extract_node_value(node.right)
          next if value.respond_to?(:size) && value.size > ArCache::Configuration.column_length

          hash[name] = value
        end
      rescue NoMethodError, ActiveModel::RangeError
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
        value = case node
                when Array
                  node.map { |v| extract_node_value(v) }
                when Arel::Nodes::BindParam
                  node.value.value_for_database # Maybe raise ActiveModel::RangeError
                when Arel::Nodes::Casted, Arel::Nodes::Quoted
                  node.value_for_database # Maybe raise ActiveModel::RangeError
                end

        value.is_a?(Date) ? value.to_s : value
      end
    end
    include Raw
  end
end
