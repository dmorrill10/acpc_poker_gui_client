require_relative '../spec_helper'

require 'application_defs'

describe ApplicationDefs do
  it '::bots' do
    [:two_player_nolimit, :two_player_limit].each do |game_def_key|
      ApplicationDefs.bots(game_def_key, ['Tester', 'User']).should == [RunTestingBot]
      ApplicationDefs.bots(game_def_key, ['User', 'Tester']).should == [RunTestingBot]
      ApplicationDefs.bots(game_def_key, ['Tester', 'User', 'Tester']).should == [RunTestingBot, RunTestingBot]
    end
  end
end