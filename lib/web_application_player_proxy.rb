require 'acpc_poker_player_proxy'

require_relative 'database_config'
require_relative '../app/models/match'
require_relative '../app/models/match_slice'

require_relative 'application_defs'

require_relative 'simple_logging'
using SimpleLogging::MessageFormatting

require 'contextual_exceptions'
using ContextualExceptions::ClassRefinement

# A proxy player for the web poker application.
class WebApplicationPlayerProxy
  include SimpleLogging

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
    @logger = Logger.from_file_name(File.join(ApplicationDefs::LOG_DIRECTORY, 'proxy_logs', "#{match_id}.#{users_seat}.log")).with_metadata!

    log __method__, {
      dealer_information: dealer_information,
      users_seat: users_seat,
      game_definition: game_definition,
      player_names: player_names,
      number_of_hands: number_of_hands
    }

    @match_id = match_id
    @player_proxy = AcpcPokerPlayerProxy::PlayerProxy.new(
      dealer_information,
      game_definition,
      users_seat
    ) do |players_at_the_table|

      if players_at_the_table.match_state
        update_database! players_at_the_table

        yield players_at_the_table if block_given?
      else
        log __method__, {before_first_match_state: true}
      end
    end
  end

  # Player action interface
  # @see PlayerProxy#play!
  def play!(action)
    log __method__, action: action

    @player_proxy.play! action do |players_at_the_table|
      update_database! players_at_the_table

      yield players_at_the_table if block_given?
    end

    self
  end

  # @see PlayerProxy#match_ended?
  def match_ended?
    match_has_ended = if @player_proxy
      @player_proxy.match_ended?
    else
      false
    end

    log __method__, match_has_ended: match_has_ended

    match_has_ended
  end

  private

  def self.chip_contributions_in_previous_rounds(
    player,
    round = player.contributions.length - 1
  )
    if round > 0
      player.contributions[0..round-1].inject(:+)
    else
      0
    end
  end

  def adjust_action_amount(action, round, action_index, patt)
    amount_to_over_hand = action.modifier
    if amount_to_over_hand.blank?
      action
    else
      amount_to_over_round = (
        amount_to_over_hand.to_i - self.class.chip_contributions_in_previous_rounds(
          patt.match_state.players(patt.game_def)[patt.match_state.position_relative_to_dealer],
          round
        ).to_i
      )
      "#{action[0]}#{amount_to_over_round}"
    end
  end

  def update_database!(players_at_the_table)
    match = Match.find(@match_id)

    # Save and retrieve game def hash in Match, then more of the game can be deduced from MatchState
    slice_attributes = {
      match_has_ended: match_ended?,
      seat_with_small_blind: players_at_the_table.small_blind_payer.seat.to_i,
      seat_with_big_blind: players_at_the_table.big_blind_payer.seat.to_i,
      seat_with_dealer_button: players_at_the_table.dealer_player.seat.to_i,
      seat_next_to_act: if players_at_the_table.next_player_to_act
        players_at_the_table.next_player_to_act.seat.to_i
      end,
      state_string: players_at_the_table.match_state.to_s,
      balances: players_at_the_table.players.map do |player|
        player.balance
      end,

      # Not necessary to be in the database, but more performant than processing on the
      # Rails server
      betting_sequence: -> do
        sequence = ''
        players_at_the_table.match_state.betting_sequence(players_at_the_table.game_def).each_with_index do |actions_per_round, round|
          actions_per_round.each_with_index do |action, action_index|
            action = adjust_action_amount(action, round, action_index, players_at_the_table)

            sequence << if (
              players_at_the_table.match_state.player_acting_sequence(players_at_the_table.game_def)[round][action_index].to_i ==
              players_at_the_table.match_state.position_relative_to_dealer
            )
              action.capitalize
            else
              action
            end
          end
          unless round == players_at_the_table.match_state.betting_sequence(players_at_the_table.game_def).length - 1
            sequence << '/'
          end
        end
        sequence
      end.call
    }

    log __method__, slice_attributes

    begin
      match.slices.create! slice_attributes

      # Since creating a new slice doesn't "update" the match for some reason
      match.update_attribute(:updated_at, Time.now)
      match.save!
    rescue => e
      raise UnableToCreateMatchSlice.with_context('Unable to create match slice', e)
    end

    self
  end
end