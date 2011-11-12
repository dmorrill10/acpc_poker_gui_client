#!/home/dmorrill/.rvm/rubies/ruby-1.9.2-p290/bin/ruby

# FOUND Thanks to
# http://www.tutorialspoint.com/ruby/ruby_socket_programming.htm
# for an incredibly clear tutorial and example on ruby sockets

require 'socket'               # Get sockets from stdlib

server = TCPServer.open(18791)  # Socket to listen on port 2000
client = server.accept       # Wait for a client to connect
puts client.gets #'VERSION:2.0.0\r\n'
client.write Time.now.ctime + "\n" # Send the time to the client
client.write "Closing the connection. Bye!\n"
client.close                 # Disconnect from the client

