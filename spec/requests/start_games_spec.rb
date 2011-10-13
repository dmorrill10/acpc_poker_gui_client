require 'spec_helper'

describe "StartGames" do
  
  describe "GET root_path" do
    it "app. displays correct main index view" do
      visit root_path
      page.should have_content(I18n.t('start_game.index.title'))
      page.should have_button(I18n.t('start_game.index.new_game'))
      page.should have_button(I18n.t('start_game.index.join_game'))
    end
    
    it "'start new game' button goes to 'start new game' view" do
      visit root_path
      page.should click_button(I18n.t('start_game.index.new_game'))
      # Check that the 'start new game' view loads
    end
    
    it "'join game' button goes to 'join game' view" do
       visit root_path
       page.should click_button(I18n.t('start_game.index.join_game'))
       # Check that the 'join game' view loads
    end
  end
  
end
