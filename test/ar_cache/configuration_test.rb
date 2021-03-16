# frozen_string_literal: true

require 'test_helper'

module ArCache
  describe Configuration do
    describe '#tables_options=' do
      it 'outder hash key verification' do
        assert_raise(ArgumentError) { DEFAULT_CONFIGURATION.tables_options = { 'table' => {} } }
      end

      it 'inner hash key verification' do
        assert_raise(ArgumentError) { DEFAULT_CONFIGURATION.tables_options = { table: { 'disabled' => true } } }
      end
    end

    it '#cache_store= should verify parameters' do
      assert_raise(ArgumentError) { DEFAULT_CONFIGURATION.cache_store = {} }
    end

    it '#coder= should verify parameters' do
      assert_raise(ArgumentError) { DEFAULT_CONFIGURATION.coder = Marshal }
    end

    it '#get_table_options should return format hash' do
      DEFAULT_CONFIGURATION.tables_options = { table: { unique_indexes: [:identity, %i[email status]] } }
      table_options = DEFAULT_CONFIGURATION.get_table_options(:table)

      assert_equal DEFAULT_CONFIGURATION.disabled, table_options[:disabled]
      assert_equal DEFAULT_CONFIGURATION.select_disabled, table_options[:select_disabled]
      assert_equal [['identity'], %w[email status]], table_options[:unique_indexes]
    end

    it 'should exists default configuration values' do
      assert_not_nil DEFAULT_CONFIGURATION.cache_store
      assert_not_nil DEFAULT_CONFIGURATION.tables_options
      assert_not_nil DEFAULT_CONFIGURATION.coder
      assert_not_nil DEFAULT_CONFIGURATION.expires_in
      assert_not_nil DEFAULT_CONFIGURATION.column_length

      assert DEFAULT_CONFIGURATION.select_disabled
      assert_not DEFAULT_CONFIGURATION.disabled
      assert_not DEFAULT_CONFIGURATION.read_uncommitted
    end
  end
end
