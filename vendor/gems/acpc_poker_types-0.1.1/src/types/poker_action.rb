
# System
require 'set'

# Local mixins
require File.expand_path('../../mixins/easy_exceptions', __FILE__)

# Local classes
require File.expand_path('../chip_stack', __FILE__)

class PokerAction
   
   exceptions :illegal_poker_action
   
   # @return A modifier for the action (i.e. a bet or raise size).
   attr_reader :modifier
   
   # @return [Hash<Symbol, String>] Representations of legal actions.
   # @todo support overloaded actions like bet and check LEGAL_ACTIONS = {bet: 'r', call: 'c', check: 'c', fold: 'f', raise: 'r'}
   LEGAL_ACTIONS = {bet: 'b', call: 'c', check: 'k', fold: 'f', raise: 'r'}
   
   # @return [Set<Symbol>] The set of legal action symbols.
   LEGAL_SYMBOLS = Set.new LEGAL_ACTIONS.keys
   
   # @return [Set<String>] The set of legal action strings.
   LEGAL_STRINGS = Set.new LEGAL_ACTIONS.keys.map { |action| action.to_s }
   
   # @return [Set<String>] The set of legal ACPC action characters.
   LEGAL_ACPC_CHARACTERS = Set.new LEGAL_ACTIONS.values
   
   # @return [Set<String>] The set of legal ACPC action characters that may be accompanied by a modifier.
   MODIFIABLE_ACTIONS = LEGAL_ACTIONS.select { |sym, char| 'r' == char || 'b' == char }
   
   # @param [Symbol, String] action A representation of this action.
   # @param [ChipStack, NilClass] modifier A modifier for the action (i.e. a bet or raise size).
   # @raise IllegalPokerAction
   def initialize(action, modifier=nil)
      validate_action action
      validate_modifier modifier
   end
   
   def ==(other_action)
      to_sym == other_action.to_sym && to_s == other_action.to_s && to_acpc == other_action.to_acpc && @modifier == other_action.modifier
   end
   
   # @return [Boolean] +true+ if this action has a modifier, +false+ otherwise.
   def has_modifier?
      !@modifier.nil?
   end
   
   # @return [Symbol]
   def to_sym
      @symbol
   end
   
   # @return [String] String representation of this rank.
   def to_s
      @symbol.to_s
   end
   
   # @return [String] ACPC character representation of this rank.
   def to_acpc
      LEGAL_ACTIONS[@symbol]
   end
   
   private
   
   def validate_action(action)
      if LEGAL_SYMBOLS.include? action
         @symbol = action
      elsif LEGAL_STRINGS.include? action
         @symbol = action.to_sym
      elsif LEGAL_ACPC_CHARACTERS.include? action
         @symbol = LEGAL_ACTIONS.key action
      end
      raise(IllegalPokerAction, action.to_s) unless @symbol
   end
   
   def validate_modifier(modifier)
      # @todo Add validations
      @modifier = modifier
   end
end
