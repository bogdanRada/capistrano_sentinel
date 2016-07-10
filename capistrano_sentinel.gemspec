require File.expand_path("../lib/capistrano_sentinel/version", __FILE__)

Gem::Specification.new do |s|
  s.name = "capistrano_sentinel"
  s.version     = CapistranoSentinel.gem_version
  s.platform    = Gem::Platform::RUBY
  s.summary = "\"capistrano_sentinel\""
  s.email       = "raoul_ice@yahoo.com"
  s.homepage = "http://github.com/bogdanRada/capistrano_sentinel"
  s.description = "\"Handles capistrano deploy in parallel.\""
  s.authors     = ["bogdanRada"]

  s.date = Date.today

  s.licenses = ["MIT"]
  s.files = `git ls-files`.split("\n")
  s.test_files = s.files.grep(/^(spec)/)
  s.require_paths = ["lib"]
  s.required_ruby_version = '>= 1.9'


  s.add_dependency 'websocket'


end
