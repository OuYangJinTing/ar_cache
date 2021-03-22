# frozen_string_literal: true

require 'test_helper'

module ArCache
  describe Marshal do
    describe '#delete' do
      it 'should return -1 when disable ArCache' do
        assert_equal(-1, Empty.ar_cache_table.delete('ArCache::Store#delete'))
      end

      it 'should try delete cache when enable ArCache' do
        assert_not_equal(-1, User.ar_cache_table.delete('ArCache::Store#delete'))
      end
    end

    describe '#write' do
      it 'should return -1 when disable ArCache' do
        Empty.create!
        assert_equal(-1, Empty.ar_cache_table.write([Empty.first]))
      end

      it 'should write cache when enable ArCache' do
        User.create(name: :foobar, email: 'foobar@test.com')
        assert_equal User.ar_cache_table.unique_indexes.size, User.ar_cache_table.write([User.first]).size
      end
    end

    describe '#read' do
      let(:user1) { User.create(name: :foo, email: 'foo@test.com') }
      let(:user2) { User.create(name: :bar, email: 'bar@test.com') }
      let(:relation) { User.where(email: [user1.email, user2.email]) }

      before do
        relation.load # write cache
        assert ArCache::Store.exist?(User.ar_cache_table.primary_cache_key(user1.id))
        assert ArCache::Store.exist?(User.ar_cache_table.primary_cache_key(user2.id))
      end

      it 'should return complete attributes object when select_values noexists' do
        where_clause = ArCache::WhereClause.new(User, relation.where_clause.send(:predicates))
        assert where_clause.cacheable?
        users = nil
        assert_not_called(ArCache::Store, :delete_multi) { users = User.ar_cache_table.read(where_clause, nil) }

        assert_equal 2, users.size
        assert_equal user1.attributes, users.first.attributes
        assert_equal user2.attributes, users.last.attributes
        assert_not where_clause.invalid_keys
        assert_empty where_clause.missed_hash
      end

      it 'should return select attributes object when select_values exists' do
        where_clause = ArCache::WhereClause.new(User, relation.where_clause.send(:predicates))
        assert where_clause.cacheable?
        users = nil
        assert_not_called(ArCache::Store, :delete_multi) { users = User.ar_cache_table.read(where_clause, ['id']) }

        assert_equal 2, users.size
        assert_equal user1.attributes.slice('id'), users.first.attributes
        assert_equal user2.attributes.slice('id'), users.last.attributes
        assert_not where_clause.invalid_keys
        assert_empty where_clause.missed_hash
      end

      it 'should return cache attributes fully match where condition object' do
        other_relation = relation.where(name: :foo)
        where_clause = ArCache::WhereClause.new(User, other_relation.where_clause.send(:predicates))
        assert where_clause.cacheable?
        users = nil
        assert_called(ArCache::Store, :delete_multi) { users = User.ar_cache_table.read(where_clause, nil) }

        assert_equal 1, users.size
        assert_equal user1.attributes, users.first.attributes
        assert where_clause.invalid_keys
        assert_equal({ 'email' => [user2.email] }, where_clause.missed_hash)
      end
    end

    it '#detect_wrong_key' do
      assert_not User.ar_cache_table.send(:detect_wrong_key, { 'name' => nil }, { 'name' => nil })
      assert_not User.ar_cache_table.send(:detect_wrong_key, { 'name' => nil }, { 'name' => [nil] })
      assert_equal 'name', User.ar_cache_table.send(:detect_wrong_key, { 'name' => nil }, { 'name' => 'foobar' })
      assert_equal 'name', User.ar_cache_table.send(:detect_wrong_key, { 'name' => nil }, { 'name' => ['foobar'] })
    end

    it '#instantiate should except ignored columns and instantiate model' do
      user = User.ar_cache_table.send(:instantiate, User, 'useless' => nil)
      assert_not user.attributes.key?('useless')
    end
  end
end
