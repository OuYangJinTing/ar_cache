# frozen_string_literal: true

module ArCache
  module TestHelper
    def savepoint
      ::ActiveRecord::Base.connection.begin_transaction(joinable: false)
      yield
    ensure
      ::ActiveRecord::Base.connection.rollback_transaction
    end

    def primary_cache_key(model)
      model.ar_cache_table.primary_cache_key(model.id)
    end

    def write_cache(*models)
      models.group_by(&:class).each { |klass, group| klass.find(*group.map(&:id)) }
    end

    def delete_cache(*models)
      models.group_by(&:class).each { |klass, group| klass.ar_cache_table.delete(*group.map(&:id)) }
    end

    def assert_model_equal(exp, act)
      exp = exp.is_a?(Array) ? exp.map(&:attributes) : exp.attributes
      act = act.is_a?(Array) ? act.map(&:attributes) : act.attributes
      assert_equal exp, act
    end

    def assert_blank_cache(*keys)
      if ArCache.cache_lock?
        assert_equal keys.index_with(ArCache::PLACEHOLDER), ArCache.read_multi(*keys)
      else
        assert_empty ArCache.read_multi(keys)
      end
    end

    def assert_cache(type, *keys)
      CacheRecord.clear_log
      yield
      if keys.any?
        assert_equal keys, CacheRecord.send(type) & keys
      else
        assert_not_empty CacheRecord.send(type)
      end
    end

    def assert_no_cache(type, *keys)
      CacheRecord.clear_log
      yield
      if keys.any?
        assert_empty CacheRecord.send(type) & keys
      else
        assert_empty CacheRecord.send(type)
      end
    end
  end
end
