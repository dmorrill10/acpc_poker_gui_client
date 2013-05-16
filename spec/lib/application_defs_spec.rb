require_relative '../spec_helper'

require 'application_defs'

describe ApplicationDefs do
  it '::bots' do
    [:two_player_nolimit, :two_player_limit].each do |game_def_key|
      ApplicationDefs.bots(game_def_key, ['tester', 'user']).should == [RunTestingBot]
      ApplicationDefs.bots(game_def_key, ['user', 'tester']).should == [RunTestingBot]
      ApplicationDefs.bots(game_def_key, ['tester', 'user', 'tester']).should == [RunTestingBot, RunTestingBot]
    end
  end
end