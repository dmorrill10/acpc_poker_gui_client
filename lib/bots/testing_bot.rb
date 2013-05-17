#!/usr/bin/env ruby

# Gems
require 'acpc_poker_types'
require 'acpc_poker_basic_proxy'
require 'acpc_dealer'

class TestingBot
  def initialize(port_number, server_host_name='localhost', millisecond_timeout=nil, random=false)
    dealer_info = AcpcDealer::ConnectionInformation.new port_number, server_host_name, millisecond_timeout.to_i
    @proxy_bot = AcpcPokerBasicProxy::BasicProxy.new dealer_info

    log __method__, 'Connected to dealer'

    match_state = @proxy_bot.receive_match_state!

    log __method__, 'Got first match state'

    @counter = 0
    while true do
      begin
        if random
          send_random_action
        else
          send_deterministic_action
        end
        match_state = @proxy_bot.receive_match_state!

        log __method__, "match_state: #{match_state}"

        if match_state.last_action && match_state.last_action.action == 'r'
          @fold_allowed = true
        else
          @fold_allowed = false
        end
      rescue AcpcPokerBasicProxy::DealerStream::UnableToWriteToDealer
      rescue AcpcPokerBasicProxy::DealerStream::UnableToGetFromDealer
        # Ignore this these since they will always occur at the end of the match
        # since this bot doesn't know anything about the match or turns.
      rescue => e
        puts "Error in main loop: #{e.message}, backtrace: #{e.backtrace.join("\n")}"
        exit
      end
    end
  end

  def send_deterministic_action

    log __method__, "counter: #{@counter}"

    case (@counter % 3)
    when 0
      @proxy_bot.send_action AcpcPokerTypes::PokerAction::CALL
    when 1
      if @fold_allowed
        @proxy_bot.send_action AcpcPokerTypes::PokerAction::FOLD
      else
        @proxy_bot.send_action AcpcPokerTypes::PokerAction::CALL
      end
    when 2
      @proxy_bot.send_action AcpcPokerTypes::PokerAction.new('r1')
    end
    @counter += 1
  end

  def send_random_action
    random_number = rand
    @counter = (random_number * 10 ** (random_number.to_s.length-2)).to_i

    log __method__, "counter: #{@counter}"

    send_deterministic_action
  end

  def log(method, message)
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
  millisecond_timeout = if ARGV.length > 2
    ARGV[2].chomp.to_i
  else
    1000000000
  end
  random = if ARGV.length > 3
    ARGV[3].chomp == 'true'
  else
    false
  end

   TestingBot.new ARGV[0].chomp, server_host_name, millisecond_timeout, random
end

if $0 == __FILE__
  if proper_usage?
    run_script
  else
    print_usage
  end
end
