#!/usr/bin/env ruby

require 'fileutils'

original_directory = File.expand_path('../', __FILE__)
poker_gems = ['acpc_poker_types',
      'acpc_poker_basic_proxy', 'acpc_poker_player_proxy',
      'acpc_poker_match_state']
temporary_gem_directory = File.expand_path('../../tmp/temporary_acpc_poker_gem', __FILE__)
poker_gems.each do |gem|
   git_repo_name = 'git@bitbucket.org:morrill/' + gem.gsub(/_/, "") + '.git'
   system "git clone #{git_repo_name} #{temporary_gem_directory}"
   unless File.directory? temporary_gem_directory
      puts "Creating #{temporary_gem_directory}..."
      Dir.mkdir temporary_gem_directory
   end
   if File.directory? temporary_gem_directory
      Dir.chdir temporary_gem_directory do
         puts "Installing..."
         system 'rake install'
      end
      puts "Removing #{temporary_gem_directory}..."
      FileUtils.rmtree temporary_gem_directory
   else
      puts "ERROR: unable to install #{git_repo_name} to #{temporary_gem_directory}"
   end
end
