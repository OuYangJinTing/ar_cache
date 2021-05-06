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

DEFAULT_CONFIGURATION = ArCache::Configuration.dup
ArCache.configure do |config|
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
