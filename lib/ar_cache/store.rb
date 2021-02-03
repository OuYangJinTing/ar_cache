# frozen_string_literal: true

module ArCache
  module Store
    delegate :cache_store, to: ArCache::Configuration

    # TODO
    # def update(*records)
    # end

    def write(*records) # rubocop:disable Metrics/CyclomaticComplexity
      return if disabled?
      return unless column_names == records.first&.attribute_names
      return unless records.first&.id?

      records_attributes = records.each_with_object({}) do |record, hash|
        attributes = attributes_for_database(record, column_names)

        primary_cache_key = cache_key(attributes, primary_key)
        hash[primary_cache_key] = attributes

        unique_indexes.each { |index| hash[cache_key(attributes, index)] = primary_cache_key }
      end

      cache_store.write_multi(records_attributes, expires_in: expires_in)
    end

    def delete(*records, previous: false)
      return if disabled?

      cache_keys = records.each_with_object([]) do |record, keys|
        attributes = attributes_for_database(record, index_columns, previous: previous)

        keys << cache_key(attributes, primary_key)
        unique_indexes.each { |index| keys << cache_key(attributes, index) }
      end

      cache_store.delete_multi(cache_keys)
    end

    def delete_by_primary_key(id)
      cache_store.delete(primary_cache_key(id)) if enabled?
    end

    def read_record(where_values_hash, index, select_values, &block)
      cache_key = cache_key(where_values_hash, index)
      entry = cache_store.read(cache_key)
      return unless entry

      entry = cache_store.read(entry) if entry.is_a?(String) # is primary cache key
      return unless entry

      if correct_entry?(entry, where_values_hash)
        entry = entry.slice(*select_values) if select_values
        instantiate(entry, &block)
      else
        cache_store.delete(cache_key) # TODO: Should only delete the cache for the wrong value of the index column
        nil
      end
    end

    def read_multi_records(where_values_hash, index, select_values, multi_values_key, &block) # rubocop:disable Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/CyclomaticComplexity
      records = []
      missed_values = []
      cache_keys_hash = {}

      cache_keys = where_values_hash[multi_values_key].map do |value|
        cache_key(where_values_hash, index, multi_values_key, value).tap { |key| cache_keys_hash[key] = value }
      end

      entries_hash = cache_store.ar_cache_fetch_multi(*cache_keys) { |key| missed_values << cache_keys_hash[key] }
      return [records, missed_values] if entries_hash.empty?

      # collect primary cache key
      primary_cache_key_hash = {}
      entries_hash.delete_if do |key, entry|
        entry.is_a?(String).tap { |bool| primary_cache_key_hash[key] = entry if bool }
      end

      if primary_cache_key_hash.any?
        invert_primary_cache_key_hash = primary_cache_key_hash.invert
        attributes_entries_hash = cache_store.ar_cache_fetch_multi(*primary_cache_key_hash.values) do |key|
          missed_values << cache_keys_hash[invert_primary_cache_key_hash[key]]
        end
        attributes_entries_hash.each do |key, value|
          entries_hash[invert_primary_cache_key_hash[key]] = value
        end
      end

      error_cache_kyes = []
      entries_hash.each do |key, entry|
        if correct_entry?(entry, where_values_hash)
          entry = entry.slice(*select_values) if select_values
          records << instantiate(entry, &block)
        else
          missed_values << cache_keys_hash[key]
          error_cache_kyes << key
        end
      end
      # TODO: Should only delete the cache for the wrong value of the index column
      cache_store.delete_multi(error_cache_kyes) if error_cache_kyes.any?

      missed_values.empty? ? [records] : [records, missed_values]
    end

    private def correct_entry?(entry, where_values_hash)
      where_values_hash.all? do |key, value|
        if value.is_a?(Array)
          value.include?(entry[key])
        else
          entry[key] == value
        end
      end
    end
  end
end
