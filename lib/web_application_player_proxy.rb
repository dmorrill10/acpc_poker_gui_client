
require 'awesome_print'
require 'acpc_poker_player_proxy'

require_relative 'database_config'
require_relative '../app/models/match'

require 'contextual_exceptions'
using ContextualExceptions::ClassRefinement

# A proxy player for the web poker application.
class WebApplicationPlayerProxy
  # @todo Use contextual exceptions
  exceptions :unable_to_create_match_slice

  # @todo Reduce the # of params
  #
  # @param [String] match_id The ID of the match in which this player is participating.
  # @param [DealerInformation] dealer_information Information about the dealer to which this bot should connect.
  # @param [GameDefinition, #to_s] game_definition A game definition; either a +GameDefinition+ or the name of the file containing a game definition.
  # @param [String] player_names The names of the players in this match.
  # @param [Integer] number_of_hands The number of hands in this match.
  def initialize(
    match_id,
    dealer_information,
    users_seat,
    game_definition,
    player_names='user p2',
    number_of_hands=1
  )

    log __method__, {
      match_id: match_id,
      dealer_information: dealer_information,
      users_seat: users_seat,
      game_definition: game_definition,
      player_names: player_names,
      number_of_hands: number_of_hands
    }

    @match_id = match_id
    @player_proxy = AcpcPokerPlayerProxy::PlayerProxy.new(
      dealer_information,
      users_seat,
      game_definition,
      player_names,
      number_of_hands
    ) do |players_at_the_table|

      if players_at_the_table.transition.next_state
        update_database! players_at_the_table
      else
        log __method__, {before_first_match_state: true}
      end
    end
  end

  # Player action interface
  # @see PlayerProxy#play!
  def play!(action)
    log __method__, {action: action}

    @player_proxy.play! action do |players_at_the_table|
      update_database! players_at_the_table
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

    # log __method__, {
    #   match_id: @match_id
    #   # @todo Add a #to_s method for PATT where it would print all the necessary information to play a poker match in terminal, then maybe use it here.
    # }

    match = Match.find(@match_id)

    # players = players_at_the_table.players.map { |player| sanitize_player_for_database(player) }

    # pot_distribution = if players_at_the_table.hand_ended?
    #   players_at_the_table.chip_contributions.map do |contributions|
    #     contributions.last
    #   end
    # else
    #   players_at_the_table.players.map { |player| 0 }
    # end

# @todo Move to gui side
    # pot_values_at_start_of_round = if players_at_the_table.transition.next_state.round < 1
    #   [0]
    # else
    #   players_at_the_table.chip_contributions.map do |contributions|
    #     contributions[0..players_at_the_table.transition.next_state.round-1].inject(:+)
    #   end
    # end

    # @todo Move to PATT
    large_blind = players_at_the_table.player_blind_relation.values.max
    player_who_submitted_big_blind = players_at_the_table.player_blind_relation.key large_blind
    small_blind = players_at_the_table.player_blind_relation.reject do |player, blind|
      blind == large_blind
    end.values.max
    player_who_submitted_small_blind = players_at_the_table.player_blind_relation.key small_blind

    slice_attributes = {
      hand_has_ended: players_at_the_table.hand_ended?,
      match_has_ended: players_at_the_table.match_ended?,
      users_turn_to_act: players_at_the_table.users_turn_to_act?,
      hand_number: players_at_the_table.transition.next_state.hand_number,
      minimum_wager: players_at_the_table.min_wager,
      seat_with_small_blind: player_who_submitted_small_blind.seat,
      seat_with_big_blind: player_who_submitted_big_blind.seat,
      seat_with_dealer_button: players_at_the_table.player_with_dealer_button.seat,
      seat_next_to_act: if players_at_the_table.next_player_to_act
        players_at_the_table.next_player_to_act.seat
      end,
      state_string: players_at_the_table.transition.next_state.to_s,
      betting_sequence: players_at_the_table.betting_sequence_string,
      legal_actions: players_at_the_table.legal_actions.to_a.map do |action|
        action.to_acpc
      end,
      players: players_at_the_table.players,
      amounts_to_call: players_at_the_table.players.sort do |player|
        player.seat
      end.map { |player| players_at_the_table.amount_to_call(player) },
      player_acting_sequence: players_at_the_table.player_acting_sequence_string
    }

    log __method__, slice_attributes

    begin
      match.slices.create! slice_attributes

      # Since creating a new slice doesn't "update" the match for some reason
      match.update_attribute(:updated_at, Time.now)
      match.save!
    rescue => e
      raise UnableToCreateMatchSlice, e.message
    end

    self
  end

  # def sanitize_player_for_database(player)
  #   {
  #     'name' => player.name.to_s,
  #     'seat' => player.seat.to_i,
  #     'chip_stack' => player.chip_stack.to_i,
  #     'chip_contributions' => player.chip_contributions.map do |contribution_per_round|
  #       contribution_per_round.to_i
  #     end,
  #     'chip_balance' => player.chip_balance.to_i,
  #     'hole_cards' => player.hole_cards.to_acpc,
  #     'actions_taken_this_hand' => player.actions_taken_this_hand.map do |actions_per_round|
  #       actions_per_round.map { |action| action.to_acpc }
  #     end,
  #     'folded?' => player.folded?,
  #     'all_in?' => player.all_in?,
  #     'active?' => player.active?
  #   }
  # end

  def log(method, variables)
    puts "#{self.class}: #{method}: #{variables.awesome_inspect}"
  end
end
