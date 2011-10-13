require 'spec_helper'
require 'socket'

describe DealerCommunication do
   before(:each) do
      start_test_connection 0
      @client_connection.gets.chomp.should == "#{VERSION_LABEL}:#{VERSION_NUMBERS[:major]}.#{VERSION_NUMBERS[:minor]}.#{VERSION_NUMBERS[:revision]}\\r\\n"
   end
  
   after(:each) do
      @patient.close
      @client_connection.close
   end
   
   it 'lets the caller know if there is not new input from the dealer' do
      @patient.ready_to_read?.should be false
   end
   
   it 'lets the caller know if there is new input from the dealer' do
      @client_connection.puts "New input"
      @patient.ready_to_read?.should be true
   end
   
   it 'lets the caller know if the dealer is ready to receive data' do
      @patient.ready_to_write?.should be true
   end
   
   it "properly sends a match state string through it's connection" do
      match_state = MATCH_STATE_LABEL + ":1:0:|" + arbitrary_hole_card_hand
      @patient.send_match_state_string_to_dealer match_state
      
      @client_connection.gets.chomp.should == match_state + "\\r\\n"
   end
   
   def start_test_connection(port)
      fake_dealer = TCPServer.open(port)
      @patient = DealerCommunication.new fake_dealer.addr[1]
      
      @client_connection = fake_dealer.accept
   end
end