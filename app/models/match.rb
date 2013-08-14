
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
  def self.finished
    all.select { |match| match.finished? }
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
  def self.delete_match!(match_id)
    begin
      match = find match_id
    rescue
    else
      match.delete
    end

    self
  end
  def self.match_lifespan() 1.month end
  def self.delete_irrelevant_matches!
    finished.each { |m| m.delete }
    delete_matches_older_than! match_lifespan
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

  include_name
  include_name_from_user
  include_user_name
  include_game_definition
  include_number_of_hands
  include_opponent_names
  include_seat

  def game_def
    @game_def ||= AcpcPokerTypes::GameDefinition.new(self.game_def_hash)
  end
  def finished?
    !slices.empty? && (
      slices.last.match_ended? ||
      AcpcPokerTypes::MatchState.parse(
        slices.last.state_string
      ).hand_number >= self.number_of_hands - 1
    )
  end
  def finish_starting!
    local_name = name_from_user.strip
    self.name = local_name
    self.name_from_user = local_name

    game_info = ApplicationDefs.game_definitions[game_definition_key]

    # Adjust or initialize seat
    self.seat ||= ApplicationDefs.random_seat(game_info[:num_players])
    if seat > game_info[:num_players]
      seat = game_info[:num_players]
    end

    self.random_seed ||= ApplicationDefs.random_seed

    self.game_definition_file_name = game_info[:file]

    self.opponent_names ||= (game_info[:num_players] - 1).times.map { |i| "tester" }

    self.number_of_hands ||= 1

    save!

    self
  end
  def player_names
    opponent_names.dup.insert seat-1, self.user_name
  end
  def every_bot(dealer_host)
    ap "port_numbers.length: #{port_numbers.length}, player_names: #{player_names}, bot_opponent_ports: #{bot_opponent_ports}, ApplicationDefs.bots(game_definition_key, opponent_names).length: #{ApplicationDefs.bots(game_definition_key, opponent_names).length}"

    raise unless port_numbers.length == player_names.length ||
      bot_opponent_ports.length == ApplicationDefs.bots(game_definition_key, opponent_names).length

    bot_opponent_ports.zip(
      ApplicationDefs.bots(game_definition_key, opponent_names)
    ).each do |port_num, bot|
      if bot.is_a?(Class)
        bot_argument_hash = {
          port_number: port_num,
          server: dealer_host,
          game_def: game_definition_file_name
        }

        yield bot.run_command(bot_argument_hash).split(' ')
      else # bot is a script that takes a host name and port in that order
        yield [bot, dealer_host, port_num]
      end
    end
  end
  def users_port
    port_numbers[seat - 1]
  end
  def opponent_ports
    local_port_numbers = port_numbers.dup
    users_port = local_port_numbers.delete_at(seat - 1)
    local_port_numbers
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