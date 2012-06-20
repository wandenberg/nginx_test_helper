# -*- encoding: utf-8 -*-
require File.expand_path('../lib/nginx_test_helper/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Wandenberg Peixoto"]
  gem.email         = ["wandenberg@gmail.com"]
  gem.description   = %q{A collection of helper methods to test your nginx module.}
  gem.summary       = %q{A collection of helper methods to test your nginx module.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "nginx_test_helper"
  gem.require_paths = ["lib"]
  gem.version       = NginxTestHelper::VERSION

  gem.add_dependency "popen4"

  gem.add_development_dependency(%q<rspec>, [">= 2.10.0"])
  gem.add_development_dependency(%q<debugger>, [">= 1.1.3"])
  gem.add_development_dependency(%q<simplecov>, [">= 0.0.1"]) if RUBY_VERSION > "1.9.0"
end
