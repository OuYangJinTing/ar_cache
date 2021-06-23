# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'pry' if ENV['DEBUG']
require 'ar_cache'
require 'sqlite3'
require 'database_cleaner'
require 'minitest/autorun'
require 'support/test_case'

Minitest::Spec.register_spec_type(//, ArCache::TestCase)

ActiveRecord::Base.logger = Logger.new($stdout) if ENV['DEBUG']
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

ArCache.configure do |config|
  config.cache_store = ActiveSupport::Cache::RedisCacheStore.new if ENV['CACHE_MODE'] == 'redis'
  config.cache_lock = true
  config.select_disabled = false
  config.tables_options = {
    empties: {
      disabled: true,
      unique_indexes: 'mark'
    }
  }
end

require 'models/application_record'
require 'models/user'
require 'models/identity'
require 'models/account'
require 'models/book'
require 'models/animal'
require 'models/image'
require 'models/plan'
require 'models/empty'
