#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

AcpcPokerGuiClient::Application.load_tasks

task :install_poker do
   poker_gems = ['acpc_poker_types',
      'acpc_poker_basic_proxy', 'acpc_poker_player_proxy',
      'acpc_poker_match_state']
   init_path = 'vendor/gems/*/'
   gemspec_extension = '.gemspec'
   poker_gems.each do |gem|
      system "gem build #{init_path}#{gem}#{gemspec_extension}"
      system "gem install #{init_path}#{gem}*.gem"
   end
end
