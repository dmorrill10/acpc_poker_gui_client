# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "acpc_poker_types/version"

Gem::Specification.new do |s|
  s.name        = "acpc_poker_types"
  s.version     = AcpcPokerTypes::VERSION
  s.authors     = ["Dustin Morrill"]
  s.email       = ["morrill@ualberta.ca"]
  s.homepage    = ""
  s.summary     = %q{ACPC Poker Types }
  s.description = %q{Poker types that conform to the standards of the Annual Computer Poker Competition.}

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'mocha'
  
  s.rubyforge_project = "acpc_poker_types"

  s.files         = Dir.glob("lib/**/*") + Dir.glob("src/**/*") + %w(Rakefile acpc_poker_types.gemspec tasks.rb)
  s.test_files    = Dir.glob "spec/**/*"
  s.extensions    = Dir.glob 'src/ext/**/*.{c,h,rb}'
  s.require_paths = ["lib"]
end
