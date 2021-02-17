# frozen_string_literal: true

require 'test_helper'

describe ArCache, 'query methods' do
  before do
    @user1 = User.create(name: :foobar1, email: 'foobar1@gmail.com')
    @user2 = User.create(name: :foobar2, email: 'foobar2@gmail.com')
    @plan  = @user1.plans.create(begin_date: Time.current)

    # Write cache
    User.find(@user1.id, @user2.id)
    Plan.find(@plan.id)
  end

  describe 'should read cache when use unique index query' do
    it 'single-column index' do
      assert_includes User.ar_cache_table.unique_indexes, ['email']

      assert_no_queries { User.where(email: @user1.email).first }
      assert_no_queries { User.where(email: [@user1.email, @user2.email]).to_a }
    end

    describe 'multi-column index' do
      it { assert_includes User.ar_cache_table.unique_indexes, %w[name status] }

      it 'where conditions exists single array' do
        assert_no_queries { User.where(name: @user1.name, status: @user1.status).first }
        assert_no_queries { User.where(name: [@user1.name, @user2.name], status: @user1.status).to_a }
      end

      it 'where conditions exists multiple array' do
        assert_queries { User.where(name: [@user1.name, @user2.name], status: User.statuses.values).to_a }
      end
    end

    it 'support different forms of value' do
      assert_no_queries { User.where(name: @user1.name, status: :active).first }
      assert_no_queries { User.where(name: @user1.name, status: 'active').first }
      assert_no_queries { User.where(name: @user1.name, status: 0).first }

      assert_no_queries { Plan.find_by(begin_date: @plan.begin_date) }
      assert_no_queries { Plan.find_by(begin_date: @plan.begin_date.to_s) }
    end
  end

  it 'should return correct records when use unique index and othen conditions query' do
    assert_no_queries { User.find_by(id: @user1.id, created_at: @user1.created_at) }
    assert_queries { User.find_by(id: @user1.id, created_at: Time.current) }

    assert_no_queries { User.find_by(id: @user1.id, created_at: [@user1.created_at, @user2.created_at]) }
    assert_queries { User.find_by(id: [@user1.id, @user2.id], created_at: [@user1.created_at, Time.current]) }
  end
end
