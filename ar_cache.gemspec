# frozen_string_literal: true

require_relative 'lib/ar_cache/version'

Gem::Specification.new do |spec|
  spec.name          = 'ar_cache'
  spec.version       = ArCache::VERSION
  spec.authors       = ['OuYangJinTing']
  spec.email         = ['ouyangshi95@foxmail.com']

  spec.summary       = 'An modern cacheing library for ActiveRecord inspired by cache-money and second_level_cache.'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/OuYangJinTing/ar_cache'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.0.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/OuYangJinTing/ar_cache.git'
  spec.metadata['changelog_uri'] = 'https://github.com/OuYangJinTing/ar_cache/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'activerecord', '>= 6.1', '< 7'
  spec.add_runtime_dependency 'oj', '>= 3', '< 4'

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
