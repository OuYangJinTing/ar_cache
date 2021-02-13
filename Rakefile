# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
  t.warning = true
  t.options = '--warnings --color --pride --defer-output'
end

Rake::TestTask.new(:bench) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_benchmark.rb']
  t.verbose = true
  t.warning = true
  t.options = '--verbose --warnings --color --pride'
end

require 'rubocop/rake_task'

RuboCop::RakeTask.new

task default: %i[test rubocop]
