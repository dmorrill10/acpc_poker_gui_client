class PokerBotGenerator < Rails::Generators::NamedBase
   source_root File.expand_path('../templates', __FILE__)
   argument :execute_command, type: :string
   argument :arguments, type: :array, default: ['host', 'port']
   
   def generate_poker_bot
      template 'poker_bot.rb', "lib/bots/run_#{file_name}_bot.rb"
      print_instructions_on_updating_app
   end
  
   private
   
   # Make the string conform to the naming convention of a class
   def to_class_name
      class_name = name.to_s.capitalize
      class_name.gsub(/[_\s]+./) { |match| match = match[1,].capitalize }
   end
   
   def print_instructions_on_updating_app
      <<-EOS
In order to integrate this new bot into the app, you must "register" the bot
by adding an entry to the it's class name #{to_class_name}

EOS
   end
   
   def file_name
      name.underscore
   end
   
   def self.banner
      "rails generate poker_bot agent_name run_command arguments"
   end
   
   def self.print_usage
      self.class.help(Thor::Base.shell.new)
      exit
   end
end
