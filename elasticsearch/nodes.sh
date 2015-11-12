#!/bin/bash

IMG_NAME=huiyan/elasticsearch:v2.0.0

NODE_ID=1

if [ -n "$CUR_NODE" ]; then
	NODE_ID=$CUR_NODE	
fi 

echo "Current running node on ${NODE_ID}"
MASTER_MEM=16g
QUERY_MEM=16g
DATA_MEM=32g

NODES=( 1 2 )


MASTER_NUM=( 1 2 3 4 )
MASTER_PER_NODE=2
MASTER_HTTP=2920
MASTER_NODE=2930

QUERY_NUM=( 1 2 3 4 )
QUERY_PER_NODE=2
QUERY_HTTP=3000
QUERY_NODE=3010


DATA_NUM=( 01 02 03 04 05 06 07 08 )
DATA_PER_NODE=4
#DATA_NUM0=( 01 02 03 04 )
#DATA_NUM1=( 05 06 07 08 )
#DATA_NUM2=( 09 10 11 12 )
DATA_HTTP=400
DATA_NODE=401

PUBLIC_HOST=( gw_server1 gw_server2 )
# used for node connection
HOST=( gw_server1 gw_server2 )
#PUBLISH_HOST=${BIND_HOST[$(expr ${NODE_ID} - 1)]}

UNICAST_HOSTS=():

join(){
  local IFS="$1";
  shift;
  echo "$*";
}


#all_nodes
#docker run -d -p 29300:29300 -p 29200:29200 -v /usr/local/elasticsearch/master/:/usr/local/elasticsearch/config -v /es/master1/:/data -e ES_MIN_MEM=16g -e ES_MAX_MEM=16g elasticsearch:v1 /start.sh
init_unicast_old(){
  total=0
  for idx in "${MASTER_NUM[@]}";
  do
    UNICAST_HOSTS[${total}]=${HOST}:${MASTER_NODE}${idx}
    total=$(expr ${total} + 1)
  done
    
  for idx in "${QUERY_NUM[@]}";
        do
                UNICAST_HOSTS[${total}]=${HOST}:${QUERY_NODE}${idx}
                total=$(expr ${total} + 1)
        done
       
  for idx in "${DATA_NUM[@]}";
        do
                UNICAST_HOSTS[${total}]=${HOST}:${DATA_NODE}${idx}
                total=$(expr ${total} + 1)
        done
}

init_unicast(){
	total=0
	
	for nodeid in "${NODES[@]}";
	do
		idx=$(expr ${nodeid} - 1)
		CUR_HOST=${HOST[${idx}]}
	
		MASTER_START_IDX=$(expr ${idx} \* ${MASTER_PER_NODE})
		for midx in "${MASTER_NUM[@]:${MASTER_START_IDX}:${MASTER_PER_NODE}}";
		do
			UNICAST_HOSTS[${total}]=${CUR_HOST}:${MASTER_NODE}${midx}
			total=$(expr ${total} + 1 )
		done


		#UNICAST_HOSTS[${total}]=${CUR_HOST}:${MASTER_NODE}${MASTER_NUM[${idx}]}
		#total=$(expr ${total} + 1 )

		QUERY_START_IDX=$(expr ${idx} \* ${QUERY_PER_NODE})
		for fidx in "${QUERY_NUM[@]:${QUERY_START_IDX}:${QUERY_PER_NODE}}";
                do
                        UNICAST_HOSTS[${total}]=${CUR_HOST}:${QUERY_NODE}${fidx}
                        total=$(expr ${total} + 1 )
                done



		#UNICAST_HOSTS[${total}]=${CUR_HOST}:${QUERY_NODE}${QUERY_NUM[${idx}]}
		#total=$(expr ${total} + 1)

		START_IDX=$(expr ${idx} \* ${DATA_PER_NODE})
		for didx in "${DATA_NUM[@]:${START_IDX}:${DATA_PER_NODE}}";
        	do
                	UNICAST_HOSTS[${total}]=${CUR_HOST}:${DATA_NODE}${didx}
                	total=$(expr ${total} + 1)
        	done
	

	done
	echo ${UNICAST_HOSTS[*]}
}
#init_unicast

#echo ${UNICAST_HOSTS[*]}

start_all_nodes(){
  start_masters
  start_querys
  start_datas
}

start_masters(){
  
  for idx in "${MASTER_NUM[@]}";
  do
    start_node master${idx}
  done
}

start_datas(){
  for idx in "${DATA_NUM[@]}";
  do
    start_node data${idx}
  done
}

start_querys(){
  for idx in "${QUERY_NUM[@]}";
  do
    start_node query${idx}
  done
}

start_node(){
  docker start $1
}


ARRAY=()


run_nodes(){
  #stop_all_nodes
  run_masters
  run_datas
  run_querys
}

run_masters(){
  ROLE=master
  IDX=$(expr ${NODE_ID} - 1) 
  START_IDX=$(expr ${IDX} \* ${MASTER_PER_NODE})
  ARRAY=( ${MASTER_NUM[@]:${START_IDX}:${MASTER_PER_NODE}} )
  BIND_IP=${HOST[${IDX}]}
  loop_nodes ${BIND_IP} ${ROLE} ${MASTER_HTTP} ${MASTER_NODE} ${MASTER_MEM}
}

run_querys(){
  ROLE=query
  
  IDX=$(expr ${NODE_ID} - 1) 
  START_IDX=$(expr ${IDX} \* ${QUERY_PER_NODE})
  ARRAY=( ${QUERY_NUM[@]:${START_IDX}:${QUERY_PER_NODE}} )
  BIND_IP=${PUBLIC_HOST[${IDX}]}
  loop_nodes ${BIND_IP} ${ROLE} ${QUERY_HTTP} ${QUERY_NODE} ${QUERY_MEM}
}

run_datas(){
  ROLE=data

  IDX=$(expr ${NODE_ID} - 1)
  START_IDX=$(expr ${IDX} \* ${DATA_PER_NODE})
  ARRAY=( ${DATA_NUM[@]:${START_IDX}:${DATA_PER_NODE}} )
  BIND_IP=${HOST[${IDX}]}
  loop_nodes ${BIND_IP} ${ROLE} ${DATA_HTTP} ${DATA_NODE} ${DATA_MEM}
}

# {1,2,3.....} {master|query|data} {2920} {2930} {16g|32g}
loop_nodes(){
  BIND_IP=$1
  ROLE=$2
  HTTP=$3
  NODE=$4
  MEM=$5
  for idx in ${ARRAY[@]}
  do
    run_node ${ROLE}${idx} ${ROLE} ${HTTP}${idx} ${NODE}${idx} ${MEM} ${BIND_IP}
  done
}


# run node by parameter
# {nodename} {master|lb|data} {http_port} {node_port} 
run_node(){
  NODE_NAME=$1
  NODE_ROLE=$2
  HOST_HTTP_PORT=$3
  HOST_NODE_PORT=$4
  MEM_SIZE=$5
  HOST_IP=$6
  
  CMD="docker run -d --net=host -e PUBLISH_AS=$HOST_IP --privileged=true --name ${NODE_NAME} -e HTTP_PORT=${HOST_HTTP_PORT} -e NODE_PORT=${HOST_NODE_PORT} -v /conf/${NODE_ROLE}/:/conf -v /es/${NODE_NAME}:/data -e ES_MIN_MEM=${MEM_SIZE} -e ES_MAX_MEM=${MEM_SIZE} -e NODE_NAME=${NODE_NAME} -e UNICAST_HOSTS=${UNICAST_HOSTS_STR} ${IMG_NAME} /start"

  echo 'Now remove:' ${NODE_NAME}
  docker rm ${NODE_NAME}

  echo 'Now running:' ${NODE_NAME}
  ${CMD}
  sleep 1
}

stop_all_nodes(){
  curl -XPOST 'http://gw_server1:30001/_cluster/nodes/_all/_shutdown'

  #curl -XPOST 'http://server1:30002/_cluster/nodes/_all/_shutdown'
  #curl -XPOST 'http://server2:30003/_cluster/nodes/_all/_shutdown'
  #curl -XPOST 'http://server2:30004/_cluster/nodes/_all/_shutdown'
  stop_masters
  sleep 5 
  stop_datas
  sleep 5
  stop_querys
}

stop_masters(){
  
  for idx in "${MASTER_NUM[@]}";
  do
    stop_nodes master${idx}
  done
}

stop_datas(){
  for idx in "${DATA_NUM[@]}";
  do
    stop_nodes data${idx}
  done
}

stop_querys(){
  for idx in "${QUERY_NUM[@]}";
  do
    stop_nodes query${idx}
  done
}
stop_nodes(){
  docker stop $1
}


case $1 in
  run)
    init_unicast
    UNICAST_HOSTS_STR=`join , ${UNICAST_HOSTS[@]}`
    #echo $UNICAST_HOSTS_STR
    run_nodes
    exit 0
  ;;
  start)
    start_all_nodes
    exit 0
  ;;
  stop)
    stop_all_nodes
    exit 0
  ;;
  start_master)
    init_unicast
    UNICAST_HOSTS_STR=`join , ${UNICAST_HOSTS[@]}`
    #echo $UNICAST_HOSTS_STR
    start_masters
    exit 0
  ;;
  start_querys)
    init_unicast
    UNICAST_HOSTS_STR=`join , ${UNICAST_HOSTS[@]}`
    #echo $UNICAST_HOSTS_STR
    start_querys
    exit 0
  ;;
  start_datas)
    init_unicast
    UNICAST_HOSTS_STR=`join , ${UNICAST_HOSTS[@]}`
    #echo $UNICAST_HOSTS_STR
    start_datas
    exit 0
  ;;
  stop_masters)
    stop_masters
    exit 0
  ;;
  stop_querys)
    stop_querys
    exit 0
  ;;
  stop_datas)
    stop_datas;
    exit 0
  ;;
esac
