# encoding: utf-8
require File.expand_path('../lib/version', __FILE__)
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
    # require 'json'
    # puts JSON.pretty_generate(ENV.to_hash)
    if ENV['BUNDLE_GEMFILE'] =~ /gemfiles/
      appraisal_name = ENV['BUNDLE_GEMFILE'].scan(/rails\_(.*)\.gemfile/).flatten.first
      command_prefix = "appraisal rails-#{appraisal_name}"
      exec ("#{command_prefix} bundle install && #{command_prefix} bundle exec rspec && bundle exec rake coveralls:push ")
    else
      exec(' bundle exec appraisal install && bundle exec rake appraisal spec && bundle exec rake coveralls:push')
   end
  else
    exec('bundle exec appraisal install && bundle exec rake appraisal spec')
  end
end
