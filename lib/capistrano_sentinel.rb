require 'capistrano_sentinel/all'

module CapistranoSentinel

  def self.configure
    yield config
  end

  def self.config
    @config ||= CapistranoSentinel::Configuration.new
  end
end
