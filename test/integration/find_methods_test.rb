# frozen_string_literal: true

require 'test_helper'

describe ArCache, 'find methods' do
  before do
    @user = User.create(name: :foobar, email: 'foobar@gmail.com')
    @empty = Empty.create
  end

  describe 'should call ActiveRecord::Core method if disabled cache' do
    it '#find' do
      Empty.find(@empty.id) # Must warm up sql cache statement, otherwise it still called all.
      assert_not_called(Empty, :all) { Empty.find(@empty.id) }
    end

    it '#find_by' do
      Empty.find_by(id: @empty.id) # Must warm up sql cache statement, otherwise it still called all.
      assert_not_called(Empty, :all) { Empty.find_by(id: @empty.id) }
    end
  end

  describe 'should call ActiveRecord::FinderMethods method if enabled cache' do
    it '#find' do
      assert_called(User, :all, returns: User.all) { User.find(@user.id) }
    end

    it '#find_by' do
      assert_called(User, :all, returns: User.all) { User.find_by(id: @user.id) }
    end
  end
end
