
class RunTestingBot
   EXECUTE_COMMAND = File.expand_path('../testing_bot.rb', __FILE__)
   ARGUMENTS = [:port_number, :server, :millisecond_response_timeout]
   
   # Connect to an ACPC Dealer and play a match of poker.
   # @param [Hash] argument_hash Hash of bot run parameters. May
   #  include values for +port_number+, +server+, and +millisecond_response_timeout+.
   # @return [String] The command that will run this bot.
   def self.run_command(argument_hash)
      argument_string = ARGUMENTS.map do |arg_key|
         argument_hash[arg_key]
      end.join(" ").strip
      "#{EXECUTE_COMMAND} #{argument_string}"
   end
end
