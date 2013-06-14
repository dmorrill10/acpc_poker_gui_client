require 'logger'
require 'awesome_print'

module WorkerHelpers
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
    log __method__, "In match #{match_id}, #{message}", Logger::Severity::ERROR
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
end


# @todo Move to dmorrill10-utils
module ConversionToEnglish
  def to_english
    gsub '_', ' '
  end
end
class String
  include ConversionToEnglish
end
class Symbol
  include ConversionToEnglish
end
######

class Hash
  include WorkerHelpers

  MATCH_ID_KEY = 'match_id'

  # @param parameter_key The key of the parameter to be retrieved.
  # @param [#to_s] parameter_name The proper name of the parameter to be retrieved.
  # @raise
  def retrieve_parameter_or_raise_exception(parameter_key)
    retrieved_param = self[parameter_key]
    unless retrieved_param
      error_message = "No #{parameter_key.to_english} provided."
      if self[MATCH_ID_KEY]
        WorkerHelpers.handle_exception self['match_id'], error_message
      else
        WorkerHelpers.log_message error_message
      end
      raise
    end
    retrieved_param
  end

  # @param [Hash] params The parameters in which a match ID should be retrieved.
  # @raise (see #param)
  def retrieve_match_id_or_raise_exception
    retrieve_parameter_or_raise_exception MATCH_ID_KEY
  end
end

class Integer
  # @todo Move to dmorrill10-utils
  def process_exists?
    begin
      Process.getpgid self
      true
    rescue Errno::ESRCH
      false
    end
  end
end