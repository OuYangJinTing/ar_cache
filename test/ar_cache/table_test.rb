# frozen_string_literal: true

require 'test_helper'

module ArCache
  describe Table do
    let(:table) { User.ar_cache_table }

    it 'should respond to methods' do
      assert_respond_to table, :name
      assert_respond_to table, :primary_key
      assert_respond_to table, :unique_indexes
      assert_respond_to table, :column_indexes
      assert_respond_to table, :column_names
      assert_respond_to table, :identity_cache_key
      assert_respond_to table, :short_sha1
    end

    describe '#new' do
      it 'should not create same table name object' do
        2.times { ArCache::Table.new(User.table_name) }
        assert_equal [table], ArCache::Table.all.select { |table| table.name == User.table_name }
      end

      it 'should not create same table name object when happen concurrent' do
        unless in_memory_db?
          begin
            ArCache::Table.alias_method(:original_initialize, :initialize)
            ArCache::Table.redefine_method(:initialize) { |table_name| sleep 0.1; original_initialize(table_name) }

            ArCache::Table.all.delete(table)

            Thread.new { ArCache::Table.new(User.table_name) }.join
            Thread.new { ArCache::Table.new(User.table_name) }.join

            assert_equal [table], ArCache::Table.all.select { |table| table.name == User.table_name }
          ensure
            ArCache::Table.alias_method(:initialize, :original_initialize)
          end
        end
      end
    end

    it '#update_cache should return -1 when disable ArCache' do
      assert_equal '', Empty.ar_cache_table.update_cache
    end

    it '#primary_cache_key format' do
      key = "#{table.cache_key_prefix}:#{table.primary_key}=1"

      assert_equal key, table.primary_cache_key(1)
    end

    it '#cache_key should return same key use different order where_values_hash called' do
      index = %w[name status]
      where_values_hash = { 'name' => 'foobar', 'status' => 0 }
      first_key = table.cache_key(where_values_hash, index)
      second_key = table.cache_key(where_values_hash.reverse_each.to_h, index)

      assert_equal first_key, second_key
      assert_equal "#{table.cache_key_prefix}:#{where_values_hash.to_query}", first_key
    end

    it '#normalize_unique_indexes should format' do
      assert_equal ['id'], Empty.ar_cache_table.unique_indexes.first
      assert_equal [['id'], ['mark']], Empty.ar_cache_table.unique_indexes
    end

    it '#query_unique_indexes' do
      assert_equal [['id'], ['email'], %w[name status]], table.unique_indexes
    end

    describe '#validate_unique_indexes' do
      let(:columns) { User.connection.columns(User.table_name) }

      it 'noexists column' do
        assert_raises(ArgumentError) do
          table.send(:validate_unique_indexes, [['noexists']], columns)
        end
      end

      it 'datetime type column' do
        assert_raises(ArgumentError) do
          table.send(:validate_unique_indexes, [['created_at']], User.connection.columns(User.table_name))
        end
      end
    end
  end
end
