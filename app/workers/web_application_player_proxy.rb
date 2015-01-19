require_relative '../../lib/database_config'
require_relative '../models/match'
require_relative '../models/match_slice'

# @todo These *must* be after database_config, otherwise segfaults will occur. Don't know why.
require 'acpc_poker_player_proxy'
require 'acpc_poker_types'

require_relative '../../lib/application_defs'

require_relative '../../lib/simple_logging'
using SimpleLogging::MessageFormatting

require 'contextual_exceptions'
using ContextualExceptions::ClassRefinement

# A proxy player for the web poker application.
class WebApplicationPlayerProxy
  include SimpleLogging
  include AcpcPokerTypes

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

    log(
      __method__,
      {
        users_turn_to_act?: @player_proxy.users_turn_to_act?,
        match_ended?: @player_proxy.match_ended?
      }
    )

    self
  end

  # @see PlayerProxy#match_ended?
  def match_ended?
    return false if @player_proxy.nil?

    @match ||= Match.find(@match_id)

    @player_proxy.match_ended? ||
    (
      @player_proxy.hand_ended? &&
      @player_proxy.match_state.hand_number >= @match.number_of_hands - 1
    )
  end

  private

  def update_database!(players_at_the_table)
    @match = Match.find(@match_id)

    begin
      MatchSlice.from_players_at_the_table!(
        players_at_the_table,
        match_ended?,
        @match
      )

      new_slice = @match.slices.last
      new_slice.messages = []

      ms = players_at_the_table.match_state

      log(
        __method__,
        {
          first_state_of_first_round?: ms.first_state_of_first_round?
        }
      )

      if ms.first_state_of_first_round?
        new_slice.messages << hand_dealt_description(
          @match.player_names,
          ms.hand_number + 1,
          players_at_the_table.game_def,
          @match.number_of_hands
        )
      end

      last_action = ms.betting_sequence(
        players_at_the_table.game_def
      ).flatten.last

      log(
        __method__,
        {
          last_action: last_action
        }
      )

      if last_action
        last_actor = @match.player_names[
          @match.slices[-2].seat_next_to_act
        ]

        log(
          __method__,
          {
            last_actor: last_actor
          }
        )

        case last_action.to_acpc_character
        when PokerAction::CHECK
          new_slice.messages << check_description(
            last_actor
          )
        when PokerAction::CALL
          new_slice.messages << call_description(
            last_actor,
            last_action
          )
        when PokerAction::BET
          new_slice.messages << bet_description(
            last_actor,
            last_action
          )
        when PokerAction::RAISE
          new_slice.messages << if @match.no_limit?
            no_limit_raise_description(
              last_actor,
              last_action,
              @match.slices[-2].amount_to_call
            )
          else
            limit_raise_description(
              last_actor,
              last_action,
              ms.players(players_at_the_table.game_def).num_wagers(ms.round) - 1,
              players_at_the_table.game_def.max_number_of_wagers[ms.round]
            )
          end
        when PokerAction::FOLD
          new_slice.messages << fold_description(
            last_actor
          )
        end
      end

      log(
        __method__,
        {
          hand_ended?: players_at_the_table.hand_ended?
        }
      )

      if players_at_the_table.hand_ended?
        log(
          __method__,
          {
            reached_showdown?: ms.reached_showdown?
          }
        )

        if ms.reached_showdown?
          players_at_the_table.players.each_with_index do |player, i|
            hd = PileOfCards.new(
              player.hand +
              ms.community_cards.flatten
            ).to_poker_hand_description
            new_slice.messages << "#{@match.player_names[i]} shows #{hd}"
          end
        end
        winning_players = new_slice.players.select do |player|
          player['winnings'] > 0
        end
        if winning_players.length > 1
          new_slice.messages << split_pot_description(
            winning_players.map { |player| player['name'] },
            ms.pot(players_at_the_table.game_def)
          )
        else
          winnings = winning_players.first['winnings']
          if winnings.to_i == winnings
            winnings = winnings.to_i
          end
          chip_balance = winning_players.first['chip_balance']
          if chip_balance.to_i == chip_balance
            chip_balance = chip_balance.to_i
          end

          new_slice.messages << hand_win_description(
            winning_players.first['name'],
            winnings,
            chip_balance - winnings
          )
        end
      end

      new_slice.save!

      # Since creating a new slice doesn't "update" the match for some reason
      @match.update_attribute(:updated_at, Time.now)
      @match.save!
    rescue => e
      raise UnableToCreateMatchSlice.with_context('Unable to create match slice', e)
    end

    self
  end
end