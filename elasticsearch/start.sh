#!/bin/sh

yum install -y tar wget 


ES_HOME=/usr/local/elasticsearch
ES_VERSION=1.6.0

mkdir -p $ES_HOME
cd $ES_HOME

wget https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-$ES_VERSION.tar.gz

tar xzvf elasticsearch-$ES_VERSION.tar.gz

ln -s elasticsearch-$ES_VERSION elasticsearch

if [ ! -e /conf/elasticsearch.* ]; then
  cp $ES_HOME/config/elasticsearch.yml /conf
fi

if [ ! -e /conf/logging.* ]; then
  cp $ES_HOME/config/logging.yml /conf
fi

OPTS=""



if [ -n "$MEM_SIZE" ]; then
  OPTS="$OPTS -Xmx=$MEM_SIZE -Xms=$MEM_SIZE"
fi

if [ -n "$CLUSTER" ]; then
  OPTS="$OPTS -Des.cluster.name=$CLUSTER"
fi

if [ -n "$NODE_NAME" ]; then
  OPTS="$OPTS -Des.node.name=$NODE_NAME"
fi

if [ -n "$UNICAST_HOSTS" ]; then
  OPTS="$OPTS -Des.discovery.zen.ping.unicast.hosts=$UNICAST_HOSTS"
fi

if [ -n "$PUBLISH_AS" ]; then
  OPTS="$OPTS -Des.transport.publish_host=$(echo $PUBLISH_AS | awk -F: '{print $1}')"
  OPTS="$OPTS -Des.transport.publish_port=$(echo $PUBLISH_AS | awk -F: '{if ($2) print $2; else print 9300}')"
fi

echo "Starting Elasticsearch with the options $OPTS"
$ES_HOME/bin/elasticsearch $OPTS
