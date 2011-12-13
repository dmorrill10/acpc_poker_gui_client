
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../../support/spec_helper', __FILE__)

# Local classes
require File.expand_path('../../../src/types/poker_action', __FILE__)

describe PokerAction do   
   describe 'legal actions can be retrieved' do
      it 'with ::LEGAL_ACTIONS' do
         PokerAction::LEGAL_ACTIONS.should_not be_empty
      end
      
      it 'in symbol format' do
         PokerAction::LEGAL_SYMBOLS.should_not be_empty
      end
      
      it 'in string format' do
         PokerAction::LEGAL_STRINGS.should_not be_empty
      end
      
      it 'in acpc format' do
         PokerAction::LEGAL_ACPC_CHARACTERS.should_not be_empty
      end
   end
   
   describe '#new' do
      it 'raises an exception if the given action is invalid' do
         expect{PokerAction.new(:not_an_action)}.to raise_exception(PokerAction::IllegalPokerAction)
      end
      describe 'treats all defined legal actions as such' do
         it 'when the action is a symbol' do
            instantiate_each_action_from_symbols do |sym, patient|
            end
         end
         it 'when the action is a string' do
            instantiate_each_action_from_strings do |string, patient|
            end
         end
         it 'when the action is an ACPC character' do
            instantiate_each_action_from_acpc_characters do |char, patient|
            end
         end
      end
   end
   
   describe 'converts itself into its proper' do
      it 'symbol' do
         instantiate_each_action_from_acpc_characters do |char, patient|
            patient.to_sym.should be == PokerAction::LEGAL_ACTIONS.key(char)
         end
         instantiate_each_action_from_strings do |string, patient|
            patient.to_sym.should be == string.to_sym
         end
         instantiate_each_action_from_symbols do |sym, patient|
            patient.to_sym.should be == sym
         end
      end
      it 'string' do
         instantiate_each_action_from_acpc_characters do |char, patient|
            patient.to_s.should be == PokerAction::LEGAL_ACTIONS.key(char).to_s
         end
         instantiate_each_action_from_strings do |string, patient|
            patient.to_s.should be == string
         end
         instantiate_each_action_from_symbols do |sym, patient|
            patient.to_s.should be == sym.to_s
         end
      end
      it 'ACPC character' do
         instantiate_each_action_from_acpc_characters do |char, patient|
            patient.to_acpc.should be == char
         end
         instantiate_each_action_from_strings do |string, patient|
            patient.to_acpc.should be == PokerAction::LEGAL_ACTIONS[string.to_sym]
         end
         instantiate_each_action_from_symbols do |sym, patient|
            patient.to_acpc.should be == PokerAction::LEGAL_ACTIONS[sym]
         end
      end
   end
   
   def instantiate_each_action_from_symbols
      PokerAction::LEGAL_SYMBOLS.each do |sym|
         yield sym, PokerAction.new(sym)
      end
   end
   def instantiate_each_action_from_strings
      PokerAction::LEGAL_STRINGS.each do |string|
         yield string, PokerAction.new(string)
      end
   end
   def instantiate_each_action_from_acpc_characters
      PokerAction::LEGAL_ACPC_CHARACTERS.each do |char|
         yield char, PokerAction.new(char)
      end
   end
end
