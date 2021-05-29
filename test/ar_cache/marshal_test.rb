# frozen_string_literal: true

require 'test_helper'

module ArCache
  describe Marshal do
    let(:user_table) { User.ar_cache_table }
    let(:empty_table) { Empty.ar_cache_table }

    it 'should include ArCache::Marshal' do
      assert_includes ArCache::Table.ancestors, ArCache::Marshal
    end

    it 'should respond to delegate methods' do
      assert_called(ArCache::Configuration, :expires_in) { user_table.expires_in }
      assert_called(ArCache, :dump_attributes) { user_table.dump_attributes }
      assert_called(ArCache, :load_attributes) { user_table.load_attributes }
    end

    describe '#delete' do
      it 'should return -1 when disable ArCache' do
        assert_not_called(ArCache, :delete_multi) do
          assert_equal(-1, empty_table.delete('test'))
        end
      end

      it 'should delete cache when enable ArCache' do
        assert_called(ArCache, :delete_multi) do
          assert_not_equal(-1, user_table.delete('test'))
        end
      end
    end

    describe '#write' do
      it 'should return -1 when disable ArCache' do
        assert_not_called(ArCache, :write) do
          assert_equal(-1, empty_table.write([Empty.first]))
        end
      end

      # it 'should write cache when enable ArCache' do
      #   assert_called(ArCache, :write_multi) do
      #     assert_not_equal -1, user_table.write([User.new.attributes])
      #   end
      # end
    end

    describe '#read' do
      let(:user1) { User.create(name: :foo, email: 'foo@test.com').reload }
      let(:user2) { User.create(name: :bar, email: 'bar@test.com').reload }
      let(:relation2) { User.where(email: [user1.email, user2.email]) }
      let(:relation3) { relation2.where(name: %w[foo foobar]) }
      let(:where_clause1) do
        predicates = User.where(email: user1.email).where_clause.send(:predicates)
        ArCache::WhereClause.new(User, predicates).tap(&:cacheable?)
      end
      let(:where_clause2) do
        predicates = User.where(email: [user1.email, user2.email]).where_clause.send(:predicates)
        ArCache::WhereClause.new(User, predicates).tap(&:cacheable?)
      end
      let(:where_clause3) do
        predicates = User.where(email: [user1.email, user2.email], name: %w[foo a]).where_clause.send(:predicates)
        ArCache::WhereClause.new(User, predicates).tap(&:cacheable?)
      end
      let(:where_clause4) do
        predicates = User.where(email: user1.email, useless: 1).where_clause.send(:predicates)
        ArCache::WhereClause.new(User, predicates).tap(&:cacheable?)
      end

      before { User.find(user1.id, user2.id) } # write cache

      describe 'select values' do
        it 'should return complete attributes records when select values is nil' do
          records = user_table.read(where_clause1)
          assert records.one?
          assert_equal user1.attributes, records.first.attributes
        end

        it 'should return select attributes records when select values is not nil' do
          records = user_table.read(where_clause1, %w[id name])
          assert records.one?
          assert_equal user1.attributes.slice('id', 'name'), records.first.attributes
        end
      end

      describe 'validate relation where values' do
        it 'should valid where values return correct records' do
          assert_equal 2, user_table.read(where_clause2).size
          assert_equal 1, user_table.read(where_clause3).size
        end

        describe 'should call #add_missed_values' do
          it 'should call #add_invalid_second_cache_key when wrony column is index column' do
            assert_called(where_clause3, :add_missed_values) do
              assert_called(where_clause3, :add_invalid_second_cache_key) do
                assert user_table.read(where_clause3).one?
              end
            end
          end

          it 'should not call #add_invalid_second_cache_key when wrony column is not index column' do
            assert_called(where_clause4, :add_missed_values) do
              assert_not_called(where_clause4, :add_invalid_second_cache_key) do
                assert_empty user_table.read(where_clause4)
              end
            end
          end
        end
      end
    end

    it '#detect_wrong_column' do
      assert_not User.ar_cache_table.send(:detect_wrong_column, { 'id' => 0 }, { 'id' => 0 })
      assert_not User.ar_cache_table.send(:detect_wrong_column, { 'id' => 0 }, { 'id' => [0] })
      assert_equal 'id', User.ar_cache_table.send(:detect_wrong_column, { 'id' => 0 }, { 'id' => 1 })
      assert_equal 'id', User.ar_cache_table.send(:detect_wrong_column, { 'id' => 0 }, { 'id' => [1] })
    end

    it '#instantiate' do
      user = User.ar_cache_table.send(:instantiate, User, 'useless' => nil)
      assert_not user.attributes.key?('useless')
    end
  end
end
