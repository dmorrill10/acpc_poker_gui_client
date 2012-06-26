#!/bin/bash

scriptDir=$( cd "$( dirname "$0" )" && pwd )
vendorDir="$scriptDir/../vendor"
cd $vendorDir

echo 'Cloning beanstalkd from GitHub...'
git clone git://github.com/kr/beanstalkd.git
echo 'Done'

echo 'Building beanstalkd...'
cd beanstalkd/
make
echo 'Done'

echo -n 'Cleaning up...' 
temp_name='beanstalkd_executable'
cp beanstalkd ../$temp_name
cd ../
rm -rf beanstalkd
mv $temp_name beanstalkd
echo 'Done'
