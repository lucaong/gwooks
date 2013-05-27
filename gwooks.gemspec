# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gwooks/version'

Gem::Specification.new do |gem|
  gem.name          = "gwooks"
  gem.version       = Gwooks::VERSION
  gem.authors       = ["Luca Ongaro"]
  gem.email         = ["lukeongaro@gmail.com"]
  gem.description   = "A DSL for quickly creating endpoints for GitHub post-receive webhooks."
  gem.summary       = "A DSL for quickly creating endpoints for GitHub post-receive webhooks. It provides methods for executing blocks of code when GitHub posts a payload matching some conditions in response to a code push."
  gem.homepage      = "https://github.com/lucaong/gwooks"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_dependency("json")
  gem.add_dependency("sinatra")
  gem.add_development_dependency("rake")
  gem.add_development_dependency("rspec")
  gem.add_development_dependency("rack-test")
end
