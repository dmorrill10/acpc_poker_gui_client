
require 'mongoid'

require_relative '../../lib/application_defs'

require_relative 'match_slice'
require_relative 'user'

require 'acpc_poker_types/game_definition'
require 'acpc_poker_types/match_state'

module TimeRefinement
  refine Time.class() do
    def now_as_string
      now.strftime('%b%-d_%Y-at-%-H:%-M:%-S')
    end
  end
end
using TimeRefinement

class Match
  include Mongoid::Document
  include Mongoid::Timestamps::Updated

  embeds_many :slices, class_name: "MatchSlice"

  # Scopes
  scope :old, ->(lifespan) do
    where(:updated_at.lt => (Time.new - lifespan))
  end
  scope :inactive, ->(lifespan) do
    started.and.old(lifespan)
  end
  scope :with_slices, ->(has_slices) do
    where({ 'slices.0' => { '$exists' => has_slices }})
  end
  scope :started, with_slices(true)
  scope :not_started, with_slices(false)
  scope :with_running_status, ->(is_running) do
    where(is_running: is_running)
  end
  scope :running, with_running_status(true)
  scope :not_running, with_running_status(false)

  class << self
    def id_exists?(match_id)
      where(id: match_id).exists?
    end

    # Almost scopes
    def finished
      all.select { |match| match.finished? }
    end
    def unfinished(matches=all)
      matches.select { |match| !match.finished? }
    end
    def started_and_unfinished()
      started.to_a.select { |match| !match.finished? }
    end

    # Schema
    def include_name
      field :name
      validates_presence_of :name
      validates_format_of :name, without: /^\s*$/
    end
    def include_name_from_user
      field :name_from_user
      validates_presence_of :name_from_user
      validates_format_of :name_from_user, without: /^\s*$/
      validates_uniqueness_of :name_from_user
    end
    def include_game_definition
      field :game_definition_key, type: Symbol
      validates_presence_of :game_definition_key
      field :game_definition_file_name
      field :game_def_hash, type: Hash
    end
    def include_number_of_hands
      field :number_of_hands, type: Integer
      validates_presence_of :number_of_hands
      validates_numericality_of :number_of_hands, greater_than: 0, only_integer: true
    end
    def include_opponent_names
      field :opponent_names, type: Array
      validates_presence_of :opponent_names
    end
    def include_seat
      field :seat, type: Integer
    end
    def include_user_name
      field :user_name
      validates_presence_of :user_name
      validates_format_of :user_name, without: /^\s*$/
    end

    # Generators
    def new_name(
      user_name,
      game_def_key: nil,
      num_hands: nil,
      seed: nil,
      seat: nil,
      time: true
    )
      name = "#{user_name}"
      name += ".#{game_def_key}" if game_def_key
      name += ".#{num_hands}h" if num_hands
      name += ".#{seat}s" if seat
      name += ".#{seed}r" if seed
      name += ".#{Time.now_as_string}" if time
      name
    end
    def new_random_seed
      random_float = rand
      random_int = (random_float * 10**random_float.to_s.length).to_i
    end
    def new_random_seat(num_players)
      rand(num_players) + 1
    end
    def default_opponent_names(num_players)
      (num_players - 1).times.map { |i| "Tester" }
    end
    # @todo Port numbers don't need to be stored
    def create_with_defaults(
      user_name: 'Guest',
      game_definition_key: :two_player_limit,
      port_numbers: []
    )
      Match.new(
        name_from_user: new_name(user_name),
        user_name: user_name,
        port_numbers: port_numbers,
        game_definition_key: game_definition_key
      ).finish_starting!
    end

    # Deletion
    def delete_matches_older_than!(lifespan)
      old(lifespan).delete_all
      self
    end
    def delete_finished_matches!
      finished.each do |m|
        m.delete if m.all_slices_viewed?
      end
      self
    end
    def delete_match!(match_id)
      begin
        match = find match_id
      rescue Mongoid::Errors::DocumentNotFound
      else
        match.delete
      end
      self
    end
  end

  # Schema
  field :port_numbers, type: Array
  field :random_seed, type: Integer, default: new_random_seed
  field :last_slice_viewed, type: Integer, default: -1
  field :is_running, type: Boolean, default: false
  field :dealer_options, type: String, default: (
    [
      '-a', # Append logs with the same name rather than overwrite
      "--t_response 80000", # 80 seconds per action
      '--t_hand -1',
      '--t_per_hand -1'
    ].join(' ')
  )
  include_name
  include_name_from_user
  include_user_name
  include_game_definition
  include_number_of_hands
  include_opponent_names
  include_seat


  def every_bot(dealer_host)
    raise unless (
      port_numbers.length == player_names.length ||
      bot_opponent_ports.length == ApplicationDefs.bots(game_definition_key, opponent_names).length
    )

    bot_opponent_ports.zip(
      ApplicationDefs.bots(game_definition_key, opponent_names)
    ).each do |port_num, bot|
      if bot[:runner].is_a?(Class)
        bot_argument_hash = {
          port_number: port_num,
          server: dealer_host,
          game_def: game_definition_file_name
        }

        yield bot[:runner].run_command(bot_argument_hash).split(' ')
      else # bot is a script that takes a host name and port in that order
        yield [bot[:runner], dealer_host, port_num]
      end
    end
  end


  # Initializers
  def set_name!(name_ = self.name_from_user)
    name_from_user_ = name_.strip
    self.name = name_from_user_
    self.name_from_user = name_from_user_
    self
  end
  def set_seat!(seat_ = self.seat)
    self.seat = seat_ || self.class().new_random_seat(game_info[:num_players])
    if self.seat > game_info[:num_players]
      self.seat = game_info[:num_players]
    end
    self
  end
  def set_game_definition_file_name!(file_name = game_info[:file])
    self.game_definition_file_name = file_name
    self
  end
  def set_game_definition_hash!(hash = self.game_def_hash)
    self.game_def_hash = hash || game_def_hash_from_key
  end
  def finish_starting!
    set_name!.set_seat!.set_game_definition_file_name!.set_game_definition_hash!
    self.opponent_names ||= self.class().default_opponent_names(game_info[:num_players])
    self.number_of_hands ||= 1
    save!
    self
  end

  UNIQUENESS_GUARANTEE_CHARACTER = '_'
  def copy_for_next_human_player(next_user_name, next_seat)
    match = dup
    # This match was not given a name from the user,
    # so set this parameter to an arbitrary character
    match.name_from_user = UNIQUENESS_GUARANTEE_CHARACTER
    while !match.save do
      match.name_from_user << UNIQUENESS_GUARANTEE_CHARACTER
    end
    match.user_name = next_user_name

    # Swap seat
    match.seat = next_seat
    match.opponent_names.insert(seat - 1, user_name)
    match.opponent_names.delete_at(seat - 1)
    match.save!(validate: false)
    match
  end
  def copy?
    self.name_from_user.match(/^#{UNIQUENESS_GUARANTEE_CHARACTER}+$/)
  end

  # Convenience accessors
  def game_info
    @game_info ||= ApplicationDefs.game_definitions[self.game_definition_key]
  end
  # @todo Why am I storing the file name if I want to get it from the key anyway?
  def game_def_file_name_from_key() game_info[:file] end
  def game_def_hash_from_key()
    @game_def_hash_from_key ||= AcpcPokerTypes::GameDefinition.parse_file(game_def_file_name_from_key).to_h
  end
  def game_def
    @game_def ||= AcpcPokerTypes::GameDefinition.new(game_def_hash_from_key)
  end
  def hand_number
    return nil if slices.last.nil?
    state = AcpcPokerTypes::MatchState.parse(
      slices.last.state_string
    )
    if state then state.hand_number else nil end
  end
  def no_limit?
    @is_no_limit ||= game_def.betting_type == AcpcPokerTypes::GameDefinition::BETTING_TYPES[:nolimit]
  end
  def started?
    !self.slices.empty?
  end
  def finished?
    started? && self.slices.last.match_ended?
  end
  def running?
    self.is_running
  end
  def all_slices_viewed?
    self.last_slice_viewed >= (self.slices.length - 1)
  end
  def all_slices_up_to_hand_end_viewed?
    (self.slices.length - 1).downto(0).each do |slice_index|
      slice = self.slices[slice_index]
      if slice.hand_has_ended
        if self.last_slice_viewed >= slice_index
          return true
        else
          return false
        end
      end
    end
    return all_slices_viewed?
  end
  def player_names
    opponent_names.dup.insert seat-1, self.user_name
  end
  def bot_special_port_requirements
    ApplicationDefs.bots(game_definition_key, opponent_names).map do |bot|
      bot[:requires_special_port]
    end
  end
  def users_port
    port_numbers[seat - 1]
  end
  def opponent_ports
    port_numbers_ = port_numbers.dup
    users_port_ = port_numbers_.delete_at(seat - 1)
    port_numbers_
  end
  def human_opponent_seats(opponent_user_name = nil)
    player_names.each_index.select do |i|
      if opponent_user_name
        player_names[i] == opponent_user_name
      else
        User.where(name: player_names[i]).exists?
      end
    end.map { |s| s + 1 } - [self.seat]
  end
  def human_opponent_ports
    human_opponent_seats.map { |human_opp_seat| port_numbers[human_opp_seat - 1] }
  end
  def bot_opponent_ports
    local_opponent_ports = opponent_ports
    human_opponent_ports.each do |port|
      local_opponent_ports.delete port
    end
    local_opponent_ports
  end
  def rejoinable_seats(user_name)
    (
      self.human_opponent_seats(user_name) -
      # Remove seats already taken by players who have already joined this match
      Match.where(name: self.name).ne(name_from_user: self.name).map { |m| m.seat }
    )
  end
end