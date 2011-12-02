#!/usr/bin/env ruby
poker_gems = ['acpc_poker_types',
      'acpc_poker_basic_proxy', 'acpc_poker_player_proxy',
      'acpc_poker_match_state']
init_path = File.expand_path('../../vendor/gems', __FILE__)
gemspec_extension = '.gemspec'
poker_gems.each do |gem|
   Dir.chdir Dir.glob(init_path + "/#{gem}*/")[0]
   system "gem build #{gem}#{gemspec_extension}"
   system "gem install #{gem}*.gem"
end
