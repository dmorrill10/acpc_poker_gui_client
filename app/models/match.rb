
require 'mongoid'

require_relative '../../lib/application_defs'

require_relative 'match_slice'
require_relative 'user'

require 'acpc_poker_types/game_definition'
require 'acpc_poker_types/match_state'

class Match
  include Mongoid::Document
  include Mongoid::Timestamps::Updated

  embeds_many :slices, class_name: "MatchSlice"

  scope :expired, ->(lifespan) do
    where(:updated_at.lt => (Time.new - lifespan))
  end

  def self.id_exists?(match_id)
    Match.where(id: match_id).exists?
  end

  # @todo Fix naming
  def self.nowAsString
    Time.now.strftime('%b%-d_%Y-at-%-H:%-M:%-S')
  end

  def self.new_name(
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
    name += ".#{nowAsString}" if time
    name
  end
  def self.new_random_seed
    random_float = rand
    random_int = (random_float * 10**random_float.to_s.length).to_i
  end
  def self.new_random_seat(num_players)
    rand(num_players) + 1
  end
  def self.finished
    all.select { |match| match.finished? }
  end
  def self.unfinished(matches=all)
    matches.select { |match| !match.finished? }
  end
  def self.started_and_unfinished(matches=all)
    matches.select { |match| match.started? && !match.finished? }
  end
  def self.include_name
    field :name
    validates_presence_of :name
    validates_format_of :name, without: /^\s*$/
  end
  def self.include_name_from_user
    field :name_from_user
    validates_presence_of :name_from_user
    validates_format_of :name_from_user, without: /^\s*$/
    validates_uniqueness_of :name_from_user
  end
  def self.include_game_definition
    field :game_definition_key, type: Symbol
    validates_presence_of :game_definition_key
    field :game_definition_file_name
    field :game_def_hash, type: Hash
  end
  def self.include_number_of_hands
    field :number_of_hands, type: Integer
    validates_presence_of :number_of_hands
    validates_numericality_of :number_of_hands, greater_than: 0, only_integer: true
  end
  def self.include_opponent_names
    field :opponent_names, type: Array
    validates_presence_of :opponent_names
  end
  def self.include_seat
    field :seat, type: Integer
  end
  def self.include_user_name
    field :user_name
    validates_presence_of :user_name
    validates_format_of :user_name, without: /^\s*$/
  end
  def self.delete_matches_older_than!(lifespan)
    expired(lifespan).delete_all
    self
  end
  def self.delete_finished_matches!
    finished.each do |m|
      m.delete if m.all_slices_viewed?
    end
    self
  end
  def self.delete_match!(match_id)
    begin
      match = find match_id
    rescue Mongoid::Errors::DocumentNotFound
    else
      match.delete
    end
    self
  end
  def self.match_lifespan() 10.minutes end
  def self.delete_irrelevant_matches!
    delete_finished_matches!
    delete_matches_older_than!(match_lifespan) if match_lifespan > 0
  end

  def self.start_match(
    name,
    game_definition_key,
    user_name = User.DEFAULT_NAME,
    opponent_names = nil,
    seat = nil,
    number_of_hands = nil,
    random_seed = nil
  )
    new(
      "name_from_user" => name,
      "game_definition_key" => game_definition_key,
      'user_name' => user_name,
      "opponent_names" => opponent_names,
      'seat'=> seat,
      "number_of_hands" => number_of_hands,
      "random_seed" => random_seed
    ).finish_starting!
  end

  # Table parameters
  field :port_numbers, type: Array
  field :random_seed, type: Integer
  field :last_slice_viewed, type: Integer

  include_name
  include_name_from_user
  include_user_name
  include_game_definition
  include_number_of_hands
  include_opponent_names
  include_seat

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
  def game_def
    @game_def ||= AcpcPokerTypes::GameDefinition.new(self.game_def_hash)
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
    !slices.empty? && (
      slices.last.match_ended? || -> do
        state = AcpcPokerTypes::MatchState.parse(
          slices.last.state_string
        )
        state.hand_ended?(game_def) && state.hand_number >= self.number_of_hands - 1
      end.call
    )
  end
  def finish_starting!
    local_name = name_from_user.strip
    self.name = local_name
    self.name_from_user = local_name

    game_info = ApplicationDefs.game_definitions[game_definition_key]

    # Adjust or initialize seat
    self.seat ||= self.class().new_random_seat(game_info[:num_players])
    if seat > game_info[:num_players]
      seat = game_info[:num_players]
    end

    self.random_seed ||= self.class().new_random_seed

    self.game_definition_file_name = game_info[:file]

    self.opponent_names ||= (game_info[:num_players] - 1).times.map { |i| "tester" }

    self.number_of_hands ||= 1
    self.last_slice_viewed ||= -1

    save!

    self
  end
  def player_names
    opponent_names.dup.insert seat-1, self.user_name
  end
  def bot_special_port_requirements
    ApplicationDefs.bots(game_definition_key, opponent_names).map do |bot|
      bot[:requires_special_port]
    end
  end
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
end