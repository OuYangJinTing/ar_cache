# frozen_string_literal: true

require 'active_support/testing/method_call_assertions'
require 'active_support/testing/stream'

# This class is based on ActiveRecord::TestCase modified.
module ArCache
  module Spec
    extend ActiveSupport::Concern

    included do
      extend Minitest::Spec::DSL
      TYPES = Minitest::Spec::DSL::TYPES # rubocop:disable Lint/ConstantDefinitionInBlock
    end

    def initialize(name)
      super
      Thread.current[:current_spec] = self
    end

    module ClassMethods
      def current
        Thread.current[:current_spec]
      end
    end
  end

  class TestCase < ActiveSupport::TestCase
    include ActiveSupport::Testing::MethodCallAssertions
    include ActiveSupport::Testing::Stream
    include Spec

    # parallelize(workers: :number_of_processors, with: :threads)

    self.test_order = :random

    def setup
      ArCache.clear
    end

    def teardown
      SQLCounter.clear_log
    end

    def capture_sql
      ::ActiveRecord::Base.connection.materialize_transactions
      SQLCounter.clear_log
      yield
      SQLCounter.log.dup
    end

    def assert_sql(*patterns_to_match, &block)
      capture_sql(&block)
    ensure
      failed_patterns = []
      patterns_to_match.each do |pattern|
        failed_patterns << pattern unless SQLCounter.log_all.any?(pattern)
      end
      assert_empty failed_patterns, "Query pattern(s) #{failed_patterns.map(&:inspect).join(', ')} not found.#{SQLCounter.log.empty? ? '' : "\nQueries:\n#{SQLCounter.log.join("\n")}"}" # rubocop:disable Layout/LineLength
    end

    def assert_queries(num = 1, options = {})
      ignore_none = options.fetch(:ignore_none) { num == :any }
      ::ActiveRecord::Base.connection.materialize_transactions
      SQLCounter.clear_log
      x = yield
      the_log = ignore_none ? SQLCounter.log_all : SQLCounter.log
      if num == :any
        assert_operator the_log.size, :>=, 1, '1 or more queries expected, but none were executed.'
      else
        mesg = "#{the_log.size} instead of #{num} queries were executed.#{the_log.empty? ? '' : "\nQueries:\n#{the_log.join("\n")}"}" # rubocop:disable Layout/LineLength
        assert_equal num, the_log.size, mesg
      end
      x
    end

    def assert_no_queries(options = {}, &block)
      options.reverse_merge! ignore_none: true
      assert_queries(0, options, &block)
    end

    def assert_column(model, column_name, msg = nil)
      assert has_column?(model, column_name), msg # rubocop:disable Minitest/AssertWithExpectedArgument
    end

    def assert_no_column(model, column_name, msg = nil)
      assert_not has_column?(model, column_name), msg
    end

    def has_column?(model, column_name) # rubocop:disable Naming/PredicateName
      model.reset_column_information
      model.column_names.include?(column_name.to_s)
    end

    def with_has_many_inversing
      old = ::ActiveRecord::Base.has_many_inversing
      ::ActiveRecord::Base.has_many_inversing = true
      yield
    ensure
      ::ActiveRecord::Base.has_many_inversing = old
    end

    def reset_callbacks(klass, kind)
      old_callbacks = {}
      old_callbacks[klass] = klass.send("_#{kind}_callbacks").dup
      klass.subclasses.each do |subclass|
        old_callbacks[subclass] = subclass.send("_#{kind}_callbacks").dup
      end
      yield
    ensure
      klass.send("_#{kind}_callbacks=", old_callbacks[klass])
      klass.subclasses.each do |subclass|
        subclass.send("_#{kind}_callbacks=", old_callbacks[subclass])
      end
    end

    def savepoint
      ::ActiveRecord::Base.connection.begin_transaction(joinable: false)
      yield
    ensure
      ::ActiveRecord::Base.connection.rollback_transaction
    end

    def current_adapter?(*types)
      types.any? do |type|
        ::ActiveRecord::ConnectionAdapters.const_defined?(type) &&
          ::ActiveRecord::Base.connection.is_a?(::ActiveRecord::ConnectionAdapters.const_get(type))
      end
    end

    def in_memory_db?
      current_adapter?(:SQLite3Adapter) && ::ActiveRecord::Base.connection_pool.db_config.database == ':memory:'
    end

    def assert_no_cache(type, &block)
      raise ArgumentError, 'type must be read\write\delete' unless %i[read write delete].include?(type.to_sym)

      assert_not_called(ArCache::Configuration.cache_store, type) do
        assert_not_called(ArCache::Configuration.cache_store, "#{type}_multi", &block)
      end
    end
  end

  class PostgreSQLTestCase < TestCase
    def self.run(*args)
      super if current_adapter?(:PostgreSQLAdapter)
    end
  end

  class Mysql2TestCase < TestCase
    def self.run(*args)
      super if current_adapter?(:Mysql2Adapter)
    end
  end

  class SQLite3TestCase < TestCase
    def self.run(*args)
      super if current_adapter?(:SQLite3Adapter)
    end
  end

  class SQLCounter
    class << self
      attr_accessor :ignored_sql, :log, :log_all

      def clear_log
        self.log = []
        self.log_all = []
      end
    end

    clear_log

    def call(_name, _start, _finish, _message_id, values)
      return if values[:cached]

      sql = values[:sql]
      self.class.log_all << sql
      self.class.log << sql unless %w[SCHEMA TRANSACTION].include? values[:name]
    end
  end

  ActiveSupport::Notifications.subscribe('sql.active_record', SQLCounter.new)
end
