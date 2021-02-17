# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'pry' if ENV['DEBUG']
require 'ar_cache'
require 'sqlite3'
require 'database_cleaner'
require 'minitest/autorun'

require 'support/ar_cache_test_case'

module Minitest
  class Spec
    register_spec_type(//, ArCacheTestCase)
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
  config.tables_options = {
    users: {
      ignored_columns: [:useless]
    },
    identities: {
      disabled: true
    }
  }
end

# TODO: Auto perform lib/generators/ar_cache/templates/migrate/create_ar_cache_records.rb.tt
ActiveRecord::Base.connection.create_table(:ar_cache_records, force: :cascade) do |t|
  t.string  :table_name, null: false
  t.string  :table_md5, null: false, limit: 32, default: '0' * 32
  t.integer :version, null: false, default: 0
  t.integer :lock_version, null: false, default: 0
  t.string  :unique_indexes, limit: 1000
  t.string  :ignored_columns, limit: 1000

  t.timestamps null: false

  t.index :table_name, unique: true
end

require 'models/application_record'
require 'models/user'
require 'models/identity'
require 'models/account'
require 'models/book'
require 'models/animal'
require 'models/image'

ApplicationRecord.descendants.each(&:ar_cache_table) # Pre-initialized ArCache::Table
