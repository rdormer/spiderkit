# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'version'

Gem::Specification.new do |spec|
  spec.name          = "spiderkit"
  spec.version       = Spider::VERSION
  spec.authors       = ["Robert Dormer"]
  spec.email         = ["rdormer@gmail.com"]
  spec.description   = %q{Spiderkit library for basic spiders and bots}
  spec.summary       = %q{Basic toolkit for writing web spiders and bots}
  spec.homepage      = "http://github.com/rdormer/spiderkit"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rspec",  "~> 3.4.0"
  spec.add_development_dependency "rake"

  spec.add_dependency "bloom-filter", "~> 0.2.0"
end
