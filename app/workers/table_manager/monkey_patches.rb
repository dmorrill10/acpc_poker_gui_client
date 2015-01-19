module TableManager
  module MonkeyPatches
    module ConversionToEnglish
      def to_english
        gsub '_', ' '
      end
    end
    module StringToEnglishExtension
      refine String do
        include ConversionToEnglish
      end
    end
    module SymbolToEnglishExtension
      refine Symbol do
        include ConversionToEnglish
      end
    end

    # @todo Move into process_runner
    module IntegerAsProcessId
      refine Integer do
        def process_exists?
          begin
            Process.getpgid self
            true
          rescue Errno::ESRCH
            false
          end
        end
        def kill_process() Process.kill('TERM', self) end
        def force_kill_process() Process.kill('KILL', self) end
      end
    end
  end
end
using TableManager::MonkeyPatches::IntegerAsProcessId

# @todo Move into acpc_dealer
require 'socket'
require 'timeout'
module AcpcDealer
  def self.dealer_running?(dealer_process_hash)
    (
      dealer_process_hash &&
      dealer_process_hash[:pid] &&
      dealer_process_hash[:pid].process_exists?
    )
  end

  # Thanks to joast and Chris Rice
  # (http://stackoverflow.com/questions/517219/ruby-see-if-a-port-is-open)
  # for this (modified)
  def self.port_available?(port, ip = 'localhost')
    begin
      Timeout::timeout(1) do
        begin
          s = TCPSocket.new(ip, port)
          s.close
          return false
        rescue Errno::EHOSTUNREACH
          return false
        rescue Errno::ECONNREFUSED
          return true
        end
      end
    rescue Timeout::Error
    end

    return false
  end
end
