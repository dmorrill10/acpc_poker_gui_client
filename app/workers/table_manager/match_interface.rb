require_relative '../../../lib/database_config'
require_relative '../../models/match'

require_relative 'graceful_error_handling'

require_relative '../../../lib/simple_logging'
using SimpleLogging::MessageFormatting


module TableManager
  module MatchInterface
    include GracefulErrorHandling

    def delete_irrelevant_matches!
      Match.delete_irrelevant_matches!
      Match.started_and_unfinished.each do |m|
        if (
          m.updated_at < (Time.new - TableManager::MATCH_LIFESPAN_S) &&
          m.all_slices_up_to_hand_end_viewed?
        )
          m.delete
        end
      end
    end

    protected

    # @param [String] match_id The ID of the +Match+ instance to retrieve.
    # @return [Match] The desired +Match+ instance.
    # @raise (see Match#find)
    def match_instance(match_id)
      try(match_id) { match = Match.find match_id }
    end

    # @param [Match] The +Match+ instance to save.
    # @raise (see Match#save)
    def save_match_instance!(match)
      try(match.id) { match.save }
      self
    end
  end
end
