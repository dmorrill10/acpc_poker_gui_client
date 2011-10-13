require 'spec_helper'

describe NewGameController do

  describe "GET 'index'" do
    it "should be successful" do
      get 'index'
      response.should be_success
    end
  end

  describe "GET 'two_player_limit'" do
    it "should be successful" do
      get 'two_player_limit'
      response.should be_success
    end
  end

  describe "GET 'two_player_no_limit'" do
    it "should be successful" do
      get 'two_player_no_limit'
      response.should be_success
    end
  end

  describe "GET 'three_player_limit'" do
    it "should be successful" do
      get 'three_player_limit'
      response.should be_success
    end
  end

  describe "GET 'three_player_no_limit'" do
    it "should be successful" do
      get 'three_player_no_limit'
      response.should be_success
    end
  end

end
