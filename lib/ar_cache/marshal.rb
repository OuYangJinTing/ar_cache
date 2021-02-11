# frozen_string_literal: true

module ArCache
  module Marshal
    def delete(id)
      enabled? ? ArCache::Store.delete(primary_cache_key(id)) : -1
    end

    def write(hash_rows) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      return -1 if disabled?
      return -1 if ignored_columns.any? && (column_names - hash_rows.first.keys).any?

      cache_hash = {}

      hash_rows.each do |attributes|
        key = nil

        unique_indexes.each_with_index do |index, i|
          if i.zero? # is primary key
            key = primary_cache_key(attributes[primary_key])
            cache_hash[key] = attributes
          else
            cache_hash[cache_key(attributes, index)] = key
          end
        end
      end

      ArCache::Store.write_multi(cache_hash)
    rescue Encoding::UndefinedConversionError
      0
    end

    def read(where_clause, select_values, &block)
      entries_hash = ArCache::Store.read_multi(where_clause.cache_hash.keys)
      where_clause.cache_hash.each_key { |k| where_clause.add_missed_values(k) unless entries_hash.key?(k) }

      records = []

      entries_hash.each do |k, entry|
        entry = entry.slice(*select_values) if select_values
        wrong_key = detect_wrong_key(entry, where_clause.to_h)

        if wrong_key
          where_clause.add_missed_values(k)
          where_clause.add_invalid_keys(k) if column_indexes.include?(k)
        else
          records << instantiate(where_clause.klass, entry, &block)
        end
      end

      where_clause.delete_invalid_keys # TODO: Should only delete the cache for the wrong value of the index column

      records
    end

    private def detect_wrong_key(entry, where_values_hash)
      where_values_hash.detect do |k, v|
        value = entry[k]
        next if value.nil?

        if v.is_a?(Array)
          return k unless v.include?(value)
        else
          return k unless v == value
        end
      end
    end

    private def instantiate(klass, attributes, &block)
      attributes.except!(*klass.ignored_columns) if klass.ignored_columns.any?

      return klass.instantiate(attributes, &block) if attributes.key?(klass.inheritance_column)

      klass.send(:instantiate_instance_of, klass, attributes, &block)
    end
  end
end
