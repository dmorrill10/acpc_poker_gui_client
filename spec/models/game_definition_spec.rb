require 'spec_helper'

describe GameDefinition do
   
   it "parses all available game definitions properly" do      
      GAME_DEFINITION_FILE_NAMES.values.each do |game_definition_file_name|
         patient = catch(:game_definition_error) do
            GameDefinition.new game_definition_file_name
         end
         patient.should be_a_kind_of GameDefinition
         matched = parsed_game_definitions_match_original_definitions? patient, game_definition_file_name
         matched.should == true
      end
   end
   
   def parsed_game_definitions_match_original_definitions?(patient, game_definition_file_name)
      game_definition_string = patient.to_s
      
      log "game_definition_string: #{game_definition_string}"
      
      game_definition_array = game_definition_string.split("\n")
      remaining_lines = []
      
      begin
         for_every_line_in_file game_definition_file_name do |definition|
            next if game_def_line_not_informative definition
            
            log "Past next if not informative with definition: #{definition}"
            
            remaining_lines << definition
            game_definition_array.each do |definition_from_game|
               log "Definition: #{definition}, definition_from_game: #{definition_from_game}"
               
               remaining_lines.delete definition if definition.match("^\s*#{definition_from_game}")
            end
         end
         log "Remaining lines: #{remaining_lines}"
         
         remaining_lines.empty?
      rescue => unable_to_open_or_read_file
         warn unable_to_open_or_read_file.message + "\n"
         false
      end
   end
end

