# -*- encoding: utf-8 -*-

$:.push File.expand_path("../lib", __FILE__)
require "tuppari/version"

Gem::Specification.new do |s|
  s.name = "tuppari"
  s.version = Tuppari::VERSION
  s.authors = ["Kazuhiro Sera"]
  s.email = ["seratch@gmail.com"]
  s.homepage = "https://github.com/tuppari/tuppari-ruby"
  s.summary = %q{Tuppari client for Ruby}
  s.description = %q{Tuppari is an experimental implementation of unbreakable message broadcasting system using WebSocket and Amazon Web Services by @hakobera.}

  s.rubyforge_project = "tuppari"

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.required_ruby_version = '>= 1.9.0'

end

