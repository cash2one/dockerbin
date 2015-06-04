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
IMG_NAME=elasticsearch:v1

MASTER_MEM=16g
QUERY_MEM=16g
DATA_MEM=32g

all_nodes(){
	start_maters
	start_querys
	start_datas
}

start_masters(){
ROLE
start_nodes master1 master 29200 29300
start_nodes master2 master 29201 29301
}

start_querys(){
start_nodes query1 query 30000 30100
start_nodes query2 query 30001 30101
}

start_datas(){
start_nodes data1 data 29500 29600
start_nodes data2 data 29501 29601
start_nodes data3 data 29502 29602
start_nodes data4 data 29503 29603
}




# start node by parameter
# {nodename} {master|lb|data} {http_port} {node_port} 
start_nodes(){
NODE_NAME=$1
NODE_ROLE=$2
HOST_HTTP_PORT=$3
HOST_NODE_PORT=$4
MEM_SIZE=$5
CMD=docker run -d -p ${HOST_HTTP_PORT}:29200 -p ${HOST_NODE_PORT}:29300 -v /usr/local/elasticsearch/${NODE_ROLE}/:/usr/local/elasticsearch/config -v /es/${NODE_NAME}:/data -e ES_MIN_MEM=${MEM_SIZE} -e ES_MAX_MEM=${MEM_SIZE} ${IMG_NAME} /start.sh

echo 'Now running: ${CMD}'

`${CMD}`

sleep 20
}
