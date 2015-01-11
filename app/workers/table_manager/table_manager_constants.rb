require 'socket'
require_relative '../../../lib/application_defs'

module TableManager
  THIS_MACHINE = Socket.gethostname
  DEALER_HOST = THIS_MACHINE

  CONSTANTS_FILE = File.expand_path('../table_manager.json', __FILE__)
  JSON.parse(File.read(CONSTANTS_FILE)).each do |constant, val|
    TableManager.const_set(constant, val) unless const_defined? constant
  end
  module ExhibitionConstants
    JSON.parse(File.read(File.expand_path('../../../constants/exhibition.json', __FILE__))).each do |constant, val|
      ExhibitionConstants.const_set(constant, val) unless const_defined? constant
    end
  end

  MATCH_LOG_DIRECTORY = File.join(ApplicationDefs::LOG_DIRECTORY, 'match_logs')
end
