
# Local modules
require File.expand_path('../board_cards', __FILE__)
require File.expand_path('../hand', __FILE__)
require File.expand_path('../../helpers/acpc_poker_types_helper', __FILE__)
require File.expand_path('../../helpers/matchstate_string_helper', __FILE__)
require File.expand_path('../rank', __FILE__)
require File.expand_path('../suit', __FILE__)
require File.expand_path('../poker_action', __FILE__)

# Local mixins
require File.expand_path('../../mixins/easy_exceptions', __FILE__)

# Model to parse and manage information from a given match state string.
class MatchstateString
   include AcpcPokerTypesHelper
   include MatchstateStringHelper
   
   exceptions :incomplete_matchstate_string, :unable_to_parse_string_of_cards
   
   # @return [Integer] The position relative to the dealer of the player that
   #     received the match state string, indexed from 0, modulo the
   #     number of players.
   # @example The player immediately to the left of the dealer has
   #     +position_relative_to_dealer+ == 0
   # @example The dealer has
   #     +position_relative_to_dealer+ == <number of players> - 1
   attr_reader :position_relative_to_dealer
   
   # @return [Integer] The hand number.
   attr_reader :hand_number
   
   # @return [Array<Array<PokerAction>>] The sequence of betting actions.
   attr_reader :betting_sequence
   
   # @return [Array<Hand>] The list of visible hole card sets for each player.
   attr_reader :list_of_hole_card_hands
   
   # @return [BoardCards] All visible community cards on the board.
   attr_reader :board_cards
   
   
   # @param [String] raw_match_state A raw match state string to be parsed.
   # @raise IncompleteMatchstateString.
   # @todo Use values from gamedef to structure objects like +number_of_board_cards_in_every_round+
   def initialize(raw_match_state)
      raise IncompleteMatchstateString, raw_match_state if line_is_comment_or_empty? raw_match_state
   
      all_actions = PokerAction::LEGAL_ACPC_CHARACTERS.to_a.join
      all_ranks = CARD_RANKS.values.join
      all_suits = CARD_SUITS.values.join
      all_card_tokens = all_ranks + all_suits
   
      if raw_match_state.match(
              /#{MATCH_STATE_LABEL}:(\d+):(\d+):([\d#{all_actions}\/]*):([|#{all_card_tokens}]+)\/*([\/#{all_card_tokens}]*)/
              )
         @position_relative_to_dealer = $1.to_i
         @hand_number = $2.to_i
         @betting_sequence = parse_betting_sequence $3
         @list_of_hole_card_hands = parse_list_of_hole_card_hands $4
         @board_cards = parse_board_cards $5
      end
   
      raise IncompleteMatchstateString, raw_match_state if incomplete_match_state?      
   end

   # @see to_str
   def to_s
      to_str
   end

   # @return [String] The MatchstateString in raw text form.
   def to_str      
      build_match_state_string @position_relative_to_dealer, @hand_number,
         betting_sequence_string(@betting_sequence),
         hole_card_strings(@list_of_hole_card_hands), @board_cards
   end
   
   # @param [MatchstateString] another_matchstate_string A matchstate string to compare against this one.
   # @return [Boolean] +true+ if this matchstate string is equivalent to +another_matchstate_string+, +false+ otherwise.
   def ==(another_matchstate_string)
      another_matchstate_string.to_s == to_s
   end
   
   # @return [PokerAction, NilClass] The last action taken or +nil+ if no action was previously taken.
   def last_action
      last_action_in_the_current_round = @betting_sequence.last.last
      if !last_action_in_the_current_round && round > 0
         return @betting_sequence[-2].last
      end
      last_action_in_the_current_round
   end

   # @return [Hand] The user's hole cards.
   # @example An ace of diamonds and a 4 of clubs is represented as
   #     'Ad4c'
   def users_hole_cards
      list_of_hole_card_hands[@position_relative_to_dealer]
   end
   
   # @return [Array] The list of opponent hole cards that are visible.
   # @example If there are two opponents, one with AhKs and the other with QdJc, then
   #     list_of_opponents_hole_cards == [AhKs:Hand, QdJc:Hand]
   def list_of_opponents_hole_cards
      local_list_of_hole_card_hands = list_of_hole_card_hands.dup
      local_list_of_hole_card_hands.delete_at @position_relative_to_dealer
      local_list_of_hole_card_hands
   end
   
   # @return [Integer] The zero indexed current round number.
   def round
      @betting_sequence.length - 1
   end
   
   # @return [Integer] The number of actions in the current round.
   def number_of_actions_in_current_round
      @betting_sequence[round].length
   end
   
   private
   
   def list_of_actions_from_acpc_characters(betting_sequence)
      all_actions = PokerAction::LEGAL_ACPC_CHARACTERS.to_a.join ''
      betting_sequence.scan(/[#{all_actions}]\d*/)
   end
   
   def incomplete_match_state?
      !(@position_relative_to_dealer and @hand_number and @list_of_hole_card_hands)
   end
   
   def parse_list_of_hole_card_hands(string_of_hole_cards)      
      list_of_hole_card_hands = []
      for_every_set_of_cards(string_of_hole_cards, '\|') do |string_hand|
         hand = Hand.draw_cards string_hand
         list_of_hole_card_hands << hand
      end
      list_of_hole_card_hands
   end
   
   def parse_betting_sequence(string_betting_sequence)
      return [[]] if string_betting_sequence.empty?
      
      betting_sequence = []
      list_of_actions_by_round = string_betting_sequence.split(/\//)
      list_of_actions_by_round.each do |betting_sequence_in_a_particular_round|
         betting_sequence_in_a_particular_round = list_of_actions_from_acpc_characters(betting_sequence_in_a_particular_round).inject([]) do
            |list, action| list << PokerAction.new(action)
         end
         betting_sequence << betting_sequence_in_a_particular_round
      end
      # Adjust the number of rounds if the last action was the last action in the round
      if string_betting_sequence.match(/\//)
         betting_sequence << [] if string_betting_sequence.count('/') > (betting_sequence.length - 1)
      end
      betting_sequence
   end
   
   def parse_board_cards(string_board_cards)
      # @todo Game definition should be used here instead
      board_cards = BoardCards.new [3, 1, 1]
      for_every_set_of_cards(string_board_cards, '\/') do |string_board_card_set|
         next if string_board_card_set.match(/^\s*$/)
         for_every_card(string_board_card_set) do |card|
            board_cards << card
         end
      end
      board_cards
   end
   
   def for_every_set_of_cards(string_of_card_sets, divider)
      string_of_card_sets.split(/#{divider}/).each do |string_card_set|
         yield string_card_set
      end
   end
   
   def for_every_card(string_of_cards)
      all_ranks = CARD_RANKS.values.join
      all_suits = CARD_SUITS.values.join
      
      string_of_cards.scan(/[#{all_ranks}][#{all_suits}]/).each do |string_card|        
         card = Card.new string_card
         yield card
      end
   end
   
   def hole_card_strings(list_of_hole_card_hands)
      # @todo Game definition should be used here instead
      number_of_players = 2
      list_of_hands = list_of_hole_card_hands.dup
      while list_of_hands.length < number_of_players
         list_of_hands << ''
      end
      
      (list_of_hands.inject('') { |string, hand|  string += hand.to_s + '|' }).chop
   end
   
   def betting_sequence_string(betting_sequence)
      string = ''
      (round + 1).times do |i|
         string += (betting_sequence[i].map { |action| action.to_acpc }).join('')
         string += '/' unless i == round
      end
      string
   end
end
