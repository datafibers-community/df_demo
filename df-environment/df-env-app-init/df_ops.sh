#!/bin/bash
set -e

#######################################################################################################
# Description : This script is used for df service operations, such as start, stop, and query status
#######################################################################################################

usage () {
    echo 'Usage: df_ops <start|stop|restart|status|format|install|admin|update> <default|min|max|jar>> <<mode, such as d = debug>>'
    exit
}

if [ "$#" -ne 1 ] && [ "$#" -ne 2 ] && [ "$#" -ne 3 ]; then
    usage
fi

action=${1}
service=${2:-default}
mode=${2:-d}

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DF_APP_NAME_PREFIX=df-data-service

if [ -z ${DF_ROOT+x} ]; then
	echo "DF_ROOT is unset, use DF_APP_CONFIG=${CURRENT_DIR} ";
	DF_ROOT=${CURRENT_DIR}
fi
if [ -z ${DF_APP_CONFIG+x} ]; then
	echo "DF_APP_CONFIG is unset, use DF_APP_CONFIG=/mnt/etc ";
	DF_APP_CONFIG=/mnt/etc
fi
if [ -z ${DF_APP_LOG+x} ]; then
	echo "DF_APP_LOG is unset, use DF_APP_LOG=/mnt/logs ";
	DF_APP_LOG=/mnt/logs
fi
if [ -z ${DF_APP_DEP+x} ]; then
	echo "DF_APP_DEP is unset, use DF_APP_DEP=/opt ";
	DF_APP_DEP=/opt
fi
if [ -z ${DF_CONFIG+x} ]; then
	echo "DF_CONFIG is unset, use DF_CONFIG=$DF_ROOT/conf ";
	DF_CONFIG=$DF_ROOT/conf
fi
if [ -z ${DF_LIB+x} ]; then
	echo "DF_LIB is unset, use DF_LIB=$DF_ROOT/lib ";
	DF_LIB=$DF_ROOT/lib
fi


echo "********Starting DF Operations********"

format_all () {
rm -rf /mnt/kafka-logs/
rm -rf /mnt/zookeeper/
rm -rf /mnt/dfs/name/*
rm -rf /mnt/dfs/data/*
rm -rf /mnt/connect.offsets
rm -rf /mnt/logs/*
echo "Formatted all data & logs"
hadoop namenode -format -force -nonInteractive > /dev/null 2>&1
echo "Formatted hadoop"
}

start_confluent () {
if [ -h /opt/confluent ]; then
	zookeeper-server-start ${DF_APP_CONFIG}/zookeeper.properties 1> ${DF_APP_LOG}/zk.log 2>${DF_APP_LOG}/zk.log &
	sleep 3
	kafka-server-start ${DF_APP_CONFIG}/server.properties 1> ${DF_APP_LOG}/kafka.log 2> ${DF_APP_LOG}/kafka.log &
	sleep 3
	schema-registry-start ${DF_APP_CONFIG}/schema-registry.properties 1> ${DF_APP_LOG}/schema-registry.log 2> ${DF_APP_LOG}/schema-registry.log &
	sleep 3
	echo "Started [Zookeeper|Kafka|Schema Registry]"
	for jar in ${DF_LIB}/*.jar; do
	  CLASSPATH=${CLASSPATH}:${jar}
	done
	export CLASSPATH
	connect-distributed ${DF_CONFIG}/connect-avro-distributed.properties 1> ${DF_APP_LOG}/distributedkafkaconnect.log 2> ${DF_APP_LOG}/distributedkafkaconnect.log &
	sleep 2
	echo "Started [Kafka Connect]"
else
	echo "Confluent Platform Not Found"
fi
}

stop_confluent () {
if [ -h /opt/confluent ]; then
	schema-registry-stop ${DF_APP_CONFIG}/schema-registry.properties 1> ${DF_APP_LOG}/schema-registry.log 2> ${DF_APP_LOG}/schema-registry.log &
	kafka-server-stop ${DF_APP_CONFIG}/server.properties 1> ${DF_APP_LOG}/kafka.log 2> ${DF_APP_LOG}/kafka.log &
	zookeeper-server-stop ${DF_APP_CONFIG}/zookeeper.properties 1> ${DF_APP_LOG}/zk.log 2> ${DF_APP_LOG}/zk.log &
	echo "Shut Down [Zookeeper|Kafka|Schema Registry]"
	sid=$(getSID supportedkafka)
	if [ ! -z "${sid}" ]; then
    kill -9 ${sid}
    fi
    sid=$(getSID connectdistributed)
	if [ ! -z "${sid}" ]; then
    kill -9 ${sid}
    fi
	echo "Shut Down [Kafka Connect]"
else
	echo "Confluent Kafka Not Found"
fi
}

start_flink () {
if [ -h /opt/flink ]; then
	start-cluster.sh 1 > /dev/null 2 > /dev/null
	echo "Started [Apache Flink]"
	sleep 3
else
	echo "Apache Flink Not Found"
fi
}

stop_flink () {
if [ -h /opt/flink ]; then
	stop-cluster.sh 1 > /dev/null 2 > /dev/null
	echo "Shut Down [Apache Flink]"
	sleep 2
else
	echo "Apache Flink Not Found"
fi
}

start_hadoop () {
if [ -h /opt/hadoop ]; then
	hadoop-daemon.sh start namenode  1 > /dev/null 2 > /dev/null
	hadoop-daemon.sh start datanode  1 > /dev/null 2 > /dev/null
	echo "Started [Hadoop]"
	sleep 5
else
	echo "Apache Hadoop Not Found"
fi
if [ -h /opt/hive ]; then
	hive --service metastore 1>> ${DF_APP_LOG}/metastore.log 2>> ${DF_APP_LOG}/metastore.log &
	echo "Started [Apache Hive Metastore]"	
	hive --service hiveserver2 1>> ${DF_APP_LOG}/hiveserver2.log 2>> ${DF_APP_LOG}/hiveserver2.log &
	echo "Started [Apache Hive Server2]"	
	sleep 5
else
	echo "Apache Hive Not Found"
fi
}

stop_hadoop () {
echo "Shutting down Hadoop"
hadoop-daemon.sh stop datanode
hadoop-daemon.sh stop namenode
sid=$(getSID hivemetastore)
kill -9 ${sid} 2> /dev/null
echo "Shut Down [Apache Hive MetaStore]"
sleep 2
sid=$(getSID hiveserver2)
kill -9 ${sid} 2> /dev/null
echo "Shut Down [Apache Hive Server2]"
}

start_df() {
if [[ "${mode}" =~ (^| )d($| ) ]]; then	
	java -jar ${DF_ROOT}/lib/${DF_APP_NAME_PREFIX}* -d 1> ${DF_APP_LOG}/df.log 2> ${DF_APP_LOG}/df.log &
	echo "Started [DF Data Service] in Debug Mode. To see log using tail -f ${DF_APP_LOG}/df.log"
else
	java -jar ${DF_ROOT}/lib/${DF_APP_NAME_PREFIX}* 1> ${DF_APP_LOG}/df.log 2> ${DF_APP_LOG}/df.log &
	echo "Started [DF Data Service]. To see log using tail -f ${DF_APP_LOG}/df.log"
fi
}

stop_df() {
sid=$(getSID $DF_APP_NAME_PREFIX)
if [ -z "${sid}" ]; then
	echo "Running DF Data Service Not Found."
else
	kill -9 ${sid}
	echo "Shut Down [DF Data Service] at [$sid]"
fi
}

getSID() {
local ps_name=$1
local sid=$(ps -ef|grep -i ${ps_name}|grep -v grep|sed 's/\s\+/ /g'|cut -d " " -f2|head -1)
echo $sid
}

status () {
local service_name=$1
local service_name_show=$2
sid=$(getSID $service_name)
if [ ! -z "${sid}" ]; then
	echo "Found Running service [$service_name_show] at [${sid}]"
fi
}

start_all_service () {
if [ "${service}" = "min" ]; then
	start_confluent
	start_df
elif [ "${service}" = "max" ]; then
	start_confluent
	start_hadoop
	start_flink
	start_df
elif [ "${service}" = "default" ]; then	
	start_confluent
	start_flink
	start_df
elif [ "${service}" = "jar" ]; then	
	start_df	
else
	echo "No service will start because of wrong command."
fi	
}

stop_all_service () {
if [ "${service}" = "min" ]; then
	stop_df
	stop_confluent
elif [ "${service}" = "max" ]; then
	stop_df
	stop_confluent
	stop_flink
	stop_hadoop
elif [ "${service}" = "default" ]; then	
	stop_df
	stop_confluent
	stop_flink
elif [ "${service}" = "jar" ]; then	
	stop_df
else
	echo "No service will stop because of wrong command."
fi	
}

restart_all_service () {
stop_all_service
start_all_service
}

status_all () {
    status $DF_APP_NAME_PREFIX DataFibers
    status SupportedKafka Kafka
    status connectdistributed Kafka_Connect
    status schemaregistrymain Schema_Registry
    status JobManager Flink_JobManager
    status TaskManager Flink_TaskManager
    status NameNode HadoopNN
    status DataNode HadoopDN
    status hiveserver2 HiveServer2
    status hivemetastore HiveMetaStore
}

install_df () {
echo "Install DataFibers ..."
curl -sL http://www.datafibers.com/install | bash -
}

if [ "${action}" = "start" ] ; then
	start_all_service
elif [ "${action}" = "stop" ]; then
	stop_all_service
elif [ "${action}" = "restart" ]; then
	restart_all_service
elif [ "${action}" = "status" ]; then
	status_all
elif [ "${action}" = "install" ]; then
	install_df	
elif [ "${action}" = "format" ]; then
	format_all		
elif [ "${action}" = "admin" ]; then
	echo "not support yet"
elif [ "${action}" = "update" ]; then
	echo "not support yet"
else
    echo "wrong command entered."
    usage
fi
