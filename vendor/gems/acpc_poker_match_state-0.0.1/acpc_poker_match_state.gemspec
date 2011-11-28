# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "acpc_poker_match_state/version"

Gem::Specification.new do |s|
  s.name        = "acpc_poker_match_state"
  s.version     = AcpcPokerMatchState::VERSION
  s.authors     = ["Dustin Morrill"]
  s.email       = ["morrill@ualberta.ca"]
  s.homepage    = ""
  s.summary     = %q{ACPC Poker Match State}
  s.description = %q{Match state data manager.}
  
  s.add_development_dependency 'acpc_poker_types'

  s.rubyforge_project = "acpc_poker_match_state"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
