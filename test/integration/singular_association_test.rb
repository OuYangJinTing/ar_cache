# frozen_string_literal: true

require 'test_helper'

describe ArCache, 'singular association' do
  before do
    @user = User.create(name: :foobar, email: 'foobar@gmail.com')
    @account = @user.create_account(username: :foobar, password: :foobar)
    @identity = @user.create_identity(number: '0' * 18)

    # Write cache
    User.find(@user.id)
    Account.find(@account.id)
    Identity.find(@identity.id)
  end

  describe 'belongs_to' do
    it 'should read cache query association model' do
      assert_queries(1) { @account.reload.user }
    end

    it 'should read cache preload association model' do
      assert_no_queries { Account.preload(:user).where(id: @account.id).first }
    end
  end

  describe 'has_one' do
    it 'should read cache query association model' do
      assert_queries(1) { @user.reload.account }
    end

    it 'should read cache preload association model' do
      assert_no_queries { User.preload(:account).where(id: @user.id).first }
    end
  end

  describe 'has_one through' do
    it 'should read cache query association model' do
      assert_queries(1) { @account.reload.identity }
    end

    it 'should read cache preload association model' do
      assert_no_queries { Account.preload(:identity).where(id: @account.id).first }
    end
  end
end
