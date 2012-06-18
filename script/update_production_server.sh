#!/bin/bash

RAILS_ROOT='/home/morrill/public_html/acpcpokerguiclient'
cd $RAILS_ROOT
god terminate
apache2ctl -f /home/morrill/httpd.conf -k stop
killall ruby
killall beanstalkd
killall mongod
hg pull --update
./script/install_poker_gems.rb
bundle install
god -c config/god.rb
bundle exec rake assets:precompile RAILS_ENV=production
