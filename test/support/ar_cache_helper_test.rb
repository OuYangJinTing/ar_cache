# frozen_string_literal: true

require 'test_helper'

describe ArCacheHelper do
  let(:user_model) { ArCache::Model.get(User) }

  it '#with_reset_model' do
    assert_not(user_model.unique_indexes.any? { |index| index == ['created_at'] })
    assert_not_includes User.ignored_columns, 'role'

    options = {
      disabled: !user_model.disabled?,
      cache_key_prefix: "new_#{user_model.cache_key_prefix}",
      expires_in: user_model.expires_in + 1.day,
      unique_indexes: (user_model.unique_indexes + [['created_at']]).sort_by(&:size),
      ignored_columns: User.ignored_columns + ['role']
    }

    ArCacheHelper.with_reset_model(User, **options) do
      reset_user_model = ArCache::Model.get(User)
      assert_includes User.ignored_columns, 'role'
      assert_equal options[:disabled],         reset_user_model.disabled
      assert_equal options[:cache_key_prefix], reset_user_model.cache_key_prefix
      assert_equal options[:expires_in],       reset_user_model.expires_in
      assert_equal options[:unique_indexes],   reset_user_model.unique_indexes
      assert_equal options[:ignored_columns],  reset_user_model.ignored_columns
    end

    new_user_model = ArCache::Model.get(User)
    assert_not_includes User.ignored_columns, 'role'
    assert_equal user_model.disabled,         new_user_model.disabled
    assert_equal user_model.cache_key_prefix, new_user_model.cache_key_prefix
    assert_equal user_model.expires_in,       new_user_model.expires_in
    assert_equal user_model.unique_indexes,   new_user_model.unique_indexes
    assert_equal user_model.ignored_columns,  new_user_model.ignored_columns
  end
end
