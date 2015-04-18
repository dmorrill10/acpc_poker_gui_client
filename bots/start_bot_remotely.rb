#!/usr/bin/env ruby

require 'socket'
require 'json'

def start_bots_remotely(local_host_name, port_to_local, bot, remote_host_name, remote_port)
  puts "#{__method__}: Connecting"
  s = TCPSocket.new remote_host_name, remote_port

  message = {bot: bot, host: local_host_name, port: port_to_local}.to_json
  puts "#{__method__}: Sending message: #{message}"
  s.puts(message)
end

if __FILE__ == $0
  local_host_name = ARGV[0]
  port_to_local = ARGV[1].to_i
  bot = ARGV[2]
  remote_host_name = ARGV[3]
  remote_port = ARGV[4].to_i
  start_cepheus_remotely local_host_name, port_to_local, bot, remote_host_name, remote_port
end
