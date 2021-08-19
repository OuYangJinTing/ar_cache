# frozen_string_literal: true

module ArCache
  class WhereClause
    attr_reader :klass, :table, :predicates

    def initialize(klass, predicates)
      @klass = klass
      @table = klass.ar_cache_table
      @predicates = predicates
    end

    def missed_values
      @missed_values ||= []
    end

    def invalid_keys
      @invalid_keys ||= []
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
          (ArCache.allow_blank_index? ? where_values_hash.key?(column) : where_values_hash[column]).tap do
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
      cacheable?
      @multi_values_key.nil?
    end

    def primary_key_index?
      cacheable?
      (@multi_values_key || @index.first) == table.primary_key
    end

    def cache_hash
      cacheable?
      return @cache_hash if defined?(@cache_hash)

      @cache_hash = {}
      multi_values_key = @multi_values_key || @index.first

      Array.wrap(where_values_hash[multi_values_key]).each do |v|
        @cache_hash[table.cache_key(where_values_hash, @index, multi_values_key, v)] = v
      end

      unless primary_key_index?
        @original_cache_hash = @cache_hash
        @cache_hash = ArCache.read_multi(*@cache_hash.keys, raw: true)
        @original_cache_hash.each { |k, v| missed_values << v unless @cache_hash.key?(k) }
        @cache_hash = @cache_hash.invert
      end

      @cache_hash.delete_if do |k, v|
        next unless klass.connection.transaction_manager.ar_cache_transactions?(k)
        missed_values << (primary_key_index? ? v : @original_cache_hash[v])
      end
    end

    def primary_cache_keys
      raise 'Does not detect primary key index' unless primary_key_index?

      @primary_cache_keys ||= Array(where_values_hash[table.primary_key]).map { |v| table.primary_cache_key(v) }
    end

    def missed_hash
      @missed_hash ||= missed_values.empty? ? {} : { (@multi_values_key || @index.first) => missed_values }
    end

    def add_missed_values(key)
      if primary_key_index?
        missed_values << cache_hash[key]
      else
        missed_values << @original_cache_hash[cache_hash[key]]
      end
    end

    # ArCache should remove lock key before execute query statements,
    # otherwise ArCahe will not fill missing cache value.
    def add_lock_key(key)
      invalid_keys << key
    end

    # After update/delete record, ArCache only remove primary cache key.
    # Therefore, the primary cache key is reliable, but the other cache
    # key may is wrong.
    def add_invalid_key(key)
      invalid_keys << cache_hash[key] unless primary_key_index?
    end

    def delete_invalid_keys
      ArCache.delete_multi(invalid_keys) if invalid_keys.any?
    end

    # This module is based on ActiveRecord::Relation::WhereClause modified
    module RawWhereClause
      def where_values_hash
        @where_values_hash ||= equalities(predicates).each_with_object({}) do |node, hash|
          # Don't support Arel::Nodes::NamedFunction.
          next if table.name != node.left.relation.name

          name = node.left.name.to_s
          value = extract_node_value(node.right)
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
        case node
        when Array
          node.map { |v| extract_node_value(v) }
        when Arel::Nodes::BindParam
          value_for_database(node.value)
        when Arel::Nodes::Casted, Arel::Nodes::Quoted
          value_for_database(node)
        end
      end

      private def value_for_database(node)
        value = node.value_for_database # Maybe raise ActiveModel::RangeError
        value.is_a?(Date) ? value.to_s : value
      end
    end
    include RawWhereClause
  end
end
