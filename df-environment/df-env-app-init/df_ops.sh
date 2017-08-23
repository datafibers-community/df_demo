#!/bin/bash
set -e

#######################################################################################################
# Description : This script is used for df service operations, such as start, stop, and query status
#######################################################################################################

usage () {
    echo 'Usage : ./df_ops.sh <start|stop|restart|status|install|admin|update> <default|min|max|jar>> <<mode, sich sd d = debug f = format>>'
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
	echo "DF_ROOT       is unset, use DF_APP_CONFIG=${CURRENT_DIR} ";
	DF_ROOT=${CURRENT_DIR}
fi
if [ -z ${DF_APP_CONFIG+x} ]; then
	echo "DF_APP_CONFIG is unset, use DF_APP_CONFIG=/mnt/etc ";
	DF_APP_CONFIG=/mnt/etc
fi
if [ -z ${DF_APP_LOG+x} ]; then
	echo "DF_APP_LOG    is unset, use DF_APP_LOG=/mnt/logs ";
	DF_APP_LOG=/mnt/logs
fi
if [ -z ${DF_APP_DEP+x} ]; then
	echo "DF_APP_DEP    is unset, use DF_APP_DEP=/opt ";
	DF_APP_DEP=/opt
fi

echo "********Start DF Operations********"

format_all () {
echo "Formatting all data & logs - started"
rm -rf /mnt/kafka-logs/
rm -rf /mnt/zookeeper/
rm -rf /mnt/dfs/name/*
rm -rf /mnt/dfs/data/*
rm -rf /mnt/connect.offsets
rm -rf /mnt/logs/*
echo "Formatting all data & logs - completed"
echo "Formatting Hadoop NameNode - started"
hadoop namenode -format -force -nonInteractive > /dev/null 2>&1
echo "Formatting Hadoop NameNode - completed"
echo "Formatting all - completed."
}

start_confluent () {
if [ -h /opt/confluent ]; then
	echo "Starting Confluent Platform - Zookeeper, Kafka, Schema Registry"
	zookeeper-server-start ${DF_APP_CONFIG}/zookeeper.properties 1> ${DF_APP_LOG}/zk.log 2>${DF_APP_LOG}/zk.log &
	sleep 3
	kafka-server-start ${DF_APP_CONFIG}/server.properties 1> ${DF_APP_LOG}/kafka.log 2> ${DF_APP_LOG}/kafka.log &
	sleep 3
	schema-registry-start ${DF_APP_CONFIG}/schema-registry.properties 1> ${DF_APP_LOG}/schema-registry.log 2> ${DF_APP_LOG}/schema-registry.log &
	sleep 3
	for jar in ${DF_ROOT}/df_connect/*.jar; do
	  CLASSPATH=${CLASSPATH}:${jar}
	done
	export CLASSPATH
	connect-distributed ${DF_ROOT}/df_config/connect-avro-distributed.properties 1> ${DF_APP_LOG}/distributedkafkaconnect.log 2> ${DF_APP_LOG}/distributedkafkaconnect.log &
	sleep 2
else
	echo "Confluent Kafka not found"
fi
}

stop_confluent () {
if [ -h /opt/confluent ]; then
	echo "Shutting down Confluent Platform - Zookeeper, Kafka, Schema Registry"
	schema-registry-stop ${DF_APP_CONFIG}/schema-registry.properties 1> ${DF_APP_LOG}/schema-registry.log 2> ${DF_APP_LOG}/schema-registry.log &
	kafka-server-stop ${DF_APP_CONFIG}/server.properties 1> ${DF_APP_LOG}/kafka.log 2> ${DF_APP_LOG}/kafka.log &
	zookeeper-server-stop ${DF_APP_CONFIG}/zookeeper.properties 1> ${DF_APP_LOG}/zk.log 2> ${DF_APP_LOG}/zk.log &
else
	echo "Confluent Kafka not found"
fi
}

start_flink () {
if [ -h /opt/flink ]; then
	echo "Starting Apache Flink"
	start-cluster.sh
	sleep 5
else
	echo "Apache Flink not found"
fi
}

stop_flink () {
if [ -h /opt/flink ]; then
	echo "Shutting down Apache Flink"
	stop-cluster.sh
	sleep 2
else
	echo "Apache Flink not found"
fi
}

start_hadoop () {
if [ -h /opt/hadoop ]; then
	echo "Starting Hadoop. Make sure you format HDP using init_all.sh if any error happens"
	hadoop-daemon.sh start namenode
	hadoop-daemon.sh start datanode
	sleep 5
else
	echo "Apache Hadoop not found"
fi
if [ -h /opt/hive ]; then
	echo "Starting Apache Hive Metastore"
	hive --service metastore 1>> ${DF_APP_LOG}/metastore.log 2>> ${DF_APP_LOG}/metastore.log &
	echo "Starting Apache Hive Server2"
	hive --service hiveserver2 1>> ${DF_APP_LOG}/hiveserver2.log 2>> ${DF_APP_LOG}/hiveserver2.log &
	sleep 5
else
	echo "Apache Hive not found"
fi
}

stop_hadoop () {
    if [ -h /opt/hadoop ]; then
        echo "Shutting down Hadoop"
        hadoop-daemon.sh stop datanode
        hadoop-daemon.sh stop namenode
        sleep 2
    else
        echo "Apache Hadoop not found"
    fi

    sid=$(getSID hivemetastore)
    echo "Shutting down Apache Hive MetaStore"
    kill -9 ${sid} 2> /dev/null
    sleep 2
    sid=$(getSID hiveserver2)
    echo "Shutting down Apache Hive Server2"
    kill -9 ${sid} 2> /dev/null
}

start_df() {
if [[ "${mode}" =~ (^| )d($| ) ]]; then	
	java -jar ${DF_ROOT}/${DF_APP_NAME_PREFIX}* -d 1> ${DF_APP_LOG}/df.log 2> ${DF_APP_LOG}/df.log &
else
	java -jar ${DF_ROOT}/${DF_APP_NAME_PREFIX}* 1> ${DF_APP_LOG}/df.log 2> ${DF_APP_LOG}/df.log &
fi
}

stop_df() {
sid=$(getSID $DF_APP_NAME_PREFIX)
if [ -z "${sid}" ]; then
	echo "NO running DataFibers service found."
else
	echo "Shutting down DF Service at $sid"
	kill -9 ${sid}
if
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
if [ -z "${sid}" ]; then
	echo "NO running $service_name_show service found."
else
	echo "Found Running $service_name_show service at ${sid}"
fi
}

start_all_service () {
if [[ "${mode}" =~ (^| )f($| ) ]]; then	
	format_all
fi
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

update_all () {

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
elif [ "${action}" = "admin" ]; then
	echo "not support yet"
elif [ "${action}" = "update" ]; then
	echo "not support yet"
else
    echo "wrong command entered."
    usage
fi