
# Local modules
require File.expand_path('../../../../application_defs', __FILE__)

# Local mixins
require File.expand_path('../../../../mixins/easy_exceptions', __FILE__)
require File.expand_path('../../../../mixins/socket_with_ready_methods', __FILE__)


# Communication service to the ACPC Dealer.
# It acts solely as an abstraction of the communication protocal and
# implements the main Ruby communication interface through 'gets' and 'puts'
# methods.
class AcpcDealerCommunicator
   include ApplicationDefs
   
   exceptions :acpc_dealer_connection_error, :put_to_acpc_dealer_error, :get_from_acpc_dealer_error
   
   # @param [Integer] port The port on which to connect to the dealer.
   # @param [String] host_name The host on which the dealer is running.
   # @raise AcpcDealerConnectionError, PutToAcpcDealerError
   def initialize(port, host_name = 'localhost')
      begin         
         @dealer_socket = TCPSocket.new(host_name, port)
         send_version_string_to_dealer
      rescue PutToAcpcDealerError
         raise
      rescue
         handle_error AcpcDealerConnectionError, "Unable to connect to the dealer on #{host_name} through port #{port}"
      end
   end

   # Closes the connection to the dealer.
   def close
      @dealer_socket.close if @dealer_socket
   end

   # Retrieves a string from the dealer.
   #
   # @return [String] A string from the dealer.
   # @raise GetFromAcpcDealerError
   def gets
      begin
         raw_match_state = @dealer_socket.gets
      rescue
         handle_error GetFromAcpcDealerError, "Unable to get a string from the dealer"
      end
      raw_match_state.chomp
   end
   
   # Sends a given +string+ to the dealer.
   #
   # @param [String] string The string to send.
   # @raise PutsToAcpcDealerError
   def puts(string)      
      begin
         send_string_to_dealer string
      rescue
         handle_error PutToAcpcDealerError, "Unable to send the string, \"#{string}\", to the dealer"
      end
   end
   
   # (see TCPSocket#ready_to_write?)
   def ready_to_write?
      @dealer_socket.ready_to_write?
   end
   
   # (see TCPSocket#ready_to_read?)
   def ready_to_read?
      @dealer_socket.ready_to_read?
   end
   
   # The following methods are private ########################################
   private
   
   def handle_error(exception, message)
      close
      raise exception, message
   end
   
   def send_version_string_to_dealer
      version_string = "#{VERSION_LABEL}:#{VERSION_NUMBERS[:major]}.#{VERSION_NUMBERS[:minor]}.#{VERSION_NUMBERS[:revision]}"
      begin
         send_string_to_dealer version_string
      rescue
         handle_error PutToAcpcDealerError, "Unable to send version string, \"#{version_string}\", to the dealer"
      end
   end
   
   def send_string_to_dealer(string)
      begin
         @dealer_socket.puts string + TERMINATION_STRING
      rescue
         raise
      end
   end
end
