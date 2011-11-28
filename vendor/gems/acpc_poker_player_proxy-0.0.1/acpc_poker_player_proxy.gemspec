# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "acpc_poker_player_proxy/version"

Gem::Specification.new do |s|
  s.name        = "acpc_poker_player_proxy"
  s.version     = AcpcPokerPlayerProxy::VERSION
  s.authors     = ["Dustin Morrill"]
  s.email       = ["morrill@ualberta.ca"]
  s.homepage    = ""
  s.summary     = %q{ACPC Poker Player Proxy}
  s.description = %q{A smart proxy for a poker player that connects to the ACPC Dealer and manages match state data.}

  s.add_development_dependency 'acpc_poker_types'
  s.add_development_dependency 'acpc_poker_basic_proxy'
  s.add_development_dependency 'acpc_poker_match_state'
  
  s.rubyforge_project = "acpc_poker_player_proxy"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
