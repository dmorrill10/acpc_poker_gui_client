require 'awesome_print'
require 'logger'
require 'fileutils'

# @todo Move to its own gem the next time I find I need easier logging faculties

class Logger
  # Defaults correspond to Logger#new defaults
  def self.from_file_name(file_name, shift_age = 0, shift_size = 1048576)
    unless File.exists?(file_name)
      FileUtils.mkdir_p File.dirname(file_name)
      FileUtils.touch file_name
    end

    logger = new(file_name, shift_age, shift_size)
  end

  def path
    @logdev.filename
  end
end

module SimpleLogging
  module MessageFormatting
    refine Logger do
      def sanitize_all_messages!
        original_formatter = Logger::Formatter.new
        @formatter = proc { |severity, datetime, progname, msg|
          original_formatter.call(severity, datetime, progname, msg.dump)
        }
        self
      end
      def with_metadata!
        original_formatter = Logger::Formatter.new
        @formatter = proc { |severity, datetime, progname, msg|
          original_formatter.call(severity, datetime, progname, msg)
        }
        self
      end
    end
  end

  def logger(stream = STDOUT)
    @logger ||= Logger.new(stream)
  end
  def log_with(logger_, method, variables = nil, msg_type = Logger::Severity::INFO)
    msg = "#{self.class}: #{method}"
    msg << ": #{variables.awesome_inspect}" if variables
    logger_.log(msg_type, msg)
  end
  def log(method, variables = nil, msg_type = Logger::Severity::INFO)
    log_with(logger, method, variables, msg_type)
  end
end