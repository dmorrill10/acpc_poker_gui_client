
# Local classes
require File.expand_path('../process_runner', __FILE__)

# Worker to run autonomous agents (bots).
class BotRunner
   
   # Starts a bot.
   # @param [String] bot_start_command The command to run the bot.
   # @raise (see ProcessRunner#initialize)
   def initialize(bot_start_command)         
      @bot = ProcessRunner.new bot_start_command
   end
   
   # @see ProcessRunner#gets
   def gets
      @bot.gets
   end
end
