# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'carpel/version'

Gem::Specification.new do |spec|
  spec.name          = "carpel"
  spec.version       = Carpel::VERSION
  spec.authors       = ["Richard Smith-Unna"]
  spec.email         = ["rds45@cam.ac.uk"]
  spec.summary       = %q{Bayesian sequence segmentation for Ruby.}
  spec.description   = %q{Ruby implementations of Bayesian sequence segmentation algorithms.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "shoulda"
  spec.add_development_dependency "turn"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
