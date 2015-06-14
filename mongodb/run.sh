#!/bin/bash


docker run -d --name HUIYAN_MONGODB -p 37017:27017 -p 38017:28017 -e MONGODB_PASS=3edczaq1 -v /mongodb/data/:/data huiyan_mongodb /run.sh
