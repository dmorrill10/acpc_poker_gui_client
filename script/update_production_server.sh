#!/bin/bash

god terminate
apache2ctl -f ~/httpd.conf -k stop
killall ruby
killall beanstalkd
killall mongod
git pull
bundle install
god -c config/god.rb
bundle exec rake assets:precompile RAILS_ENV=production
