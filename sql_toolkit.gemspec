# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sql_toolkit/version'

Gem::Specification.new do |gem|
  gem.name          = "sql_toolkit"
  gem.version       = SQLToolkit::VERSION
  gem.authors       = ["Willem van Bergen"]
  gem.email         = ["willem@railsdoctors.com"]
  gem.description   = %q{A toolkit to work with the SQL language. Incluses a parser, and tools mor testing and monitoring}
  gem.summary       = %q{Toolkit to work with SQL queries}
  gem.homepage      = "https://github.com/wvanbergen/sql_toolkit"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency('rake')
  gem.add_development_dependency('minitest', '~> 5')
  gem.add_development_dependency('pg')

  gem.add_runtime_dependency('treetop')
end
