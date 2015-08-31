#!/bin/bash


#docker run -d --name HUIYAN_MONGODB -p 37017:27017 -p 38017:28017 -e MONGODB_PASS=3edczaq1 -v /mongodb/data/:/data huiyan_mongodb /run.sh
docker run -d --name HUIYAN_MONGODB --net=host -e AUTH=no -v /mongodb/data/:/data huiyan_mongodb /run.sh
