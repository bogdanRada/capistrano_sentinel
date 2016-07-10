require 'rubygems'
require 'bundler'
require 'bundler/setup'

require 'base64'
require 'socket'
require 'fileutils'
require 'json'
require 'uri'
require 'digest/md5'
require 'openssl'
require 'forwardable'
require 'thread'
require 'monitor'

require 'websocket'

require_relative './capistrano_sentinel/classes/gem_finder'

Gem.find_files('capistrano_sentinel/initializers/active_support/**/*.rb').each { |path| require path }

Gem.find_files('capistrano_sentinel/initializers/core_ext/**/*.rb').each { |path| require path }
Gem.find_files('capistrano_sentinel/helpers/**/*.rb').each { |path| require path }
Gem.find_files('capistrano_sentinel/classes/**/*.rb').each { |path| require path }

if CapistranoSentinel::GemFinder.fetch_gem_version('bundler')
  require_relative './capistrano_sentinel/patches/bundler'
end

if CapistranoSentinel::GemFinder.fetch_gem_version('rake')
  require_relative './capistrano_sentinel/patches/rake'
end

if CapistranoSentinel::GemFinder.capistrano_version_2?
  require_relative './capistrano_sentinel/patches/capistrano2'
end
