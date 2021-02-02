# frozen_string_literal: true

module ArCache
  class Query
    attr_reader :relation, :model

    def initialize(relation)
      @relation = relation
      @model = relation.klass.ar_cache_model
    end

    def exec_queries(&block)
      return relation.skip_ar_cache.send(:exec_queries, &block) unless exec_queries_cacheable?

      if single_query?
        record = model.read_record(where_values_hash, @index, @select_values, &block)
        records = record ? [record] : relation.find_by_sql(relation.arel, &block).tap { |rs| model.write(*rs) }
      else
        records, missed_value = model.read_multi_records(where_values_hash, @index, @select_values, @multi_values_key,
                                                         &block)
        unless missed_value.nil?
          arel = relation.rewhere(@multi_values_key => missed_value).arel
          records += relation.find_by_sql(arel, &block).tap { |rs| model.write(*rs) }
        end
        records = records_order(records)
      end

      records.tap { reset }
    end

    private def exec_queries_cacheable? # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      return false if relation.skip_query_cache_value
      return false if relation.group_values.any?
      return false if relation.joins_values.any?
      return false if relation.left_outer_joins_values.any?
      return false if relation.offset_value
      return false unless relation.from_clause.empty?
      return false unless where_clause_cacheable?
      return false unless select_values_cacheable?
      return false unless order_values_cacheable?
      return false unless limit_value_cacheable?

      true
    end

    private def where_clause_cacheable? # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      return false if predicates.empty?
      return false if where_values_hash.length != predicates.length

      primary_key = relation.primary_key
      if where_values_hash.key?(primary_key)
        @index = primary_key
        @multi_values_key = primary_key if where_values_hash[primary_key].is_a?(Array)
        return true
      end

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
        return true if count < 2
      end

      false
    end

    private def select_values_cacheable?
      return true if relation.select_values.empty?
      return false if model.select_disabled?

      @select_values = relation.select_values.map(&:to_s)
      (@select_values - relation.klass.column_names).empty?
    end

    private def order_values_cacheable? # rubocop:disable Metrics/CyclomaticComplexity
      return true if single_query?

      size = relation.order_values.size
      return true if size.zero?
      return false if size > 1

      first_order_value = relation.order_values.first
      case first_order_value
      when Arel::Nodes::Ordering
        return false unless relation.klass.column_names.include?(first_order_value.expr.name)

        @order_name = first_order_value.expr.name
        @order_desc = first_order_value.descending?
        return true
      when String
        @order_name, @order_desc = first_order_value.downcase.split
        return false unless relation.klass.column_names.include?(@order_name)

        @order_desc = @order_desc == 'desc'
        return true
      end

      false
    end

    private def limit_value_cacheable?
      single_query? || relation.limit_value.nil?
    end

    private def single_query?
      @multi_values_key.nil?
    end

    private def records_order(records)
      return records unless @order_name

      method = "#{@order_name}_for_database"
      return records.sort { |a, b| b.send(method) <=> a.send(method) } if @order_desc

      records.sort { |a, b| a.send(method) <=> b.send(method) }
    end

    private def reset
      @where_values_hash = nil
      @index = nil
      @multi_values_key = nil
      @select_values = nil
      @order_name = nil
      @order_desc = nil
    end

    private def predicates
      relation.where_clause.send(:predicates)
    end

    # This method is based on ActiveRecord::Relation::WhereClause#to_h modified
    # TODO: where_values_hash add Range type value
    private def where_values_hash
      @where_values_hash ||= relation.where_clause.send(:equalities, predicates).each_with_object({}) do |node, hash|
        name = node.left.name.to_s
        value = extract_node_value(node.right)
        hash[name] = value
      end
    end

    # This method is based on ActiveRecord::Relation::WhereClause#extract_node_value modified
    private def extract_node_value(node)
      case node
      when Array
        node.map { |v| extract_node_value(v) }
      when Arel::Nodes::BindParam
        node.value.value_for_database
      when Arel::Nodes::Casted, Arel::Nodes::Quoted
        node.value_for_database
      end
    end
  end
end
