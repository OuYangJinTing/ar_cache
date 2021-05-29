# frozen_string_literal: true

require 'test_helper'

module ArCache
  describe Query do
    let(:query) { ArCache::Query.new(User.all) }

    it 'should respond to methods' do
      assert_respond_to query, :relation
      assert_respond_to query, :table
      assert_respond_to query, :where_clause
    end

    describe '#exec_queries' do
      let(:user1) { User.create(name: :foo, email: 'foo@test.com') }
      let(:user2) { User.create(name: :bar, email: 'bar@test.com') }

      before { User.find(user1.id, user2.id) } # write cache

      it 'shodul not called #exec_queries_cacheable? when relation is contradiction' do
        assert_not_called_on_instance_of(ArCache::Query, :exec_queries_cacheable?) do
          ArCache::Query.new(User.where(id: [])).exec_queries
        end
      end

      it 'shodul load' do
        User.ar_cache_table.delete(user2.id)

        capture_sql do
          users = User.includes(:books).where(id: [user1.id, user2.id]).readonly!.load
          assert_equal 2, users.size
          assert_equal 2, ArCache::SQLCounter.log.size
          assert_includes ArCache::SQLCounter.log.first, 'WHERE "users"."id" ='
          assert_includes ArCache::SQLCounter.log.last, 'FROM "books"'
          assert users.all?(&:readonly?)
        end
      end

      describe '#exec_queries_cacheable?' do
        describe '#select_values_cacheable?' do
          let(:relation) { User.where(id: [user2.id, user1.id]) }

          it 'select_values noexists' do
            assert ArCache::Query.new(relation).exec_queries_cacheable?
          end

          it 'select_values are table columns' do
            assert ArCache::Query.new(relation.select(:name, :email)).exec_queries_cacheable?
          end

          it 'select_values are other' do
            assert_not ArCache::Query.new(relation.select('MAX(id)')).exec_queries_cacheable?
          end
        end

        describe '#order_values_cacheable?' do
          describe 'mulit order_values' do
            let(:relation) { User.order(:id, books_count: :desc) }

            it 'single query' do
              assert ArCache::Query.new(relation.where(id: user1.id)).exec_queries_cacheable?
            end

            it 'multi query' do
              assert_not ArCache::Query.new(relation.where(id: [user1.id, user2.id])).exec_queries_cacheable?

              # order_values noexists
              other_relation = relation.where(id: [user1.id, user2.id]).unscope(:order)
              assert ArCache::Query.new(other_relation).exec_queries_cacheable?
            end
          end

          describe 'single order_values' do
            let(:relation) { User.where(id: [user2.id, user1.id]) }

            it 'table column order' do
              assert ArCache::Query.new(relation.order(:created_at)).exec_queries_cacheable?
              assert ArCache::Query.new(relation.order('created_at DESC')).exec_queries_cacheable?
            end

            it 'other order' do
              assert_not ArCache::Query.new(relation.order('RANDOM()')).exec_queries_cacheable?
            end
          end
        end

        describe '#limit_value_cacheable?' do
          let(:relation) { User.limit(10) }

          it 'single query' do
            assert ArCache::Query.new(relation.where(id: user1.id)).exec_queries_cacheable?
          end

          it 'multi query' do
            assert_not ArCache::Query.new(relation.where(id: [user1.id, user2.id])).exec_queries_cacheable?

            # limit_value noexists
            other_relation = relation.where(id: [user1.id, user2.id]).unscope(:limit)
            assert ArCache::Query.new(other_relation).exec_queries_cacheable?
          end
        end

        describe 'other related' do
          let(:relation) { User.where(id: [user2.id, user1.id]) }

          before { assert ArCache::Query.new(relation).exec_queries_cacheable? }

          it 'from_clause exists' do
            assert_not ArCache::Query.new(relation.from(:books)).exec_queries_cacheable?
          end

          it 'eager_loading' do
            assert_not ArCache::Query.new(relation.eager_load(:books)).exec_queries_cacheable?
          end

          it 'offset_value exists' do
            assert_not ArCache::Query.new(relation.offset(1)).exec_queries_cacheable?
          end

          it 'left_outer_joins exists' do
            assert_not ArCache::Query.new(relation.left_outer_joins(:books)).exec_queries_cacheable?
          end

          it 'joins_values exists' do
            assert_not ArCache::Query.new(relation.joins(:books)).exec_queries_cacheable?
          end

          it 'group_values exists' do
            assert_not ArCache::Query.new(relation.group(:id)).exec_queries_cacheable?
          end

          it 'distinct_value exists' do
            assert_not ArCache::Query.new(relation.distinct).exec_queries_cacheable?
          end

          it 'lock_value exists' do
            assert_not ArCache::Query.new(relation.lock).exec_queries_cacheable?
          end

          it 'lock_value exists' do
            assert_not ArCache::Query.new(relation.skip_query_cache!).exec_queries_cacheable?
          end

          it 'disable ArCache' do
            assert_not ArCache::Query.new(Empty.where(id: [1, 2])).exec_queries_cacheable?
          end

          it 'transaction exists and updated table' do
            User.transaction do
              user1.touch
              user2.touch
              where_clause = ArCache::WhereClause.new(User, relation.where_clause.send(:predicates))
              assert where_clause.cacheable?
              assert_empty User.ar_cache_table.read(where_clause, nil)
            end
          end
        end
      end

      describe '#records_order' do
        let(:relation) { User.where(id: [user2.id, user1.id]) }

        it 'should depend with primary_key order when @order_name noexists' do
          users = ArCache::Query.new(relation).exec_queries
          assert_equal [user1, user2], users
        end

        it 'should depend with @order_name order when @order_name exists' do
          users = ArCache::Query.new(relation.order(:name)).exec_queries
          assert_equal [user2, user1], users
        end
      end
    end
  end
end
