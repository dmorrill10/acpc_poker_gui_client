
require 'mongoid'

require_relative '../../lib/application_defs'

require_relative 'match_slice'

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
  def self.delete_matches_older_than!(lifespan)
    expired(lifespan).delete_all
  end
  def self.delete_match!(match_id)
    begin
      match = find match_id
    rescue
    else
      match.delete
    end
  end
  def self.start_match(
    name,
    game_definition_key,
    opponent_names=nil,
    seat=nil,
    number_of_hands=nil,
    random_seed=nil
  )
    new(
      "name_from_user" => name,
      "game_definition_key" => game_definition_key,
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
  include_game_definition
  include_number_of_hands
  include_opponent_names
  include_seat

  # Game definition information
  field :betting_type, type: String
  field :number_of_hole_cards, type: Integer
  field :min_wagers, type: Array
  field :blinds, type: Array

  # User preferences

  # Each element must be a Hash defining:
  #   +'element_to_click'+, string representing the HTML element to click,
  #   +'action_label'+, human readable label for the action this hotkey activates, and
  #   +'key'+, the key in JQuery.hotkeys format.
  field :hotkeys, type: Array

  field :min_wager_hotkey, type: Hash
  field :all_in_hotkey, type: Hash

  # Each element must be a Hash defining:
  #   +'pot_fraction'+, Float fraction of the pot to wager,
  #   +'action_label'+, human readable label for the action this hotkey activates, and
  #   +'key'+, the key in JQuery.hotkeys format.
  field :wager_hotkeys, type: Array

  def finished?
    !slices.empty? && slices.last.match_ended?
  end
  def finish_starting!
    local_name = name_from_user.strip
    self.name = local_name
    self.name_from_user = local_name

    game_info = ApplicationDefs::GAME_DEFINITIONS[game_definition_key]

    # Adjust or initialize seat
    self.seat ||= ApplicationDefs.random_seat(game_info[:num_players])
    if seat > game_info[:num_players]
      seat = game_info[:num_players]
    end

    self.random_seed ||= ApplicationDefs.random_seed

    self.game_definition_file_name = game_info[:file]

    self.opponent_names ||= (game_info[:num_players] - 1).times.map { |i| "tester" }

    self.number_of_hands ||= 1

    # @todo I'm using literal strings when they should be constants, but I'm not sure where these should live yet
    self.hotkeys = [
      {
        'element_to_click' => ".fold",
        'key' => 'A',
        'action_label' => 'Fold'
      },
      {
        'element_to_click' => ".pass",
        'key' => 'S',
        'action_label' => 'Check / Call'
      },
      {
        'element_to_click' => ".wager",
        'key' => 'D',
        'action_label' => 'Bet / Raise'
      },
      {
        'element_to_click' => ".next_state",
        'key' => 'F',
        'action_label' => 'Next Hand'
      },
      {
        'element_to_click' => ".leave",
        'key' => 'Q',
        'action_label' => 'Leave Match'
      }
    ]
    self.min_wager_hotkey = {
      'key' => 'Z',
      'action_label' => 'Min'
    }
    self.all_in_hotkey = {
      'key' => 'N',
      'action_label' => 'All-in'
    }
    self.wager_hotkeys = [
      {
        'pot_fraction' => 1/2.to_f,
        'key' => 'X'
      },
      {
        'pot_fraction' => 3/4.to_f,
        'key' => 'C'
      },
      {
        'pot_fraction' => 1,
        'key' => 'V'
      },
      {
        'pot_fraction' => 2,
        'key' => 'B'
      }
    ]

    save!

    self
  end
  def player_names(users_name = ApplicationDefs::USER_NAME)
    opponent_names.dup.insert seat-1, users_name
  end
  def every_bot(dealer_host)
    ap "port_numbers.length: #{port_numbers.length}, player_names: #{player_names}, bot_opponent_ports: #{bot_opponent_ports}, ApplicationDefs.bots(game_definition_key, opponent_names).length: #{ApplicationDefs.bots(game_definition_key, opponent_names).length}"

    raise unless port_numbers.length == player_names.length ||
      bot_opponent_ports.length == ApplicationDefs.bots(game_definition_key, opponent_names).length

    bot_opponent_ports.zip(
      ApplicationDefs.bots(game_definition_key, opponent_names)
    ).each do |port_num, bot|
      # ENSURE THAT ALL REQUIRED KEY-VALUE PAIRS ARE INCLUDED IN THIS BOT
      # ARGUMENT HASH.
      bot_argument_hash = {
        port_number: port_num,
        server: dealer_host,
        game_def: game_definition_file_name
      }

      yield bot.run_command(bot_argument_hash).split(' ')
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
  def human_opponent_seats
    player_names.each_index.select{ |i| player_names[i] == ApplicationDefs::HUMAN_OPPONENT_NAME }.map { |s| s + 1 }
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
end