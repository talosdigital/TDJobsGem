# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'td/jobs/version'

Gem::Specification.new do |spec|

  spec.name          = "td-jobs"
  spec.version       = TD::Jobs::VERSION
  spec.authors       = ["David Castillo", "René Dávila", "Santiago Vanegas"]
  spec.email         = [
    "juandavid.castillo@talosdigital.com",
    "rene.davila@talosdigital.com",
    "santiago.vanegas@talosdigital.com"
  ]

  spec.summary       = "A Ruby wrapper for TDJobs."
  spec.homepage      = "https://github.com/talosdigital/TDJobsGem"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'httparty', '0.13.5'
  spec.add_dependency 'activesupport', '4.2.3'

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "faker"
end
