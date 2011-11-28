
# Local modules
require File.expand_path('../../../src/acpc_poker_types_defs', __FILE__)

# Local classes
require File.expand_path('../../../src/types/card', __FILE__)
require File.expand_path('../../../src/types/hand', __FILE__)

# Assortment of methods to support model tests
module ModelTestHelper
   
   # Initialization methods ---------------------------------------------------
   def create_initial_match_state(number_of_players = 2)
      user_position = 1;
      hand_number = 0
      hole_card_hand = arbitrary_hole_card_hand
      initial_match_state = mock('MatchstateString')
      initial_match_state.stubs(:position_relative_to_dealer).returns(user_position)
      initial_match_state.stubs(:hand_number).returns(hand_number)
      initial_match_state.stubs(:list_of_board_cards).returns([])
      initial_match_state.stubs(:list_of_betting_actions).returns([])
      initial_match_state.stubs(:users_hole_cards).returns(hole_card_hand)      
      initial_match_state.stubs(:list_of_opponents_hole_cards).returns([])
      initial_match_state.stubs(:list_of_hole_card_hands).returns(list_of_hole_card_hands(user_position, hole_card_hand, number_of_players))
      initial_match_state.stubs(:last_action).returns(nil)
      initial_match_state.stubs(:round).returns(0)
      initial_match_state.stubs(:number_of_actions_in_current_round).returns(0)
      
      raw_match_state =  AcpcPokerTypesDefs::MATCH_STATE_LABEL + ":#{user_position}:#{hand_number}::" + hole_card_hand
      initial_match_state.stubs(:to_s).returns(raw_match_state)
      
      [initial_match_state, user_position]
   end
   
   def list_of_hole_card_hands(user_position, user_hole_card_hand, number_of_players)
      if user_position == number_of_players - 1
         number_of_entries_in_the_list = number_of_players - 1
      else
         number_of_entries_in_the_list = number_of_players - 2
      end
      
      hole_card_sets = []
      number_of_entries_in_the_list.times do |i|
         hole_card_sets << if i == user_position then user_hole_card_hand else '' end
      end
      
      hole_card_sets   
   end
   
   def create_game_definition
      game_definition = mock('GameDefinition')
      game_definition.stubs(:number_of_players).returns(3)
      game_definition.stubs(:raise_size_in_each_round).returns([10, 10, 20, 20])
      game_definition.stubs(:first_player_position_in_each_round).returns([2, 1, 1, 1])
      game_definition.stubs(:max_raise_in_each_round).returns([3, 4, 4, 4])
      game_definition.stubs(:list_of_player_stacks).returns([20000, 20000, 20000])
      game_definition.stubs(:big_blind).returns(10)
      game_definition.stubs(:small_blind).returns(5)
      
      game_definition
   end
   
   def create_player_manager(game_definition)
      player_manager = mock('PlayerManager')
      
      (player_who_submitted_big_blind, player_who_submitted_small_blind, other_player) = create_players game_definition.big_blind, game_definition.small_blind
      
      player_manager.stubs(:player_who_submitted_big_blind).returns(player_who_submitted_big_blind)      
      player_manager.stubs(:player_who_submitted_small_blind).returns(player_who_submitted_small_blind)
      player_manager.stubs(:players_who_did_not_submit_a_blind).returns([other_player])
      
      list_of_player_stacks = game_definition.list_of_player_stacks.dup
      player_manager.stubs(:list_of_player_stacks).returns(list_of_player_stacks)
      
      player_manager
   end
   
   def create_players(big_blind, small_blind)
      player_who_submitted_big_blind = mock('Player')
      player_who_submitted_big_blind.stubs(:current_wager_faced=).with(0)
      player_who_submitted_big_blind.stubs(:current_wager_faced).returns(0)
      player_who_submitted_big_blind.stubs(:name).returns('big_blind_player')
      
      player_who_submitted_small_blind = mock('Player')
      player_who_submitted_small_blind.stubs(:current_wager_faced=).with(big_blind - small_blind)
      player_who_submitted_small_blind.stubs(:current_wager_faced).returns(big_blind - small_blind)
      player_who_submitted_small_blind.stubs(:name).returns('small_blind_player')
      
      other_player = mock('Player')
      other_player.stubs(:current_wager_faced=).with(big_blind)
      other_player.stubs(:current_wager_faced).returns(big_blind)
      other_player.stubs(:name).returns('other_player')
      
      [player_who_submitted_big_blind, player_who_submitted_small_blind, other_player]
   end
      
   def setup_action_test(match_state, action_type, action_argument = '')
      action = action_argument + action_type
      expected_string = raw_match_state_string match_state, action
      
      expected_string
   end
   
   
   # Helper methods -----------------------------------------------------------

   def raw_match_state_string(match_state, action)
      "#{match_state}:#{action}"
   end
   
   # Construct an arbitrary hole card hand.
   #
   # @return [Mock Hand] An arbitrary hole card hand.
   def arbitrary_hole_card_hand
      hand = mock('Hand')
      hand.stubs(:to_str).returns(AcpcPokerTypesDefs::CARD_RANKS[:two] + AcpcPokerTypesDefs::CARD_SUITS[:spades] + AcpcPokerTypesDefs::CARD_RANKS[:three] + AcpcPokerTypesDefs::CARD_SUITS[:hearts])
      hand.stubs(:to_s).returns(AcpcPokerTypesDefs::CARD_RANKS[:two] + AcpcPokerTypesDefs::CARD_SUITS[:spades] + AcpcPokerTypesDefs::CARD_RANKS[:three] + AcpcPokerTypesDefs::CARD_SUITS[:hearts])
      
      hand
   end
end