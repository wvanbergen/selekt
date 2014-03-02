# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'selekt/version'

Gem::Specification.new do |gem|
  gem.name          = "selekt"
  gem.version       = Selekt::VERSION
  gem.authors       = ["Willem van Bergen"]
  gem.email         = ["willem@railsdoctors.com"]
  gem.description   = %q{A toolkit to work with the SQL language. Incluses a SQL parser, tree manipulations, and tools for testing and monitoring}
  gem.summary       = %q{Toolkit to work with SQL queries}
  gem.homepage      = "https://github.com/wvanbergen/selekt"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency('rake')
  gem.add_development_dependency('minitest', '~> 5')

  gem.add_runtime_dependency('treetop')
end
