require 'spec_helper'

describe MatchstateString do
   describe '#initialize' do
      describe 'raises an exception if the raw matchstate string' do   
         it 'is empty' do
            test_match_state_error ""
         end
      
         it 'is not in the proper format' do
            test_match_state_error "hello world"
         end
      
         it 'does not contain a position' do
            test_match_state_error MATCH_STATE_LABEL + "::0::AhKd"
         end
      
         it 'does not contain a hand number' do
            test_match_state_error MATCH_STATE_LABEL + ":0:::AsKc"
         end
   
         it 'does not contain cards' do
            test_match_state_error MATCH_STATE_LABEL + ":0:0::"
         end
      end
   
      it "parses every possible action" do
         partial_match_state = MATCH_STATE_LABEL + ":1:1:"
         hole_cards = arbitrary_hole_card_hand
         ACTION_TYPES.values.each do |action|
            match_state = partial_match_state + action + ":#{hole_cards}"
            
            patient = test_match_state_success match_state
            patient.last_action.should be == action
            
            match_state += '|'
         end
      
         # Check a no limit action as well
         pending 'No-limit support'
         
         no_limit_action = ACTION_TYPES[:raise] + "123"
         match_state = partial_match_state + no_limit_action + ":#{hole_cards}"
         patient = test_match_state_success match_state
         patient.last_action.should be == no_limit_action
      end
   
      it "parses every possible hole card hand" do
         partial_match_state = MATCH_STATE_LABEL + ":2:2::"
         LIST_OF_HOLE_CARD_HANDS.each do |hand|
            match_state = partial_match_state + hand
            
            test_match_state_success match_state
         end
      end
   
      it "parses valid limit match states in all rounds" do
         test_all_rounds_with_given_action_string ACTION_TYPES.values.join ''
      end
   
      it "parses valid no-limit match states in all rounds" do
         test_all_rounds_with_given_action_string ACTION_TYPES[:raise], 1
      end
   
      it "parses a valid two player final match state" do
         partial_match_state = MATCH_STATE_LABEL + ":20:22:"
         all_actions = ACTION_TYPES.values.join ''
         betting = all_actions
         (MAX_VALUES[:rounds]-1).times do
            betting += "/#{all_actions}"
         end
         board_cards = arbitrary_roll_out
         hands = arbitrary_hole_card_hand + "|" + arbitrary_hole_card_hand
         match_state = partial_match_state + betting + ":" + hands + board_cards
         
         test_match_state_success match_state
      end
   
      it "parses a valid three player final match state" do
         pending 'move game definition params into match state string'
         
         partial_match_state = MATCH_STATE_LABEL + ":20:22:"
         all_actions = ACTION_TYPES.values.join ''
         betting = all_actions
         (MAX_VALUES[:rounds]-1).times do
            betting += "/#{all_actions}"
         end
         board_cards = arbitrary_roll_out
         hands = arbitrary_hole_card_hand + "|" + arbitrary_hole_card_hand + "|" + arbitrary_hole_card_hand
         match_state = partial_match_state + betting + ":" + hands + board_cards
         
         test_match_state_success match_state
      end
   end
   
   describe '#round' do
      it "properly reports the current round number" do
         partial_match_state = MATCH_STATE_LABEL + ":0:0:"
         betting = ""
         hands = arbitrary_hole_card_hand
         (MAX_VALUES[:rounds]-1).times do |i|
            match_state = partial_match_state + betting + ":" + hands
            patient = test_match_state_success match_state
            patient.round.should be == i
               
            betting += "/"
         end
      end
   end
   
   # Non-test methods #########################################################
   
   # @param [Integer] An amount to append to actions.  If none is given,
   # +raise_amount+ defaults to an empty string.
   def test_all_rounds_with_given_action_string(action_string, raise_amount = '')
      partial_match_state = MATCH_STATE_LABEL + ":1:0:"
      
      users_hole_cards = arbitrary_hole_card_hand
      list_of_opponents_hole_cards = [[]]
      
      (betting_string, list_of_betting_actions) = generate_betting_sequence action_string + raise_amount.to_s
      number_of_actions_in_current_round = list_of_betting_actions.length
      
      list_of_board_cards = []
      board_cards_string = ""
      
      (1..MAX_VALUES[:rounds]).each do |round|
         match_state = partial_match_state + betting_string + ":|#{users_hole_cards}#{board_cards_string}"
         
         round_index = round - 1

         test_full_information(match_state, list_of_betting_actions,
         last_action(list_of_betting_actions), users_hole_cards, list_of_opponents_hole_cards,
         list_of_board_cards, round_index, number_of_actions_in_current_round)
         
         # Make an interesting raise amount if the caller specified a raise amount in the first place
         raise_amount += 10**round + round*3 unless raise_amount.to_s.empty?
         
         (betting_string, list_of_betting_actions) =
         generate_betting_sequence betting_string, list_of_betting_actions, action_string + raise_amount.to_s
         
         list_of_board_cards << if round > 1 then (round+1).to_s + CARD_SUITS[:spades] else arbitrary_flop end
         board_cards_string += "/" + list_of_board_cards[round]
      end
   end
   
   def generate_betting_sequence(betting_string = "", list_of_betting_actions = [], action_string)
      betting_string += if betting_string.empty? then action_string else "/#{action_string}" end
      (list_of_betting_actions << action_string.scan(/[^\/]\d*/)).flatten!
      
      [betting_string, list_of_betting_actions]
   end
   
   def last_action(list_of_betting_actions)
      log "last_action: list_of_betting_actions: #{list_of_betting_actions}"
      
      list_of_betting_actions[-1]
   end
   
   def test_full_information(match_state, list_of_betting_actions,
         last_action, users_hole_cards, list_of_opponents_hole_cards,
         list_of_board_cards, round, number_of_actions_in_current_round)
            
      patient = test_match_state_success match_state
      
      patient.list_of_betting_actions.should be == list_of_betting_actions
      patient.last_action.should be == last_action
      patient.users_hole_cards.to_s.should be == users_hole_cards.to_s
      patient.list_of_opponents_hole_cards.should be == list_of_opponents_hole_cards
      (if patient.board_cards.join.empty? then [] else [patient.board_cards.join] end).should be == list_of_board_cards
      patient.round.should be == round
      patient.number_of_actions_in_current_round.should be == number_of_actions_in_current_round
   end
   
   def test_match_state_error(incomplete_match_state)
      expect{MatchstateString.new incomplete_match_state}.to raise_exception(MatchstateString::IncompleteMatchstateString)
   end
   
   def test_match_state_success(match_state)
      patient = catch(:incomplete_match_state) do
         MatchstateString.new match_state
      end
      patient.should be_a_kind_of MatchstateString
      patient.to_s.should be == match_state
      patient
   end
   
   def arbitrary_flop
      flop = ""
      rank = 2
      CARD_SUITS.values.each do |suit|
         flop += rank.to_s + suit unless CARD_SUITS[:clubs] == suit
         rank += 3
      end
      flop
   end
   
   def arbitrary_roll_out
      board_cards = ""
      (1..MAX_VALUES[:rounds]-1).each do |round|
         board_cards += "/" + if round > 1 then (round+1).to_s + CARD_SUITS[:spades] else arbitrary_flop end
      end
      board_cards
   end
end
