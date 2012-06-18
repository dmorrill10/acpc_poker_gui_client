
# Gems
require 'acpc_poker_types'
require 'acpc_poker_match_state'
require 'acpc_poker_player_proxy'

require File.expand_path('../config/database_config', __FILE__)
require File.expand_path('../../app/models/match', __FILE__)

# A proxy player for the web poker application.
class WebApplicationPlayerProxy
   include AcpcPokerTypes
   
   exceptions :unable_to_create_match_slice
   
   # @param [String] match_id The ID of the match in which this player is participating.
   # @param [DealerInformation] dealer_information Information about the dealer to which this bot should connect.
   # @param [GameDefinition, #to_s] game_definition_argument A game definition; either a +GameDefinition+ or the name of the file containing a game definition.
   # @param [String] player_names The names of the players in this match.
   # @param [Integer] number_of_hands The number of hands in this match.
   def initialize(match_id, dealer_information, users_seat,
                  game_definition_file_name, player_names='user p2',
                  number_of_hands=1)

      log __method__, {
         match_id: match_id,
         dealer_information: dealer_information,
         users_seat: users_seat,
         game_definition_file_name: game_definition_file_name,
         player_names: player_names,
         number_of_hands: number_of_hands
      }
      
      @match_id = match_id
      @match_slice_index = 0
      @player_proxy = PlayerProxy.new(
         dealer_information, 
         users_seat,
         game_definition_file_name, 
         player_names, 
         number_of_hands
      ) do |players_at_the_table|
         
         log __method__, {
            match_slice_index: @match_slice_index, 
            players_at_the_table: players_at_the_table
         }

         log __method__, { first_player_positions: players_at_the_table.game_def.first_player_positions }

         if players_at_the_table.transition.next_state
            update_database! players_at_the_table
         end
      end
   end
   
   # Player action interface
   # @see PlayerProxy#play!
   def play!(action)

      log __method__, {
         match_slice_index: @match_slice_index,
         action: action
      }

      @player_proxy.play! action do |players_at_the_table|
         update_database! players_at_the_table
         
         @match_slice_index += 1
      end

      self
   end
   
   # @see PlayerProxy#match_ended?
   def match_ended?
      match_has_ended = @player_proxy.players_at_the_table.match_ended?

      log __method__, {match_has_ended: match_has_ended}

      match_has_ended
   end
   
   private
   
   def update_database!(players_at_the_table)

      log __method__, {
         match_id: @match_id, 
         match_slice_index: @match_slice_index, 
         players_at_the_table: players_at_the_table
      }

      match = Match.find(@match_id)
      
      players = players_at_the_table.players.map { |player| sanitize_player_for_database(player) }
      
      pot_distribution = if players_at_the_table.chip_contributions.mapped_sum.sum < 0
         pot_distribution = players_at_the_table.chip_contributions.map do |contributions| 
             if contributions.last < 0 then contributions.last else 0 end
         end
      else
         players_at_the_table.chip_contributions.mapped_sum.map { |contribution| 0 }
      end
      
      pot_values_at_start_of_round = if players_at_the_table.transition.next_state.round < 1
         players_at_the_table.chip_contributions.map { |contribution| 0 }
      else
         players_at_the_table.chip_contributions.map do |contributions| 
            contributions[0..players_at_the_table.transition.next_state.round-1].sum
         end
      end

      large_blind = players_at_the_table.player_blind_relation.values.max
      player_who_submitted_big_blind = players_at_the_table.player_blind_relation.key large_blind
      small_blind = players_at_the_table.player_blind_relation.reject do |player, blind|
         blind == large_blind
      end.values.max
      player_who_submitted_small_blind = players_at_the_table.player_blind_relation.key small_blind

      player_turn_information = {
         submitted_small_blind: player_who_submitted_small_blind.name,
         submitted_big_blind: player_who_submitted_big_blind.name,
         whose_turn_is_next: if players_at_the_table.next_player_to_act 
            players_at_the_table.next_player_to_act.name
         else
            ''
         end,
         with_the_dealer_button: players_at_the_table.player_with_dealer_button.name
      }
      betting_sequence = players_at_the_table.betting_sequence_string
      legal_actions = players_at_the_table.legal_actions.to_a.map do |action| 
         action.to_acpc
      end
      
      log __method__, {
         hand_has_ended: players_at_the_table.hand_ended?,
         match_has_ended: players_at_the_table.match_ended?,
         state_string: players_at_the_table.transition.next_state.to_s,
         users_turn_to_act: players_at_the_table.users_turn_to_act?,
         players: players,
         pot_values_at_start_of_round: pot_values_at_start_of_round,
         pot_distribution: pot_distribution,
         player_turn_information: player_turn_information,
         betting_sequence: betting_sequence,
         player_acting_sequence: players_at_the_table.player_acting_sequence_string,
         legal_actions: legal_actions,
         minimum_wager: players_at_the_table.min_wager.to_i,
         amounts_to_call: players_at_the_table.players.inject({}) do |hash, player|
            hash[player.name] = players_at_the_table.amount_to_call(player).to_i
            hash
         end,
         hand_number: players_at_the_table.transition.next_state.hand_number
      }

      begin
         match.slices.create!(
            hand_has_ended: players_at_the_table.hand_ended?,
            match_has_ended: players_at_the_table.match_ended?,
            state_string: players_at_the_table.transition.next_state.to_s,
            users_turn_to_act: players_at_the_table.users_turn_to_act?,
            players: players,
            pot_values_at_start_of_round: pot_values_at_start_of_round,
            pot_distribution: pot_distribution,
            player_turn_information: player_turn_information,
            betting_sequence: betting_sequence,
            player_acting_sequence: players_at_the_table.player_acting_sequence_string,
            legal_actions: legal_actions,
            minimum_wager: players_at_the_table.min_wager.to_i,
            amounts_to_call: players_at_the_table.players.inject({}) do |hash, player|
               hash[player.name] = players_at_the_table.amount_to_call(player).to_i
               hash
            end,
            hand_number: players_at_the_table.transition.next_state.hand_number
         )
         match.save
      rescue => e
         raise UnableToCreateMatchSlice, e.message
      end

      @match_slice_index += 1

      self
   end

   def sanitize_player_for_database(player)
      { 
         'name' => player.name.to_s,
         'seat' => player.seat.to_i,
         'chip_stack' => player.chip_stack.to_i,
         'chip_contributions' => player.chip_contributions.map do |contribution_per_round|
            contribution_per_round.to_i
         end,
         'chip_balance' => player.chip_balance.to_i,
         'hole_cards' => player.hole_cards.to_acpc,
         'actions_taken_this_hand' => player.actions_taken_this_hand.map do |actions_per_round|
            actions_per_round.map { |action| action.to_acpc }
         end,
         'folded?' => player.folded?,
         'all_in?' => player.all_in?,
         'active?' => player.active?
      }
   end

   def log(method, variables)
      puts "#{self.class}: #{method}: #{variables.inspect}"
   end
end
