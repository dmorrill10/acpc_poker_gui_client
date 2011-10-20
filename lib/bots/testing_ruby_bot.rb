
# Local modules
#require 'models_helper'

class TestingRubyBot # TODO < I_Bot
   #include ModelsHelper
   
   trap("CLD") do
      pid = Process.wait
      puts "Child pid #{pid}: terminated"
      exit
   end
   
   def self.connect_to_dealer!(arguments)
      #log "connect_to_dealer!: #{arguments}"
      
#      fake_acpc_client_path = Rails.root.join('external', 'fake_acpc_server', 'fake_acpc_client.rb')
      fake_acpc_client_path = '/home/dmorrill/workspace/acpcpokerguiclient/external/fake_acpc_server/fake_acpc_client.rb'
      
      puts "connect_to_dealer!: fake_acpc_client_path: #{fake_acpc_client_path}"
      #log "connect_to_dealer!: fake_acpc_client_path: #{fake_acpc_client_path}"
      
      #TODO Should a system, exec, or pipe be done here?
      exec("#{fake_acpc_client_path} #{arguments[:port_number]} > outputFromFakeClient.txt") if fork == nil
   end
end
