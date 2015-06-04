#!/bin/bash

while getopts "a:b:s:e:" arg
    do
        case $arg in
            "b")
		echo $OPTARG
                bulk=$OPTARG
                ;;
            "s")
                startOffset=$OPTARG
                ;;
            "e")
                endOffset=$OPTARG
                ;;
            "?")
                echo "unknow argument"
                ;;
	    "a")
		echo "Run all nodes"
		;;
        esac
    done

#docker run -d -p 29300:29300 -p 29200:29200 -v /usr/local/elasticsearch/master/:/usr/local/elasticsearch/config -v /es/master1/:/data -e ES_MIN_MEM=16g -e ES_MAX_MEM=16g elasticsearch:v1 /start.sh
all_nodes(){
start_maters
start_lbs
start_datas
}

start_masters(){
start_nodes master1 master 29200 29300
start_nodes master2 master 29201 29301
}

# start node by parameter
# {nodename} {master|lb|data} {http_port} {node_port} 
start_nodes(){
NODE_NAME=$1
NODE_ROLE=$2
HOST_HTTP_PORT=$3
HOST_NODE_PORT=$4

CMD=docker run -d -p ${HOST_HTTP_PORT}:29200 -p ${HOST_NODE_PORT}:29300 -v /usr/local/elasticsearch/${NODE_ROLE}/:/usr/local/elasticsearch/config -v /es/${NODE_NAME}:/data -e ES_MIN_MEM=16g -e ES_MAX_MEM=16g elasticsearch:v1 /start.sh

echo 'Now running: ${CMD}'

`${CMD}`

sleep 20
}
