# frozen_string_literal: true
require 'capistrano_sentinel/all'

# module that holds the configuration
module CapistranoSentine
  def self.configure
    yield config
  end

  def self.config
    @config ||= CapistranoSentinel::Configuration.new
  end
end
