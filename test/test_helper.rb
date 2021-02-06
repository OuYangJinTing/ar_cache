# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'pry' if ENV['DEBUG']
require 'ar_cache'
require 'sqlite3'
require 'database_cleaner'
require 'minitest/autorun'
require 'minitest/pride'

# Use rails style test
require 'active_support/testing/assertions'
require 'active_support/testing/method_call_assertions'
require 'rails/generators/testing/assertions'

module Minitest
  class Test
    include ActiveSupport::Testing::Assertions
    include ActiveSupport::Testing::MethodCallAssertions
    include Rails::Generators::Testing::Assertions

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

ArCache.configure do |config|
  config.select_disabled = false
end

# TODO: Auto perform lib/generators/ar_cache/templates/migrate/create_ar_cache_monitors.rb.tt
ActiveRecord::Base.connection.create_table(:ar_cache_monitors, force: :cascade) do |t|
  t.string  :table_name,      null: false
  t.integer :version,         null: false, default: 0
  t.integer :lock_version,    null: false, default: 0
  t.boolean :disabled,        null: false
  t.string  :unique_indexes,  limit: 1000

  t.index   :table_name, unique: true
end

require 'support/ar_cache_helper'

require 'models/application_record'
require 'models/user'
require 'models/identity'
require 'models/account'
require 'models/book'
require 'models/animal'
require 'models/image'

ArCache::Monitor.ar_cache_model
User.ar_cache_model
Image.ar_cache_model
Identity.ar_cache_model
Book.ar_cache_model
Animal.ar_cache_model
Cat.ar_cache_model
Dog.ar_cache_model
Account.ar_cache_model

User.create(name: :ouyang1, email: :ouyang1)
User.create(name: :ouyang2, email: :ouyang2)
User.create(name: :ouyang3, email: :ouyang3)
User.find(1).create_account(username: 1, password: 1)
User.find(1).create_identity(num: 1)

User.find(1, 2, 3)
User.ar_cache_model.delete(User.find(3))
User.where(name: %i[ouyang1 ouyang3], status: 0).to_a
User.includes(:account, :identity).where(id: 1).to_a
User.find(1).account
Account.find(1).user
Account.find(1).identity
