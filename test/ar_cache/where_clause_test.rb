# frozen_string_literal: true

require 'test_helper'

module ArCache
  describe WhereClause do
    let(:where_clause) { ArCache::WhereClause.allocate }

    it 'should respond to methods' do
      assert_respond_to where_clause, :klass
      assert_respond_to where_clause, :table
      assert_respond_to where_clause, :predicates
    end

    describe '#cacheable?' do
      it 'when predicates is noexists' do
        predicates = User.all.where_clause.send(:predicates)
        assert_not ArCache::WhereClause.new(User, predicates).cacheable?
      end

      it 'when where_values_hash.length != predicates.length' do
        predicates = User.where(id: 1).or(User.where(id: 2)).where_clause.send(:predicates)
        assert_not ArCache::WhereClause.new(User, predicates).cacheable?
      end

      describe '#hit_unique_index?' do
        it 'normal column query' do
          predicates = User.where(name: :foobar).where_clause.send(:predicates)
          assert_not ArCache::WhereClause.new(User, predicates).cacheable?
        end

        it 'single query hit index' do
          predicates = User.where(id: 1).where_clause.send(:predicates)
          where_clause = ArCache::WhereClause.new(User, predicates)
          assert where_clause.cacheable?
          assert_equal ['id'], where_clause.instance_variable_get(:@index)
          assert_not where_clause.instance_variable_get(:@multi_values_key)

          predicates = User.where(name: :foobar, status: 1).where_clause.send(:predicates)
          where_clause = ArCache::WhereClause.new(User, predicates)
          assert where_clause.cacheable?
          assert_equal %w[name status], where_clause.instance_variable_get(:@index)
          assert_not where_clause.instance_variable_get(:@multi_values_key)
        end

        it 'multi query hit index' do
          predicates = User.where(id: [1, 2, 3]).where_clause.send(:predicates)
          where_clause = ArCache::WhereClause.new(User, predicates)
          assert where_clause.cacheable?
          assert_equal ['id'], where_clause.instance_variable_get(:@index)
          assert_equal 'id', where_clause.instance_variable_get(:@multi_values_key)

          predicates = User.where(name: %i[foo bar], status: 1).where_clause.send(:predicates)
          where_clause = ArCache::WhereClause.new(User, predicates)
          assert where_clause.cacheable?
          assert_equal %w[name status], where_clause.instance_variable_get(:@index)
          assert_equal 'name', where_clause.instance_variable_get(:@multi_values_key)

          predicates = User.where(name: %i[foo bar], status: [0, 1]).where_clause.send(:predicates)
          assert_not ArCache::WhereClause.new(User, predicates).cacheable?
        end
      end
    end

    describe '#cache_hash' do
      it 'when hit primary key index' do
        predicates = User.where(id: 1).where_clause.send(:predicates)
        where_clause = ArCache::WhereClause.new(User, predicates)
        assert where_clause.cacheable?

        assert_equal({ User.ar_cache_table.primary_cache_key(1) => 1 }, where_clause.cache_hash)
        assert_not where_clause.instance_variable_get(:@original_cache_hash)
      end

      it 'when hit other index' do
        predicates = User.where(email: 'foobar@test.com').where_clause.send(:predicates)
        where_clause = ArCache::WhereClause.new(User, predicates)
        assert where_clause.cacheable?
        assert_empty where_clause.cache_hash
        # assert_empty where_clause.instance_variable_get(:@original_cache_hash)
        assert_equal ['foobar@test.com'], where_clause.instance_variable_get(:@missed_values)
        assert_equal({ 'email' => ['foobar@test.com'] }, where_clause.missed_hash)

        User.create(name: :foobar, email: 'foobar@test.com')
        User.find(1) # write cache
        predicates = User.where(email: 'foobar@test.com').where_clause.send(:predicates)
        where_clause = ArCache::WhereClause.new(User, predicates)
        assert where_clause.cacheable?
        key = User.ar_cache_table.cache_key({ 'email' => 'foobar@test.com' }, ['email'])
        assert_equal({ User.ar_cache_table.primary_cache_key(1) => key }, where_clause.cache_hash)
        assert_equal({ key => 'foobar@test.com' }, where_clause.instance_variable_get(:@original_cache_hash))
      end
    end
  end
end
