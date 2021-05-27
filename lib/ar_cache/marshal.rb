# frozen_string_literal: true

module ArCache
  module Marshal
    delegate :expires_in, :cache_lock?, to: ArCache::Configuration
    delegate :dump_attributes, :load_attributes, to: ArCache

    def delete(*ids)
      return -1 if disabled?

      ArCache.delete_multi(ids.map { |id| primary_cache_key(id) })
    end

    def write(records)
      return -1 if disabled?

      records.each do |attributes|
        key = primary_cache_key(attributes[primary_key])
        ArCache.write(key, dump_attributes(attributes), unless_exist: cache_lock?, raw: true, expires_in: expires_in)
        unique_indexes.each_with_index do |index, i|
          # The first index is primary key, should skip it.
          ArCache.write(cache_key(attributes, index), key, raw: true, expires_in: expires_in) unless i.zero?
        end
      end
    rescue Encoding::UndefinedConversionError
      0
    end

    def read(where_clause, select_values = nil, &block)
      entries_hash = ArCache.read_multi(*where_clause.cache_hash.keys, raw: true)
      entries_hash = entries_hash.each do |k, v|
        if v == ArCache::PLACEHOLDER
          entries_hash.delete(k)
          where_clause.add_blank_primary_cache_key(k)
        else
          entries_hash[k] = load_attributes(v)
        end
      end
      where_clause.cache_hash.each_key { |k| where_clause.add_missed_values(k) unless entries_hash.key?(k) }

      records = []

      entries_hash.each do |k, entry|
        wrong_key = detect_wrong_column(entry, where_clause.to_h)

        if wrong_key
          where_clause.add_missed_values(k)
          where_clause.add_invalid_second_cache_key(k) if column_indexes.include?(wrong_key)
        else
          entry = entry.slice(*select_values) if select_values
          records << instantiate(where_clause.klass, entry, &block)
        end
      end

      where_clause.delete_invalid_keys
      records
    end

    private def detect_wrong_column(entry, where_values_hash)
      where_values_hash.detect do |k, v|
        value = entry[k]

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
