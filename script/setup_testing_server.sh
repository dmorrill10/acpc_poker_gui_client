#!/bin/bash

SCRIPT_DIR=$( cd "$( dirname "$0" )" && pwd )
RAILS_ROOT="$SCRIPT_DIR/../"
$SCRIPT_DIR/mongoDB/bin/mongod --nojournal --dbpath $SCRIPT_DIR/mongoDB/data/db &
$SCRIPT_DIR/beanstalkd &
stalk $SCRIPT_DIR/worker.rb &
cd $RAILS_ROOT
rails s
