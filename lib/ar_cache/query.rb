# frozen_string_literal: true

module ArCache
  class Query
    attr_reader :relation, :table, :where_clause

    def initialize(relation)
      @relation = relation
      @table = @relation.klass.ar_cache_table
      @where_clause = ArCache::WhereClause.new(@relation.klass, @relation.where_clause.send(:predicates))
    end

    def exec_queries(&block)
      return relation.skip_ar_cache.send(:exec_queries, &block) unless exec_queries_cacheable?

      records = table.read(where_clause, @select_values, &block)

      missed_relation = if records.empty?
        relation
      elsif where_clause.missed_hash.any?
        relation.rewhere(where_clause.missed_hash)
      end

      if missed_relation
        missed_relation = missed_relation.select(table.column_names) if table.ignored_columns.any? || true
        records += relation.find_by_sql(missed_relation.arel, &block)
      end

      records_order(records)
    end

    private def exec_queries_cacheable? # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      return false if relation.skip_query_cache_value
      return false if relation.group_values.any?
      return false if relation.joins_values.any?
      return false if relation.left_outer_joins_values.any?
      return false if relation.offset_value
      return false unless relation.from_clause.empty?
      return false unless where_clause.cacheable?
      return false unless select_values_cacheable?
      return false unless order_values_cacheable?
      return false unless limit_value_cacheable?

      true
    end

    private def select_values_cacheable?
      return true if relation.select_values.empty?
      return false if table.select_disabled?

      @select_values = relation.select_values.map(&:to_s)
      (@select_values - table.column_names).empty?
    end

    private def order_values_cacheable?
      return true if where_clause.single?

      size = relation.order_values.size
      return true if size.zero?
      return false if size > 1

      first_order_value = relation.order_values.first
      case first_order_value
      when Arel::Nodes::Ordering
        @order_name = first_order_value.expr.name
        @order_desc = first_order_value.descending?
      when String
        @order_name, @order_desc = first_order_value.downcase.split
        return false unless table.column_names.include?(@order_name)

        @order_desc = @order_desc == 'desc'
      else
        return false
      end

      true
    end

    private def limit_value_cacheable?
      where_clause.single? || relation.limit_value.nil?
    end

    private def records_order(records)
      return records if records.size < 2
      return records if @order_name.nil?

      method = "#{@order_name}_for_database"
      return records.sort! { |a, b| b.send(method) <=> a.send(method) } if @order_desc

      records.sort! { |a, b| a.send(method) <=> b.send(method) }
    end
  end
end
