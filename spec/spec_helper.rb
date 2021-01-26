# frozen_string_literal: true

require 'pry' if ENV['DEBUG']
require 'ar_cache'
require 'sqlite3'
require 'database_cleaner'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.order = :random

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

ActiveRecord::Base.logger = Logger.new($stdout) if ENV['DEBUG']
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

ArCache::Configuration.configure do |config|

end

require 'models/application_record'
require 'models/ar_cache/monitor'
require 'models/user'
require 'models/book'
require 'models/animal'
require 'models/image'
