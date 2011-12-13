
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../../support/spec_helper', __FILE__)

# System classes
require 'tempfile'

# Local modules
require File.expand_path('../../../src/acpc_poker_types_defs', __FILE__)
require File.expand_path('../../../src/helpers/acpc_poker_types_helper', __FILE__)

# Local classes
require File.expand_path('../../../src/types/game_definition', __FILE__)

describe GameDefinition do
   include AcpcPokerTypesDefs
   include AcpcPokerTypesHelper
   include GameDefinitionHelper
   
   describe '#initialize' do
      it "parses all available game definitions properly" do      
         GAME_DEFINITION_FILE_NAMES.values.each do |game_definition_file_name|
            patient = GameDefinition.new game_definition_file_name
            
            # I reason that if the GameDefinition produced by the string version of the patient is identical to the patient, then it's likley that everything works
            temporary_game_definition_file_name = 'test_game_definition.game'
            temporary_game_definition_file = Tempfile.new(temporary_game_definition_file_name)
            temporary_game_definition_file.write patient.to_s
            temporary_game_definition_file.close false
            
            second_game_definition = GameDefinition.new temporary_game_definition_file.path
            
            patient.should be ==(second_game_definition)
            
            temporary_game_definition_file.unlink
         end
      end
   end
   
   # @todo While this procedure is decently accurate for ensuring the game definitions match, it is often buggy, so I'm going to try a simpler route (I'm not using this function right now).
   def parsed_game_definitions_match_original_definitions?(patient, game_definition_file_name)
      game_definition_string = patient.to_s
      game_definition_array = game_definition_string.split("\n")
      remaining_lines = []
      begin
         for_every_line_in_file game_definition_file_name do |definition|
            next if game_def_line_not_informative definition
            remaining_lines << definition
            game_definition_array.each do |definition_from_game|               
               remaining_lines.delete definition if definition.match("^\s*#{definition_from_game}")
            end
         end         
         remaining_lines.empty?
      rescue => unable_to_open_or_read_file
         warn unable_to_open_or_read_file.message + "\n"
         false
      end
   end
end

