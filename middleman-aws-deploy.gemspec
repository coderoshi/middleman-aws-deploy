# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "middleman-aws-deploy/version"

Gem::Specification.new do |s|
  s.name        = "middleman-aws-deploy"
  s.version     = Middleman::AWSDeploy::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Eric Redmond"]
  s.email       = ["eric.redmond@gmail.com"]
  s.homepage    = "https://github.com/coderoshi/middleman-aws-deploy"
  s.summary     = %q{Deploy to AWS with Middleman}
  s.description = %q{Adds S3 deploy and Cloudfront invalidation support to the Middleman build toolchain}

  s.rubyforge_project = "middleman-aws-deploy"

  s.files         = `git ls-files -z`.split("\0")
  s.test_files    = `git ls-files -z -- {fixtures,features}/*`.split("\0")
  s.require_paths = ["lib"]
  
  s.add_dependency("middleman-core", [">= 3.0.0", "< 3.2"])
  s.add_dependency("ruby-hmac", ["~> 0.4.0"])
  s.add_dependency("parallel", ["~> 0.6.1"])
  s.add_dependency("fog", ["~> 1.8.0"])
  s.add_dependency("progressbar", ["~> 0.12.0"])
end
