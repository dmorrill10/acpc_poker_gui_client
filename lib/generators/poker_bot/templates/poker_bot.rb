
class Run<%= to_class_name %>Bot
   EXECUTE_COMMAND = "<%= execute_command %>"
   ARGUMENTS = <%= arguments.map { |arg| arg.to_sym } %>
   
   # Connect to an ACPC Dealer and play a match of poker.
   # @param [Hash] argument_hash Hash of bot run parameters. Must
   #  include values for <%= "+#{arguments.join("+ +")}+." %>
   # @return [String] The command that will run this bot.
   def self.run_command(argument_hash)
      argument_string = ARGUMENTS.map do |arg_key|
         argument_hash[arg_key]
      end.join(" ").strip
      "#{EXECUTE_COMMAND} #{argument_string}"
   end
end
