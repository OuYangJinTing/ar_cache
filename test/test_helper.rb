# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'pry' if ENV['DEBUG']
require 'ar_cache'
require 'sqlite3'
require 'database_cleaner'
require 'minitest/autorun'
require 'minitest/reporters'

Minitest::Reporters.use!

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

require 'models/application_record'
require 'models/ar_cache/monitor'
require 'models/user'
require 'models/book'
require 'models/animal'
require 'models/image'
