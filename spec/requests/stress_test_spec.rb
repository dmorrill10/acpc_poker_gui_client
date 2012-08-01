# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../../support/spec_helper', __FILE__)

require 'acpc_dealer'
require 'acpc_dealer_data'

describe 'ACPC Poker GUI Client', :type => :request do
  it 'works properly' do
    visit root_url
    page.should have_content('Match name')
  end
end