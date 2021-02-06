# frozen_string_literal: true

module ArCache
  module Store
    def write(records)
      records_attributes = records.each_with_object({}) do |record, attributes_cache_hash|
        attributes = column_names.index_with { |column| record.send(:attribute_for_database, column) }

        key = nil
        unique_indexes.each_with_index do |index, i|
          if i.zero?
            key = primary_cache_key(attributes[primary_key])
            attributes_cache_hash[key] = attributes
          else
            attributes_cache_hash[cache_key(attributes, index)] = key
          end
        end
      end

      cache_store.write_multi(records_attributes, expires_in: expires_in)
    end

    def delete(id)
      cache_store.delete(primary_cache_key(id))
    end

    def read_records(where_clause, select_values, &block)
      recoreds = if where_clause.single?
                   read_single_record([], where_clause, select_values, &block)
                 else # is multi
                   read_multi_records([], where_clause, select_values, &block)
                 end

      where_clause.delete_invalid_keys # TODO: Should only delete the cache for the wrong value of the index column
      recoreds
    end

    private def read_single_record(records, where_clause, select_values, &block)
      entry = cache_store.read(where_clause.cache_key) if where_clause.cache_key
      return records unless entry

      if correct_entry?(entry, where_clause.to_h)
        entry = entry.slice(*select_values) if select_values
        records << instantiate(entry, &block)
      else
        where_clause.add_invalid_keys(where_clause.cache_key)
      end

      records
    end

    private def read_multi_records(records, where_clause, select_values, &block)
      entries_hash = cache_store.read_multi(*where_clause.cache_keys_hash.keys)
      where_clause.cache_keys_hash.each_key { |k| where_clause.add_missed_values(k) unless entries_hash.key?(k) }

      entries_hash.each do |k, entry|
        if correct_entry?(entry, where_clause.to_h)
          entry = entry.slice(*select_values) if select_values
          records << instantiate(entry, &block)
        else
          where_clause.add_missed_values(k)
          where_clause.add_invalid_keys(k)
        end
      end

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
