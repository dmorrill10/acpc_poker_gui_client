

module WorkerHelpers
   
   # @param [#to_s] message The message to log.
   def background_log(message)
      puts message.to_s
   end
   
   def delete_state!(match_id)
      @match_id_to_background_processes.delete match_id
      begin
         match = Match.find(match_id)
      rescue
      else
         match.delete
      end
   end
   
   # @param [String] match_id The ID of the match in which the exception occurred.
   # @param [String] message The exception message to log.
   def handle_exception(match_id, message)
      background_log "In match #{match_id}, #{message}"
      delete_state! match_id
   end

   # @param [String] match_id The ID of the +Match+ instance to retrieve.
   # @return [Match] The desired +Match+ instance.
   # @raise (see Match#find)
   def match_instance(match_id)
      begin
         match = Match.find match_id
      rescue => unable_to_find_match_exception
         handle_exception match_id, "unable to find a match with ID #{match_id}: #{unable_to_find_match_exception.message}"
         raise unable_to_find_match_exception
      end
      match
   end

   # @param [Match] The +Match+ instance to save.
   # @raise (see Match#save)
   def save_match_instance(match)
      begin
         match.save
      rescue => unable_to_save_match_exception
         handle_exception match.id, "Unable to save match: #{unable_to_save_match_exception}"
         raise unable_to_save_match_exception
      end
   end
   
   # @param [Hash] params The parameters in which a match ID should be retrieved.
   # @raise (see #param)
   def match_id_param(params)
      param(params, 'match_id', 'match ID')
   end
   
   # @param [Hash] params The parameter hash.
   # @param parameter_key The key of the parameter to be retrieved.
   # @param [#to_s] parameter_name The proper name of the parameter to be retrieved.
   # @raise
   def param(params, parameter_key, parameter_name, match_id=nil)
      retrieved_param = params[parameter_key]
      unless retrieved_param
         error_message = "No #{parameter_name} provided."
         if match_id
            handle_exception match_id, error_message
         else
            background_log error_message
         end
         raise
      end
      retrieved_param
   end
end
