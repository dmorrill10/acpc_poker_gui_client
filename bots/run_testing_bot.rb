
class RunTestingBot
   PROJECT_ROOT = File.expand_path('../..', __FILE__) << '/'
   # REPLACE THIS LINE WITH THE COMMAND TO EXECUTE.
   # IF YOUR AGENT OR SCRIPT IS ON THE SAME MACHINE AS THIS
   # PROJECT, SIMPLY REPLACE "#{bots/testing_bot.rb}" WITH
   # THE PATH TO YOUR AGENT OR SCRIPT RELATIVE TO THIS
   # PROJECT'S ROOT DIRECTORY.
   EXECUTE_COMMAND = PROJECT_ROOT << "bots/agent_scripts/testing_bot.rb"
   ARGUMENTS = [:port_number, :server]

   # Connect to an ACPC Dealer and play a match of poker.
   # @param [Hash] argument_hash Hash of bot run parameters. May
   #  include values for +port_number+ and +server+.
   # @return [String] The command that will run this bot.
   def self.run_command(argument_hash)
      argument_string = ARGUMENTS.map do |arg_key|
         argument_hash[arg_key]
      end.join(" ").strip
      "#{EXECUTE_COMMAND} #{argument_string}"
   end
end
