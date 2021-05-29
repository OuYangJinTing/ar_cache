# frozen_string_literal: true

require 'rails/generators'

module ArCache
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      def copy_initializer_file
        copy_file 'configuration.rb', 'config/initializers/ar_cache.rb'
      end
    end
  end
end
