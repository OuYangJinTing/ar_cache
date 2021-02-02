# frozen_string_literal: true

require 'test_helper'

describe ArCache do
  it 'has a version number' do
    assert_not_nil ArCache::VERSION
  end

  it '#configure' do
    assert_respond_to ArCache, :configure
  end
end
