# frozen_string_literal: true

require 'test_helper'

describe ArCache, 'cache remove' do
  before do
    @user1 = User.create(name: :foobar1, email: 'foobar1@gmail.com')
    @user2 = User.create(name: :foobar2, email: 'foobar2@gmail.com')
    User.find(@user1.id, @user2.id) # Write cache
  end

  describe 'should remove cache when use unique index update or delete' do
    describe 'executed callbacks methods' do
      it 'update record' do
        assert_no_difference('ArCache::Record.get(User.table_name).version') do
          assert_no_queries { User.find(@user1.id) }

          @user1.update_attribute(:name, :foobar1_updated)

          assert_queries { User.find(@user1.id) }
          assert_no_queries { User.find(@user1.id) }
        end
      end

      it 'destroy record' do
        assert_no_difference('ArCache::Record.get(User.table_name).version') do
          assert_no_queries { User.find(@user1.id) }

          @user1.destroy

          assert_raises(ActiveRecord::RecordNotFound) { User.find(@user1.id) }
        end
      end
    end

    describe 'skip callbacks methods' do
      it 'update record' do
        assert_no_difference('ArCache::Record.get(User.table_name).version') do
          assert_no_queries { User.find(@user1.id) }

          User.where(id: @user1.id).update_all(name: :foobar1_updated)

          assert_queries { User.find(@user1.id) }
          assert_no_queries { User.find(@user1.id) }
        end
      end

      it 'destroy record' do
        assert_no_difference('ArCache::Record.get(User.table_name).version') do
          assert_no_queries { User.find(@user1.id) }

          User.where(id: @user1.id).delete_all

          assert_raises(ActiveRecord::RecordNotFound) { User.find(@user1.id) }
        end
      end
    end
  end

  it 'should update cache version when nont use unique index update or delete' do
    assert_difference('ArCache::Record.get(User.table_name).version') do
      User.update_all(updated_at: Time.current)
    end

    assert_difference('ArCache::Record.get(User.table_name).version') do
      User.delete_all
    end
  end
end
