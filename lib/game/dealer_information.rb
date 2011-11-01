
# Information about a dealer instance.
class DealerInformation  
   # @return [String] The host name of the dealer associated with this table.
   attr_reader :host_name
   
   # @return [Integer] The port number of the dealer associated with this table.
   attr_reader :port_number
   
   def initialize(host_name, port_number)
      @host_name = host_name
      @port_number = port_number
   end
end
