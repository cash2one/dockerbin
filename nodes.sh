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
	ROLE=master
	loop_nodes (1,2) ${ROLE} 2920 2930 ${MASTER_MEM}
}

start_querys(){
	ROLE=query
	loop_nodes (1,2) ${ROLE} 3000 3010 ${QUERY_MEM}
}

start_datas(){
	ROLE=data
	loop_nodes (1,2,3,4) ${ROLE} 2950 2960 ${DATA_MEM}
}

# {1,2,3.....} {master|query|data} {2920} {2930}
loop_nodes(){
	ARRAY=$1
	ROLE=$2
	HTTP=$3
	NODE=$4
	MEM=$5
	for idx in ${ARRAY[@]}
	do
		start_nodes ${ROLE}${idx} ${ROLE} ${HTTP}${idx} ${NODE}${idx} ${MEM}
	done
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
