# frozen_string_literal: true

require 'test_helper'

describe ArCache do
  it 'should has a version number' do
    assert_not_nil ArCache::VERSION
  end

  it 'should respond to delegate methods' do
    assert_called(ArCache::Configuration, :configure) { ArCache.configure }
    assert_called(ArCache::Configuration, :memcached?) { ArCache.memcached? }
    assert_called(ArCache::Configuration, :redis?) { ArCache.redis? }
    assert_called(ArCache::Configuration, :cache_store) { ArCache.cache_store }
    assert_called(ArCache::Configuration.cache_store, :read) { ArCache.read }
    assert_called(ArCache::Configuration.cache_store, :read_multi) { ArCache.read_multi }
    assert_called(ArCache::Configuration.cache_store, :write) { ArCache.write }
    assert_called(ArCache::Configuration.cache_store, :write_multi) { ArCache.write_multi }
    assert_called(ArCache::Configuration.cache_store, :delete) { ArCache.delete }
    assert_called(ArCache::Configuration.cache_store, :delete_multi) { ArCache.delete_multi }
    assert_called(ArCache::Configuration.cache_store, :clear) { ArCache.clear }
  end

  it '#skip_cache' do
    assert_not ArCache.skip_cache?
    ArCache.skip_cache do
      ArCache.skip_cache { assert ArCache.skip_cache? }
      assert ArCache.skip_cache?
    end
    assert_not ArCache.skip_cache?
  end

  it '#skip_expire' do
    assert_not ArCache.skip_expire?
    ArCache.skip_expire do
      ArCache.skip_expire { assert ArCache.skip_expire? }
      assert ArCache.skip_expire?
    end
    assert_not ArCache.skip_expire?
  end

  it '#cache_reflection?' do
    reflection = User.reflections[:account]
    ArCache.instance_variable_get(:@cache_reflection).delete(reflection)

    assert_not Thread.current[:ar_cache_reflection]
    ArCache.cache_reflection?(reflection) { assert Thread.current[:ar_cache_reflection] }
    assert_not Thread.current[:ar_cache_reflection]

    assert ArCache.instance_variable_get(:@cache_reflection).key?(reflection)
    ArCache.cache_reflection?(reflection) { raise 'ArCache should cache relation' }
  end

  describe 'serialization' do
    let(:user_attributes) { User.new.attributes }
    let(:times) { (ArCache.memcached? || ArCache.redis?) ? 1 : 0 }

    it '#dump_attributes' do
      assert_called(Oj, :dump, times: times) { ArCache.dump_attributes(user_attributes) }
    end

    it '#load_attributes' do
      assert_called(Oj, :load, times: times) { ArCache.load_attributes(user_attributes) }
    end
  end
end
