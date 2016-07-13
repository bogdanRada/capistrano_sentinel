require File.expand_path("../lib/capistrano_sentinel/version", __FILE__)

Gem::Specification.new do |s|
  s.name = "capistrano_sentinel"
  s.version     = CapistranoSentinel.gem_version
  s.platform    = Gem::Platform::RUBY
  s.summary = "CapistranoSentinel is a simple ruby implementation that allows you to emit websocket events before a task is invoked by Capistrano."
  s.email       = "raoul_ice@yahoo.com"
  s.homepage = "http://github.com/bogdanRada/capistrano_sentinel"
  s.description = "CapistranoSentinel is a simple ruby implementation that allows you to emit websocket events before a task is invoked by Capistrano."
  s.authors     = ["bogdanRada"]

  s.date = Date.today

  s.licenses = ["MIT"]
  s.files = `git ls-files`.split("\n")
  s.test_files = s.files.grep(/^(spec)/)
  s.require_paths = ["lib"]
  s.required_ruby_version = '>= 2.0'


  s.add_dependency 'websocket'


end
