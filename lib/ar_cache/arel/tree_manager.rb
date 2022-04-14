# frozen_string_literal: true

module ArCache
  module Arel
    class TreeManager
      def ar_cache_table
        ::ArCache::Table[@ast.relation.left.name]
      end

      def recognizable_ar_cache?
        return @recognizable_ar_cache if defined?(@recognizable_ar_cache)

        @recognizable_ar_cache = catch(:abort) { recognizable_wheres? } && primary_key_nodes.any?
      end

      def delete_ar_cache_keys(connection)
        return false if ar_cache_table.disabled? || !recognizable_ar_cache?

        cache_keys = primary_key_nodes.map { |node| extract_primark_cache_keys(node) }
        cache_keys = cache_keys.reduce(&:&) unless primary_key_nodes.one?
        connection.current_transaction.delete_ar_cache(cache_keys)

        true
      end

      private def primary_key_nodes
        @primary_key_nodes ||= []
      end

      private def extract_primark_cache_keys(node)
        case node
        when Arel::Nodes::Equality
          value = node.right.value
          if value.respond_to?(:value_for_database)
            value = primary_key_nodes.one? ? value.value : value.value_for_database
          end
          [ar_cache_table.primary_cache_key(value)]
        when Arel::Nodes::HomogeneousIn
          values = primary_key_nodes.one? ? node.values : node.casted_values
          values.map { |value| ar_cache_table.primary_cache_key(value) }
        else
          raise ::ArCache::UnknownArelNode, "Unknown Arel node: #{node.class}"
        end
      end

      private def recognizable_wheres?(nodes = @ast.wheres)
        nodes.each do |node|
          if node.is_a?(Arel::Nodes::And)
            recognizable_wheres?(node.children)
          elsif node.equality? # Arel::Nodes::In|Arel::Nodes::HomogeneousIn|Arel::Nodes::Equality
            if node.is_a?(Arel::Nodes::In)
              throw(:abort, false)
            elsif @ast.relation.left == node.left.relation && ar_cache_table.primary_key == node.left.name
              primary_key_nodes << node
            end
          else
            throw(:abort, false)
          end
        end
      end
    end
  end
end
