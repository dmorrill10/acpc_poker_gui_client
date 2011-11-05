
# Local mixins
require File.expand_path('../../mixins/socket_with_ready_methods', __FILE__)

# Worker to run the ACPC dealer.
class AcpcDealerRunner
   
   # @todo this worked before, but I'm not sure if it will work here
   trap("CLD") do
      @pipe_to_dealer.close
      @pipe_to_dealer = nil
      puts 'close!: Closed pipe'
      pid = Process.wait
      puts "Child pid #{pid}: terminated"
      exit
   end
      
   # Starts an ACPC dealer instance with the given +dealer_arguments+.
   # @param [Array] dealer_arguments Arguments to the new dealer instance.
   def initialize(dealer_arguments)
      dealer_path = File.expand_path('../../../external/project_acpc_server/dealer', __FILE__)
      dealer_start_command = dealer_arguments.unshift dealer_path.to_s
      
      begin
         puts "start_dealer!: dealer_start_command: #{dealer_start_command}"
         
         @pipe_to_dealer = IO.popen(dealer_start_command)
         
         puts "start_dealer!: @pipe_to_dealer.closed?: #{@pipe_to_dealer.closed?}"
      rescue
         raise
      end
   end
   
   # @return [String] A string from the dealer if there is one to be read and
   #  an empty string otherwise.
   def dealer_string
      if @pipe_to_dealer.ready_to_read?
         begin
            @pipe_to_dealer.gets
         rescue
            raise
         end
      else
         ''
      end
   end
end
