# frozen_string_literal: true

module ArCache
  module Store
    def write(*records) # rubocop:disable Metrics/CyclomaticComplexity
      return unless enabled?
      return unless column_names == records.first&.attribute_names
      return unless records.first&.id?

      records_attributes = records.each_with_object({}) do |record, attributes_cache_hash|
        attributes = attributes_for_database(record)

        primary_cache_key = nil
        unique_indexes.each_with_index do |index, i|
          if i.zero?
            primary_cache_key = cache_key(attributes, [primary_key])
            attributes_cache_hash[primary_cache_key] = attributes
          else
            attributes_cache_hash[cache_key(attributes, index)] = primary_cache_key
          end
        end
      end

      cache_store.write_multi(records_attributes, expires_in: expires_in)
    end

    def delete(*records, previous: false)
      return if disabled?

      cache_keys = records.each_with_object([]) do |record, keys|
        attributes = attributes_for_database(record, index_columns, previous: previous)
        unique_indexes.each { |index| keys << cache_key(attributes, index) }
      end

      cache_store.delete_multi(cache_keys)
    end

    def read_records(where_clause, select_values, &block)
      if where_clause.single?
        read_single_record([], where_clause, select_values, &block)
      else # is multi
        read_multi_records([], where_clause, select_values, &block)
      end
    end

    private def read_single_record(records, where_clause, select_values, &block)
      entry = cache_store.read(where_clause.cache_key) if where_clause.cache_key
      return records unless entry

      if correct_entry?(entry, where_clause.to_h)
        entry = entry.slice(*select_values) if select_values
        records << instantiate(entry, &block)
      else
        where_clause.delete_cache_keys # TODO: Should only delete the cache for the wrong value of the index column
      end

      records
    end

    private def read_multi_records(records, where_clause, select_values, &block)
      entries_hash = cache_store.read_multi(*where_clause.cache_keys_hash.keys)
      where_clause.cache_keys_hash.each { |k, v| where_clause.add_missed_values(k) unless entries_hash.key?(k) }

      invalid_keys = []

      entries_hash.each do |k, entry|
        if correct_entry?(entry, where_clause.to_h)
          entry = entry.slice(*select_values) if select_values
          records << instantiate(entry, &block)
        else
          where_clause.add_missed_values(k)
          where_clause.concat_orginal_cache_key(k, invalid_keys)
        end
      end

      cache_store.delete_multi(invalid_keys) if invalid_keys.any? # TODO: Should only delete the cache for the wrong value of the index column

      records
    end

    private def correct_entry?(entry, where_values_hash)
      where_values_hash.all? do |k, v|
        if v.is_a?(Array)
          v.include?(entry[k])
        else
          entry[k] == v
        end
      end
    end

    private def cache_store
      ArCache::Configuration.cache_store
    end
  end
end
