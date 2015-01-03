#!/usr/bin/env ruby

require 'acpc_poker_types'
require 'acpc_poker_basic_proxy'
require 'acpc_dealer'

class RaiseBot
  def initialize(port_number, server_host_name='localhost')
    dealer_info = AcpcDealer::ConnectionInformation.new port_number, server_host_name
    @proxy_bot = AcpcPokerBasicProxy::BasicProxy.new dealer_info

    log __method__, 'Connected to dealer'

    match_state = @proxy_bot.receive_match_state!

    log __method__, 'Got first match state'

    while true do
      begin
        send_raise
        match_state = @proxy_bot.receive_match_state!

        log __method__, "match_state: #{match_state}"

        if match_state.last_action && match_state.last_action.action == 'r'
          @fold_allowed = true
        else
          @fold_allowed = false
        end
      rescue AcpcPokerBasicProxy::DealerStream::UnableToWriteToDealer
        exit
      rescue AcpcPokerBasicProxy::DealerStream::UnableToGetFromDealer
        # Ignore this these since they will always occur at the end of the match
        # since this bot doesn't know anything about the match or turns.
        exit
      rescue => e
        puts "Error in main loop: #{e.message}, backtrace: #{e.backtrace.join("\n")}"
        exit
      end
    end
  end

  def send_raise
    log __method__
    @proxy_bot.send_action AcpcPokerTypes::PokerAction.new('r1')
  end

  def log(method, message='')
    File.open File.expand_path('../../../log/testing_bot.log', __FILE__), 'a' do |f|
      f.puts "#{self.class}: #{method}: #{message}"
    end
  end
end

def print_usage
  puts "Usage: #{$0} <port number> [server host name] [millisecond timeout] [random]"
end

def proper_usage?
  ARGV.length > 0
end

def run_script
  server_host_name = if ARGV.length > 1
    ARGV[1].chomp
  else
    'localhost'
  end

   RaiseBot.new ARGV[0].chomp, server_host_name
end

if $0 == __FILE__
  if proper_usage?
    run_script
  else
    print_usage
  end
end
