#!/usr/bin/env ruby

require 'socket'
require 'json'

module AcpcBotServer
  ALLOWED_BOTS = {
    # Register allowed bot names and commands here like
    # 'MyRemoteBot' => File.expand_path('../bots/my_bot_runner.sh', __FILE__)
  }
  ALLOWED_HOSTS = [
    # Register the address of allowed hosts
    # 'trusted.ca'
  ]

  def self.run!(port)
    puts "#{self.class()}##{__method__}: Starting"

    TCPServer.open(port) do |server|
      puts "#{self.class()}##{__method__}: Listening"
      STDIN.flush
      loop do
        Thread.start(server.accept) do |client|
          puts "#{self.class()}##{__method__}: Client connected"
          message = client.gets
          puts "#{self.class()}##{__method__}: Message from client: #{message}"
          # @todo
          begin
            data = JSON.parse(message)
            bot = data["bot"]
            port = data["port"]
            host = data["host"]
            raise "Request ignored: #{host} is not in the list of trusted hosts: #{ALLOWED_HOSTS}" unless ALLOWED_HOSTS.include?(host)

            command = ALLOWED_BOTS[bot]

            if command
              command += " #{host} #{port}"
              puts "#{self.class()}##{__method__}: Starting #{bot}, connecting to #{host} on port #{port} with command:"
              puts "Running: `#{command}`"

              `#{command}`
            end
          rescue => e
            puts "Exception: #{e.message}"
          end
          client.close
        end
      end
    end

    puts "#{self.class()}##{__method__}: Exiting"
  end
end

if __FILE__ == $0
  puts "Running"
  AcpcBotServer.run!
end
