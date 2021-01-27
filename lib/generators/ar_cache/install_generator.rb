# frozen_string_literal: true

require 'rails/generators'

module ArCache
  module Generators # :nodoc: all
    class InstallGenerator < Rails::Generators::Base
      def create_initializer_file
        create_file "db/migrate/#{Time.now.to_i}_create_ar_cache_monitors.rb", <<-RUBY.strip_heredoc
          # frozen_string_literal: true

          class CreateArCacheMonitors < ActiveRecord::Migration[#{::ActiveRecord::VERSION::MAJOR}.#{::ActiveRecord::VERSION::MINOR}]
            def change
              create_table :ar_cache_monitors do |t|
                t.string  :table_name, null: false
                t.string  :version, null: false
                t.boolean :disabled
                t.string  :unique_indexes, limit: 1000
                t.string  :ignored_columns, limit: 1000

                t.index   :table_name, unique: true
              end
            end
          end
        RUBY

        create_file 'config/initializers/ar_cache.rb', <<-RUBY.strip_heredoc
          # frozen_string_literal: true

          # For more information, see: https://github.com/OuYangJinTing/ar_cache/README.md
          ArCache::Configuration.configure do |config|
            # Default: ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'unknwon'
            # config.env = String

            # Default: Rails.cache || ActiveSupport::Cache::MemoryStore.new
            # config.cache_store = ActiveSupport::Cache::Store

            # Default: { cache_key_prefix: 'arcache', expires_in: 1.week }
            # config.default_model_options = {
            #   disabled: Boolean, # Optional, default enabled ArCache
            #   cache_key_prefix: String,
            #   expires_in: Numeric
            # }

            # config.models_options = {
            #   table_name: {
            #     disabled: Boolean, # Optional, default enabled ArCache
            #     cache_key_prefix: String,
            #     expires_in: Numeric,
            #     unique_indexes: Array # The primary key is used by default
            #   }
            # }
          end
        RUBY
      end
    end
  end
end
