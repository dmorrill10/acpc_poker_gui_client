# To push notifications
require 'redis'

require_relative 'table_manager_constants'

module TableManager
  class MatchCommunicator
    def initialize
      @message_server = Redis.new(
        host: THIS_MACHINE,
        port: MESSAGE_SERVER_PORT
      )
    end

    def match_updated!(match_id)
      sleep ACTION_DELAY_S if ACTION_DELAY_S > 0
      @message_server.publish(
        REALTIME_CHANNEL,
        {
          room: match_id,
          channel: "#{PLAYER_ACTION_CHANNEL_PREFIX}#{match_id}"
        }.to_json
      )
      self
    end

    def update_match_queue!
      @message_server.publish(
        UPDATE_MATCH_QUEUE_CHANNEL,
        {
          room: UPDATE_MATCH_QUEUE_CHANNEL,
          channel: UPDATE_MATCH_QUEUE_CHANNEL
        }.to_json
      )
      self
    end
  end
end
