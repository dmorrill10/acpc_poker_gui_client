#!/usr/bin/env ruby

require_relative 'table_manager'

# Replace localhost with whatever domain on which you host this app
AcpcPokerGuiClient::TableManager.listen_to_gui('http://localhost:3000')