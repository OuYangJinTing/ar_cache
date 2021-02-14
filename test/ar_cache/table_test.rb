# frozen_string_literal: true

require 'test_helper'

module ArCache
  describe Table do
    it 'use same table name concurrent create table object should only create one object' do
      4.times.each do
        Thread.new { ArCache::Table.new(User.table_name) }
      end

      assert_equal(1, ArCache::Table.all.count { |table| table.name == User.table_name })
    end

    describe '#cache_key' do
      it 'the different order where_values_hash should return same key' do
        index = %w[name status]
        first_key = User.ar_cache_table.cache_key({ 'name' => 'foobar', 'status' => 0 }, index)
        second_key = User.ar_cache_table.cache_key({ 'status' => 0, 'name' => 'foobar' }, index)

        assert_equal first_key, second_key
      end

      it 'should use md5 digest if length of value > 64' do
        actual_key = User.ar_cache_table.cache_key({ 'email' => '0' * 65 }, ['email'])
        md5 = Digest::MD5.hexdigest('0' * 65)
        expect_key = "#{User.ar_cache_table.cache_key_prefix}:#{User.ar_cache_table.version}:email=#{md5}"

        assert_equal expect_key, actual_key
      end
    end
  end
end
