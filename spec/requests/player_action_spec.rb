require 'spec_helper'

describe "PlayerActions" do
  
  describe "GET game_home" do
    it "app. displays correct main game view" do
      visit game_home_path
      page.should have_content(I18n.t('player_actions.index.title'))
      page.should have_button(I18n.t('player_actions.index.leave'))
      page.should have_button(I18n.t('player_actions.index.bet'))
      page.should have_button(I18n.t('player_actions.index.call'))
      page.should have_button(I18n.t('player_actions.index.check'))
      page.should have_button(I18n.t('player_actions.index.fold'))
      page.should have_button(I18n.t('player_actions.index.raise'))
    end
  end
  
end
