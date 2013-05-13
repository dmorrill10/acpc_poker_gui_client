require_relative '../spec_helper'

require 'acpc_dealer'
require 'acpc_dealer_data'

describe 'ACPC Poker GUI Client', :type => :request do
  it 'works properly' do
    visit root_path
    page.should have_content('Match name')
  end
end