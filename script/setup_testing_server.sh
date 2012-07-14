#!/bin/bash

SCRIPT_DIR=$( cd "$( dirname "$0" )" && pwd )
RAILS_ROOT="$SCRIPT_DIR/../"
VENDOR_DIR="$RAILS_ROOT/vendor"
$VENDOR_DIR/mongoDB/bin/mongod --nojournal --dbpath $VENDOR_DIR/mongoDB/data/db &
$VENDOR_DIR/beanstalkd &
stalk $RAILS_ROOT/lib/background/worker.rb &
cd $RAILS_ROOT
rails s
