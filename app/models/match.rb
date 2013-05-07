
require 'mongoid'

# @todo Use this for DB recovery
Mongoid.logger = nil

require_relative 'match_slice'

module MatchConstants
  MATCH_STATE_RETRIEVAL_TIMEOUT = 10 unless const_defined? :MATCH_STATE_RETRIEVAL_TIMEOUT
end

class Match
  include Mongoid::Document
  include Mongoid::Timestamps::Updated
  include MatchConstants

  embeds_many :slices, class_name: "MatchSlice"

  scope :expired, ->(lifespan) do
    where(:updated_at.lt => (Time.new - lifespan))
  end

  def self.include_match_name
    field :match_name
    validates_presence_of :match_name
    validates_uniqueness_of :match_name
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

  def self.include_random_seed
    field :random_seed, type: Integer
  end

  def self.include_opponent_agent
    field :bot, type: String
    validates_presence_of :bot
  end

  def self.delete_matches_older_than(lifespan)
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

  def self.failsafe_while_for_match(match_id, method_for_condition)
    match = find match_id
    failsafe_while lambda{ method_for_condition.call(match) } do
      match = find match_id
    end
    match
  end

  def self.failsafe_while(method_for_condition)
    time_beginning_to_wait = Time.now
    attempts = 0
    while method_for_condition.call
      sleep Math.log(attempts) if attempts > 1
      yield
      raise if time_limit_reached?(time_beginning_to_wait)
      attempts += 1
    end
  end

  # Table parameters
  field :port_numbers, type: Array
  field :player_names, type: String
  field :millisecond_response_timeout, type: Integer
  field :seat, type: Integer

  include_match_name
  include_game_definition
  include_number_of_hands
  include_random_seed
  include_opponent_agent

  # Game definition information
  field :betting_type, type: String
  field :number_of_hole_cards, type: Integer

  def delete_previous_slices!(current_index)
    if current_index > 0
      slices.where(
        :_id.in => (
          slices[0..current_index-1].map do |slice|
            slice.id
          end
        )
      ).delete_all
    else
      0
    end
  end

  def parameters
    {'Match name:' => match_name,
     'Game definition file name:' => game_definition_file_name,
     'Number of hands:' => number_of_hands,
     'Random seed:' => random_seed}
  end

  private

  def self.time_limit_reached?(start_time)
    Time.now > start_time + MATCH_STATE_RETRIEVAL_TIMEOUT
  end
end

module Stalker
  def self.start_background_job(job_name, arguments, options={ttr: MatchConstants::MATCH_STATE_RETRIEVAL_TIMEOUT})
    enqueue job_name, arguments, options
  end
end
