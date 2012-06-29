
class RunUAlberta2011Bot
   EXECUTE_COMMAND = File.expand_path('~burch/nolimit_bot/run.sh', __FILE__)
   ARGUMENTS = [:server, :port_number]
   
   # Connect to an ACPC Dealer and play a match of poker.
   # @param [Hash] argument_hash Hash of bot run parameters. May
   #  include values for +game_def+ +server+ +port_number+ +player_object+ +player_arguments+.
   # @return [String] The command that will run this bot.
   def self.run_command(argument_hash)
      argument_string = ARGUMENTS.map do |arg_key|
         argument_hash[arg_key]
      end.join(" ").strip
      "#{EXECUTE_COMMAND} #{argument_string}"
   end
end
