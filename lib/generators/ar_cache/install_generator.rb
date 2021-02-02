# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/migration'
require 'rails/generators/active_record/migration'

module ArCache
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      include ::ActiveRecord::Generators::Migration

      source_root File.expand_path('templates', __dir__)

      def copy_initializer_file
        copy_file 'configuration.rb', 'config/initializers/ar_cache.rb'

        migration_template 'migrate/create_ar_cache_monitors.rb', 'db/migrate/create_ar_cache_monitors.rb'
      end
    end
  end
end
