# frozen_string_literal: true

require 'test_helper'

describe ArCache, 'cache switch' do
  before do
    @user = User.create(name: :foobar, email: 'foobar@gmail.com')
    @empty = Empty.create
  end

  describe 'disabled cache' do
    it 'should not update cache version' do
      assert_no_cache(:write) do
        assert_no_sql { Empty.ar_cache_table.update_version }
      end
    end

    it 'should not write cache' do
      assert_no_cache(:write) { Empty.ar_cache_table.write([@empty.reload]) }
    end

    it 'should not delete cache' do
      assert_no_cache(:delete) { Empty.ar_cache_table.delete(@empty.id) }
    end

    it 'should not read cache' do
      assert_no_cache(:read) { Empty.find(@empty.id) }
    end
  end

  describe 'enabled cache' do
    it 'should update cache version' do
      old_version = User.ar_cache_table.version
      new_version = User.ar_cache_table.update_version

      assert_not_equal old_version, new_version
    end

    it 'should write cache' do
      User.ar_cache_table.delete(@user.id)
      User.ar_cache_table.write([@user.reload])

      assert ArCache::Store.exist?(User.ar_cache_table.primary_cache_key(@user.id))
    end

    it 'should delete cache' do
      User.ar_cache_table.write([@user.reload])

      assert ArCache::Store.exist?(User.ar_cache_table.primary_cache_key(@user.id))

      User.ar_cache_table.delete(@user.id)

      assert_not ArCache::Store.exist?(User.ar_cache_table.primary_cache_key(@user.id))
    end

    it 'should read cache' do
      User.ar_cache_table.write([@user.reload])

      assert_no_queries { User.find(@user.id) }
    end
  end
end
