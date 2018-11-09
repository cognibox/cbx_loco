# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "cbx_loco/version"

Gem::Specification.new do |s|
  s.name = "cbx_loco"
  s.version = CbxLoco::VERSION
  s.authors = ["Cognibox"]
  s.email = ["developer@cognibox.com"]

  s.summary = %q{Provides rake tasks to synchronize translation assets between the codebase and Loco.}
  s.description = <<-TEXT
- `rake i18n:extract` extracts assets from server and client code, and uploads them to Loco using the developer API.
- `rake i18n:import` Imports assets from Loco using developer API into server-specific files and client-specific files

CbxLoco requires configuration of a Loco API key
TEXT
  s.post_install_message = %q{Thanks for using CbxLoco! Remember to run rails generate cbx_loco:install}

  s.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # Allow parsing of PO files
  s.add_dependency "get_pomo", "~> 0.7.1"

  # Allow colors in console outputs
  s.add_dependency "colorize", "~> 0.8.1"

  s.add_dependency "rails", ">= 4.1", "<= 5.1"
  s.add_dependency "rest-client", "~> 1.6.7"
  s.add_dependency "rake", ">= 11.0", "<= 12.3.1"

  s.add_development_dependency "rspec", "~> 3.6"
end
