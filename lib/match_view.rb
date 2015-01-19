require 'delegate'
require 'timeout'

require 'match'
require 'acpc_poker_types/match_state'
require 'acpc_poker_types/game_definition'
require 'acpc_poker_types/hand'

require 'contextual_exceptions'
using ContextualExceptions::ClassRefinement

class MatchView < SimpleDelegator
  include AcpcPokerTypes

  exceptions :unable_to_find_next_slice

  attr_reader :match, :slice_index, :messages_to_display
  attr_writer :messages_to_display

  def self.chip_contributions_in_previous_rounds(player, round)
    if round > 0
      player['chip_contributions'][0..round-1].inject(:+)
    else
      0
    end
  end

  DEFAULT_WAIT_FOR_SLICE_TIMEOUT = 0 # seconds

  def initialize(match_id, slice_index = nil, load_previous_messages: false, timeout: DEFAULT_WAIT_FOR_SLICE_TIMEOUT)
    @match = Match.find(match_id)
    super @match

    @messages_to_display = []

    @slice_index = slice_index || @match.last_slice_viewed

    raise StandardError.new("Illegal slice index: #{@slice_index}") unless @slice_index >= 0

    unless @slice_index < @match.slices.length
      if timeout > 0
        Timeout.timeout(timeout, UnableToFindNextSlice) do
          while @slice_index >= @match.slices.length do
            sleep 0.5
            @match = Match.find(match_id)
          end
        end
        super @match
      else
        raise UnableToFindNextSlice
      end
    end

    @messages_to_display = slice.messages

    @loaded_previous_messages_ = false

    load_previous_messages! if load_previous_messages
  end
  def user_contributions_in_previous_rounds
    self.class.chip_contributions_in_previous_rounds(user, state.round)
  end
  def state() @state ||= MatchState.parse slice.state_string end
  def slice() slices[@slice_index] end

  # zero indexed
  def users_seat() @users_seat ||= @match.seat - 1 end
  def betting_sequence() slice.betting_sequence end
  def pot_at_start_of_round() slice.pot_at_start_of_round end
  def hand_ended?() slice.hand_ended? end
  def match_ended?() slice.match_ended? end
  def users_turn_to_act?() slice.users_turn_to_act? end
  def legal_actions
    slice.legal_actions.map do |action|
      AcpcPokerTypes::PokerAction.new(action)
    end
  end

  # @return [Array<Hash>] Player information ordered by seat.
  # Each player hash should contain
  # values for the following keys:
  # 'name',
  # 'seat'
  # 'chip_stack'
  # 'chip_contributions'
  # 'chip_balance'
  # 'hole_cards'
  def players
    return @players if @players

    @players = slice.players
  end
  def user
    @user ||= players[users_seat]
  end
  def opponents
    @opponents ||= compute_opponents
  end
  def opponents_sorted_by_position_from_user
    @opponents_sorted_by_position_from_user ||= opponents.sort_by do |opp|
      Seat.new(
        opp['seat'],
        players.length
      ).seats_from(
        users_seat
      )
    end
  end
  def amount_for_next_player_to_call
    @amount_for_next_player_to_call ||= slice.amount_to_call
  end

  # Over round
  def chip_contribution_for_next_player_after_calling
    @chip_contribution_for_next_player_after_calling ||= slice.chip_contribution_after_calling
  end

  # Over round
  def minimum_wager_to
    @minimum_wager_to ||= slice.minimum_wager_to
  end

  # Over round
  def pot_after_call
    @pot_after_call ||= slice.pot_after_call
  end

  # Over round
  def pot_fraction_wager_to(fraction=1)
    return 0 if hand_ended?

    [
      [
        (
          fraction * pot_after_call +
          chip_contribution_for_next_player_after_calling
        ),
        minimum_wager_to
      ].max,
      all_in
    ].min.floor
  end

  # Over round
  def all_in
    @all_in ||= slice.all_in
  end

  def betting_type_label
    if @betting_type_label.nil?
      @betting_type_label = if no_limit?
        'nolimit'
      else
       'limit'
      end
    end

    @betting_type_label
  end

  def load_previous_messages!(index = @slice_index)
    @messages_to_display = slices[0...index].inject([]) do |messages, s|
      messages += s.messages
    end + @messages_to_display
    @loaded_previous_messages_ = true
    self
  end

  def loaded_previous_messages?
    @loaded_previous_messages_
  end

  private

  def compute_opponents
    opp = players.dup
    opp.delete_at(users_seat)
    opp
  end

  def next_slice_without_updating_messages!(max_retries = 0)
    @slice_index += 1
    retries = 0
    if @slice_index >= slices.length && max_retries < 1
      @slice_index -= 1
      raise UnableToFindNextSlice.new("Unable to find next match slice after #{retries} retries")
    end
    while @slice_index >= slices.length do
      sleep(0.1)
      @match = Match.find(@match.id)
      __setobj__ @match
      if retries >= max_retries
        @slice_index -= 1
        raise UnableToFindNextSlice.new("Unable to find next match slice after #{retries} retries")
      end
      retries += 1
    end
    self
  end
end