# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'pry' if ENV['DEBUG']
require 'ar_cache'
require 'sqlite3'
require 'database_cleaner'
require 'minitest/autorun'
require 'minitest/pride'

module Minitest
  class Test
    # These is copy from ActiveSupport::TestCase
    alias assert_raise           assert_raises
    alias assert_not_empty       refute_empty
    alias assert_not_equal       refute_equal
    alias assert_not_in_delta    refute_in_delta
    alias assert_not_in_epsilon  refute_in_epsilon
    alias assert_not_includes    refute_includes
    alias assert_not_instance_of refute_instance_of
    alias assert_not_kind_of     refute_kind_of
    alias assert_no_match        refute_match
    alias assert_not_nil         refute_nil
    alias assert_not_operator    refute_operator
    alias assert_not_predicate   refute_predicate
    alias assert_not_respond_to  refute_respond_to
    alias assert_not_same        refute_same
  end
end

module ActiveSupport
  class TestCase
    self.test_order = :random

    setup { DatabaseCleaner.start }

    teardown { DatabaseCleaner.clean }
  end
end

module ActiveRecord
  class Base
    self.logger = Logger.new($stdout) if ENV['DEBUG']
    establish_connection(adapter: 'sqlite3', database: ':memory:')
  end
end

ArCache::Configuration.configure do |config|
  # ...
end

require 'support/ar_cache_helper'

require 'models/application_record'
require 'models/ar_cache/monitor'
require 'models/user'
require 'models/book'
require 'models/animal'
require 'models/image'
