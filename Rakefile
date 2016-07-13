# encoding: utf-8
require 'rubygems'
require 'bundler/setup'
require 'bundler/gem_tasks'
require 'appraisal'
require 'rspec/core/rake_task'
require 'coveralls/rake/task'
Coveralls::RakeTask.new

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts 'Run `bundle install` to install missing gems'
  exit e.status_code
end
require 'rake'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = ['--backtrace '] if ENV['DEBUG']
  spec.verbose = true
end

desc 'Default: run the unit tests.'
task default: [:all]

desc 'Test the plugin under all supported Rails versions.'
task :all do |_t|
  if ENV['TRAVIS']
    exec('bundle exec rake  spec && bundle exec rake coveralls:push')
  else
    exec('bundle exec rake spec')
  end
end

task :docs do
  exec('bundle exec inch --pedantic && bundle exec yard --list-undoc')
end
