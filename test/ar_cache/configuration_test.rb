# frozen_string_literal: true

require 'test_helper'

module ArCache
  describe Configuration do
    it 'should respond to methods' do
      assert_respond_to ArCache::Configuration, :cache_store
      assert_respond_to ArCache::Configuration, :tables_options
      assert_respond_to ArCache::Configuration, :read_uncommitted=
      assert_respond_to ArCache::Configuration, :read_uncommitted?
      assert_respond_to ArCache::Configuration, :disabled
      assert_respond_to ArCache::Configuration, :disabled=
      assert_respond_to ArCache::Configuration, :select_disabled
      assert_respond_to ArCache::Configuration, :select_disabled=
      assert_respond_to ArCache::Configuration, :expires_in
      assert_respond_to ArCache::Configuration, :expires_in=
      assert_respond_to ArCache::Configuration, :configure
    end

    it '#redis?' do
      bool = ArCache::Configuration.cache_store.is_a?(ActiveSupport::Cache::RedisCacheStore)
      assert_equal bool, !!ArCache::Configuration.redis?
    end

    it '#memcached?' do
      bool = ArCache::Configuration.cache_store.is_a?(ActiveSupport::Cache::MemCacheStore)
      assert_equal bool, !!ArCache::Configuration.memcached?
    end

    describe 'tmp reset configuration' do
      before { @source_configuration = ArCache::Configuration.tables_options }
      after { ArCache::Configuration.tables_options = @source_configuration }

      it '#cache_store=' do
        assert_raise(ArgumentError) { ArCache::Configuration.cache_store = {} }
      end

      describe '#tables_options=' do
        it 'should deep symbolize keys' do
          options = { table: { disabled: true } }
          ArCache::Configuration.tables_options = options.deep_stringify_keys
          assert_equal options, ArCache::Configuration.tables_options
        end
      end

      describe '#get_table_options' do
        it 'should formatt unique indexes' do
          ArCache::Configuration.tables_options = { table: { unique_indexes: [:identity, %i[email status]] } }
          table_options = ArCache::Configuration.get_table_options(:table)
          assert_equal [['identity'], %w[email status]], table_options[:unique_indexes]
        end
      end
    end
  end
end
