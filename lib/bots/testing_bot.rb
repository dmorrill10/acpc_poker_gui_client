#!/usr/bin/env ruby

# Gems
require 'dmorrill10-utils'
require 'acpc_poker_types'
require 'acpc_poker_basic_proxy'

include Script

class TestingBot
  
  def initialize(port_number, server_host_name='localhost', millisecond_timeout=nil, random=false)
    dealer_info = AcpcDealerInformation.new server_host_name,
      port_number.to_i, millisecond_timeout.to_i
    @proxy_bot = BasicProxy.new dealer_info

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

        if match_state.last_action && match_state.last_action.to_acpc_character == 'r'
          @fold_allowed = true
        else
          @fold_allowed = false
        end
      rescue => e
        puts e.message
        exit
      end
    end
  end

  def send_deterministic_action

    log __method__, "counter: #{@counter}"

    case (@counter % 3)
    when 0
      @proxy_bot.send_action PokerAction.new(:call)
    when 1
      if @fold_allowed
        @proxy_bot.send_action PokerAction.new(:fold)
      else
        @proxy_bot.send_action PokerAction.new(:call)
      end
    when 2
      @proxy_bot.send_action PokerAction.new(:raise, {modifier: 1})
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

run_script_if_run_as_script(__FILE__) do
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
