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
module AcpcDealer
  def self.dealer_running?(match_process_hash)
    (
      match_process_hash[:dealer] &&
      match_process_hash[:dealer][:pid] &&
      match_process_hash[:dealer][:pid].process_exists?
    )
  end
end
