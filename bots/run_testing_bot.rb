# Dynamically produces a command to run a poker agent based on keyword
# arguments from a hash. Allows greater flexibility in the number, order,
# and appearance of arguments provided to agents than a script.
class RunTestingBot
  # Absolute path to the root of this project
  PROJECT_ROOT = File.expand_path('../..', __FILE__) << '/'

  # The command to execute to run this agent
  EXECUTE_COMMAND = PROJECT_ROOT << "bots/agent_scripts/testing_bot.rb"
  # The arguments this agent expects in the order specified by
  # the order of the elements of this array.
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
