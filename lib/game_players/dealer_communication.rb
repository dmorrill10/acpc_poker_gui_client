# System classes
require "socket"

# Local modules
require 'application_defs'

# Class that provides a communication service to the dealer.
class DealerCommunication
   include ApplicationDefs

   # @param port [Integer] port The port on which to connect to the dealer.
   # @raise 'Unable to connect to dealer' exception.
   def initialize(port)
      begin
         begin
            host_name = Socket::gethostname
         rescue
            raise "Unable to get host name"
         end
         
         host_name.chomp!

         @dealer_socket = TCPSocket.new(host_name, port)

         send_version_string_to_dealer
      rescue
         close
         raise "Unable to connect to dealer"
      end
   end

   # Close the connection to the dealer.
   def close
      @dealer_socket.close if @dealer_socket
   end

   # Retrieves a match state string from the dealer.
   #
   # @return [String] A match state string from the dealer.
   # @raise 'Unable to get a match state string from the dealer' exception.
   def get_match_state_string_from_dealer
      begin
         raw_match_state = @dealer_socket.gets
      rescue
         close
         raise "Unable to get a match state string from the dealer"
      end
      raw_match_state.chomp
   end
   
   # Sends a given match state string to the dealer.
   #
   # @param [String] match_state_string The match state string to send.
   # @raise 'Unable to send match state string "+match_state_string+" to the dealer' exception.
   def send_match_state_string_to_dealer(match_state_string)
      log "match_state_string: #{match_state_string}"
      
      begin
         send_string_to_dealer match_state_string
      rescue
         close
         raise "Unable to send match state string, \"#{match_state_string}\", to the dealer"
      end
   end
   
   # Checks if the socket is ready to be read from.
   # @return [Boolean] +true+ if the socket is ready to be read from, +false+ otherwise.
   def ready_to_read?
      read_array = [@dealer_socket]
      write_array = nil
      error_array = nil
      timeout = 1
      
      IO.select(read_array, write_array, error_array, timeout) != nil
   end
   
   # Checks if the socket is ready to be written to.
   #
   # @return [Boolean] +true+ if the socket is ready to be written to, +false+ otherwise.
   def ready_to_write?
      log "ready_to_write?"
      
      read_array = nil
      write_array = [@dealer_socket]
      error_array = nil
      timeout = 1
      
      IO.select(read_array, write_array, error_array, timeout) != nil
   end
   
   private
   
   def send_version_string_to_dealer
      version_string = "#{VERSION_LABEL}:#{VERSION_NUMBERS[:major]}.#{VERSION_NUMBERS[:minor]}.#{VERSION_NUMBERS[:revision]}"
      begin
         send_string_to_dealer version_string
      rescue
         close
         raise "Unable to send version string, \"#{version_string}\", to the dealer"
      end
   end
   
   def send_string_to_dealer(string)
      begin
         @dealer_socket.puts string + TERMINATION_STRING
      rescue
         close
         raise
      end
   end
end
