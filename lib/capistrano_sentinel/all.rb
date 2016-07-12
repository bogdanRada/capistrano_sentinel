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
require 'logger'

require 'websocket'
require_relative './classes/gem_finder'

%w(initializers helpers classes).each do |folder_name|
  Gem.find_files("#{CapistranoSentinel::GemFinder.get_current_gem_name}/#{folder_name}/**/*.rb").each { |path| require path }
end

if !CapistranoSentinel::GemFinder.value_blank?(ENV[CapistranoSentinel::RequestHooks::ENV_KEY_JOB_ID])

  if CapistranoSentinel::GemFinder.fetch_gem_version('capistrano')
    if CapistranoSentinel::GemFinder.capistrano_version_2?
      require_relative './patches/capistrano2'
    else
      require_relative './patches/rake'
    end
  end
end
