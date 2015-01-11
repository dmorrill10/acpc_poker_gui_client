require_relative '../../../lib/database_config'
require_relative '../../models/match'

module TableManager
  module GracefulErrorHandling
    protected

    # @param [String] match_id The ID of the match in which the exception occurred.
    # @param [Exception] e The exception to log.
    def handle_exception(match_id, e)
      log(
        __method__,
        {
          match_id: match_id,
          message: e.message,
          backtrace: e.backtrace
        },
        Logger::Severity::ERROR
      )
      Match.delete_match! match_id if match_id
    end

    def try(match_id)
      begin
        yield if block_given?
      rescue => e
        handle_exception match_id, e
        raise e
      end
    end
  end
end
