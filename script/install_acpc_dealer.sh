#!/bin/bash

scriptDir=$( cd "$( dirname "$0" )" && pwd )
vendorDir="$scriptDir/../vendor"
cd $vendorDir

echo -n 'Downloading ACPC Dealer...'
svn co http://www.computerpokercompetition.org/repos/project_acpc_server/trunk/
mv trunk project_acpc_server
echo 'Done'

echo -n 'Installing...'
cd project_acpc_server
make
echo 'Done'
