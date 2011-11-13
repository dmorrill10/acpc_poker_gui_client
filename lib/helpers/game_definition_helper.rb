require File.expand_path('../models_helper', __FILE__)

# Assortment of static helper methods for the GameDefinition model.
module GameDefinitionHelper
   include ModelsHelper
   
   # Checks a given line from a game definition file for a game
   # definition name and returns the given default value unless there is a match.
   #
   # @param [String, #match] line A line from a game definition file.
   # @param [String] definition_name The name of the game definition that is
   #     being checked for in +line+.
   # @param default The default value to return in the case that the game
   #     definition name doesn't match +line+.
   # @return The game definition value in +line+ if +line+ contains the game definition
   #     referred to by +definition_name+, +default+ otherwise.
   def check_game_def_line_for_definition(line, definition_name, default)
      log "check_game_def_line_for_definition: line: #{line}, definition_name: #{definition_name}"
      
      if line.match(/^\s*#{definition_name}\s*=\s*([\d\s]+)/i)
         values = $1.chomp.split(/\s+/)
         (0..values.length-1).each do |i|
            values[i] = values[i].to_i
         end
      
         log "Values: #{values}"
      
         return flatten_if_single_element_array values
      end
      
      default
   end

   # Checks if the given line from a game definition file is informative or not
   # (in which case the line is either: a comment beginning with '#', empty, or
   # contains 'gamedef').
   #
   # @param line (see ModelsHelper#check_game_def_line_for_definition)
   # @return [Boolean] +true+ if the line is not informative, +false+ otherwise.
   def game_def_line_not_informative(line)
      log "game_def_line_not_informative"
      
      return_value = line_is_comment_or_empty? line
      return_value or line.match(/\s*gamedef\s*/i)
   end

end
