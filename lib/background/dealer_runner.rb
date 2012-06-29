
# Local classes
require File.expand_path('../process_runner', __FILE__)

# Worker to run the ACPC dealer.
class AcpcDealerRunner
   
   # Starts an ACPC dealer instance with the given +dealer_arguments+.
   # @param [Array] dealer_arguments Arguments to the new dealer instance.
   # @raise (see ProcessRunner#initialize)
   def initialize(dealer_arguments)
      dealer_path = File.expand_path('../../../vendor/project_acpc_server/dealer', __FILE__)
      dealer_start_command = dealer_arguments.unshift(dealer_path.to_s).join(' ')

      @dealer = ProcessRunner.new dealer_start_command
   end
   
   # @return [String] A string from the dealer if there is one to be read and
   #  an empty string otherwise.
   # @raise (see ProcessRunner#gets)
   def dealer_string
      @dealer.gets
   end
end
