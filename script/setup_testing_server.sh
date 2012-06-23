#!/bin/bash

SCRIPT_DIR=$( cd "$( dirname "$0" )" && pwd )
RAILS_ROOT="$SCRIPT_DIR/../"
$RAILS_ROOT/mongoDB/mongodb-linux-x86_64-2.0.1/bin/mongod --nojournal --dbpath $RAILS_ROOT/mongoDB/data/db &
$SCRIPT_DIR/beanstalkd &
stalk $SCRIPT_DIR/worker.rb &
cd $RAILS_ROOT
rails s
