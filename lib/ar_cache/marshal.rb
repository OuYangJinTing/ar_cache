# frozen_string_literal: true

module ArCache
  module Marshal
    def delete(*ids)
      return -1 if disabled?

      if ids.one?
        ArCache.delete(primary_cache_key(ids.first))
      else
        ArCache.delete_multi(ids.map { |id| primary_cache_key(id) })
      end
    end

    def write(records_attributes)
      return -1 if disabled?

      records_attributes.each do |attributes|
        key = primary_cache_key(attributes[primary_key])
        stringify_attributes = ArCache.dump(attributes)
        bool = ArCache.write(key, stringify_attributes, unless_exist: ArCache.cache_lock?, raw: true, expires_in: ArCache.expires_in)
        if ArCache.cache_lock? && !bool
          value = ArCache.read(key, raw: true)
          next if value == ArCache::LOCK
          next ArCache.lock(key) if value != stringify_attributes
        end

        unique_indexes.each_with_index do |index, i|
          ArCache.write(cache_key(attributes, index), key, raw: true, expires_in: ArCache.expires_in) unless i.zero?
        end
      end
    rescue Encoding::UndefinedConversionError
      0
    end

    def read(where_clause, select_values = nil, &block)
      entries_hash = ArCache.read_multi(*where_clause.cache_hash.keys, raw: true)
      where_clause.cache_hash.each_key do |k|
        v = entries_hash[k]

        case v
        when nil
          where_clause.add_missing_values(k)
        when ArCache::LOCK
          where_clause.add_missing_values(k)
          where_clause.add_lock_key(k)
          entries_hash.delete(k)
        else
          entries_hash[k] = ArCache.load(v)
        end
      end

      records = []

      entries_hash.each do |k, entry|
        mismatch_column = detect_mismatch_column(entry, where_clause.to_h)

        if mismatch_column
          where_clause.add_missing_values(k)
          where_clause.add_cache_invalid_key(k) if index_column_names.include?(mismatch_column)
        else
          entry = entry.slice(*select_values) if select_values
          records << instantiate(where_clause.klass, entry, &block)
        end
      end

      where_clause.delete_invalid_cache_keys
      records
    end

    private def detect_mismatch_column(entry, where_values_hash)
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

      if attributes.key?(klass.inheritance_column)
        klass.instantiate(attributes, &block)
      else
        klass.send(:instantiate_instance_of, klass, attributes, &block)
      end
    end
  end
end
