#!/bin/bash

scriptDir=$( cd "$( dirname "$0" )" && pwd )
cd $scriptDir

echo -n 'Downloading MongoDb 2.0.6...'
wget http://fastdl.mongodb.org/linux/mongodb-linux-x86_64-2.0.6.tgz
echo 'Done'

echo -n 'Unpacking MongoDb...'
gunzip mongodb-linux-x86_64-2.0.6.tgz
tar xvf mongodb-linux-x86_64-2.0.6.tar
rm -f mongodb-linux-x86_64-2.0.6.tar
mv mongodb-linux-x86_64-2.0.6 mongoDB
mkdir mongoDB
mkdir mongoDB/data
mkdir mongoDB/data/db
echo 'Done'

cd -
