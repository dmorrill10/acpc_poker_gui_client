require 'spec_helper'
require 'socket'

# Local modules
require File.expand_path('../../../../../../lib/application_defs', __FILE__)
require File.expand_path('../../../../../support/model_test_helper', __FILE__)

describe AcpcDealerCommunicator do
   include ApplicationDefs
   include ModelTestHelper
   
   before(:each) do
      start_test_connection 0
      @client_connection.gets.chomp.should eq("#{VERSION_LABEL}:#{VERSION_NUMBERS[:major]}.#{VERSION_NUMBERS[:minor]}.#{VERSION_NUMBERS[:revision]}\\r\\n")
   end
  
   after(:each) do
      @patient.close
      @client_connection.close
   end
   
   describe "#ready_to_read?" do
      it 'lets the caller know if there is not new input from the dealer' do
         @patient.ready_to_read?.should be false
      end
   
      it 'lets the caller know if there is new input from the dealer' do
         @client_connection.puts "New input"
         @patient.ready_to_read?.should be true
      end
   end
   
   describe "#ready_to_write?" do
      it 'lets the caller know if the dealer is ready to receive data' do
         @patient.ready_to_write?.should be true
      end
   end
   
   describe "#puts" do
      it "properly sends actions to the dealer" do
         action = MATCH_STATE_LABEL + ":1:0:|" + arbitrary_hole_card_hand + ':c'
         @patient.puts action
         
         @client_connection.gets.chomp.should eq(action + "\\r\\n")
      end
   end
   
   describe "#gets" do
      it "properly receives matchstate strings from the dealer" do
         matchstate_string = MATCH_STATE_LABEL + ":1:0:|" + arbitrary_hole_card_hand
         @client_connection.puts matchstate_string
         @patient.gets.should eq(matchstate_string)
      end
   end
   
   def start_test_connection(port)
      fake_dealer = TCPServer.open(port)
      @patient = AcpcDealerCommunicator.new fake_dealer.addr[1]
      
      @client_connection = fake_dealer.accept
   end
end
