# frozen_string_literal: true

require 'test_helper'

module ArCache
  describe Table do
    let(:table) { User.ar_cache_table }

    it '#new should only create one object when use same table name concurrent calld #new' do
      4.times do
        Thread.new { ArCache::Table.new(User.table_name) }
      end

      assert_equal(1, ArCache::Table.all.count { |table| table.name == User.table_name })
    end

    it '#md5 should use coder-disabled-columns calculate' do
      coder = ArCache::Configuration.coder
      disabled = table.disabled?
      columns = User.connection.columns(User.table_name)
      md5 = Digest::MD5.hexdigest("#{coder}-#{disabled}-#{columns.to_json}")

      assert_equal md5, table.md5
    end

    it '#update_version should return -1 when disable ArCache' do
      assert_equal(-1, Empty.ar_cache_table.update_version)
    end

    it '#primary_cache_key format' do
      key = "#{table.cache_key_prefix}:#{table.version}:#{table.primary_key}=1"

      assert_equal key, table.primary_cache_key(1)
    end

    it '#cache_key should return same key use different order where_values_hash called' do
      index = %w[name status]
      where_values_hash = { 'name' => 'foobar', 'status' => 0 }
      first_key = table.cache_key(where_values_hash, index)
      second_key = table.cache_key(where_values_hash.reverse_each.to_h, index)

      assert_equal first_key, second_key
      assert_equal "#{table.cache_key_prefix}:#{table.version}:#{where_values_hash.to_query}", first_key
    end

    it '#normalize_unique_indexes should format' do
      assert_equal ['id'], Empty.ar_cache_table.unique_indexes.first
      assert_equal [['id'], ['mark']], Empty.ar_cache_table.unique_indexes
    end

    it '#query_unique_indexes' do
      assert_equal [['id'], ['email'], %w[name status]], table.unique_indexes
    end

    describe '#custom_unique_indexes' do
      let(:columns) { User.connection.columns(User.table_name) }

      it 'noexists column' do
        assert_raises(ArgumentError) do
          table.send(:custom_unique_indexes, [['noexists']], columns)
        end
      end

      it 'datetime type column' do
        assert_raises(ArgumentError) do
          table.send(:custom_unique_indexes, [['created_at']], User.connection.columns(User.table_name))
        end
      end
    end
  end
end
