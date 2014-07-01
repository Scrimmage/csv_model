# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'csv_model/version'

Gem::Specification.new do |spec|
  spec.name          = "csv_model"
  spec.version       = CSVModel::VERSION
  spec.authors       = ["Matthew Chadwick"]
  spec.email         = ["matthew.chadwick@gmail.com"]
  spec.summary       = %q{Utility library for importing CSV data.}
  spec.description   = %q{}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "3.0.0"
end
