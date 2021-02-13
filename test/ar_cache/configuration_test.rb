# frozen_string_literal: true

require 'test_helper'

module ArCache
  describe Configuration do
    it 'should respond to disabled' do
      assert_respond_to ArCache::Configuration, :disabled
    end

    it 'should respond to disabled=' do
      assert_respond_to ArCache::Configuration, :disabled=
    end

    it 'should respond to select_disabled' do
      assert_respond_to ArCache::Configuration, :select_disabled
    end

    it 'should respond to select_disabled=' do
      assert_respond_to ArCache::Configuration, :select_disabled=
    end

    it 'should respond to expires_in' do
      assert_respond_to ArCache::Configuration, :expires_in
    end

    it 'should respond to expires_in=' do
      assert_respond_to ArCache::Configuration, :expires_in=
    end

    it 'should respond to cache_store' do
      assert_respond_to ArCache::Configuration, :cache_store
    end

    it 'should respond to cache_store=' do
      assert_respond_to ArCache::Configuration, :cache_store=
    end

    it 'should respond to tables_options' do
      assert_respond_to ArCache::Configuration, :tables_options
    end

    it 'should respond to tables_options=' do
      assert_respond_to ArCache::Configuration, :tables_options=
    end

    it 'should respond to coder' do
      assert_respond_to ArCache::Configuration, :coder
    end

    it 'should respond to coder=' do
      assert_respond_to ArCache::Configuration, :coder=
    end

    it 'should respond to configure' do
      assert_respond_to ArCache::Configuration, :configure
    end

    it 'should respond to get_table_options' do
      assert_respond_to ArCache::Configuration, :get_table_options
    end
  end
end
