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

      # Since creating a new slice doesn't "update" the match for some reason
      @match.update_attribute(:updated_at, Time.now)
      @match.save!
    rescue => e
      raise UnableToCreateMatchSlice.with_context('Unable to create match slice', e)
    end

    self
  end
end