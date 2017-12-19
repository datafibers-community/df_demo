#!/bin/bash
#set -e #comment this since the curl returns none-zero when service is not available

#######################################################################################################
# Description : This script is used for df service operations, such as start, stop, and query status
#######################################################################################################

usage () {
    printf "Usage:\n"
        printf " df_ops [service operation] [service name] [service option]\n"
        printf " df_ops [admin operation] [admin option]\n"
        printf "\n"
        printf "Parameters:\n"
        printf "[service operation]\n"
        printf "%-25s: %-50s\n" "start|stop|restart" "Perform start|stop|restart on df environment and service"
    printf "\n"
        printf "[service]\n"
        printf "%-25s: %-50s\n" "default" "Run kafka, flink, and df. This is the default option."
        printf "%-25s: %-50s\n" "min" "Run kafka and df"
        printf "%-25s: %-50s\n" "max" "Run kafka, flink, hadoop, hive, spark, livy, and df"
        printf "%-25s: %-50s\n" "jar" "Run df jar only"
    printf "\n"
        printf "[service option]\n"
        printf "%-25s: %-50s\n" "debug" "Run in debug mode. This is a default option."
        printf "%-25s: %-50s\n" "normal" "Run in normal mode."
    printf "\n"
    printf "[admin operation]\n"
        printf "%-25s: %-50s\n" "status" "Check status of data service and environment"
        printf "%-25s: %-50s\n" "format" "Format all data and logs"
        printf "%-25s: %-50s\n" "help" "Show this help"
        printf "%-25s: %-50s\n" "admin" "Perform data service admin operations and must use with [admin option]"
        printf "%-25s: %-50s\n" "install" "Reinstall df packages, which can also use with [admin option]"
        printf "%-25s: %-50s\n" "update" "Update df packages, which can also use with [admin option]"
    printf "\n"
        printf "[admin option]\n"
        printf "%-25s: %-50s\n" "idi" "Reset df_installed collection. Only applicable to admin"
        printf "%-25s: %-50s\n" "branch_name" "Install df from specific branch name. Only applicable to install"
        printf "%-25s: %-50s\n" "yes" "Update df with yes prompt for all package. Only applicable to update"
    printf "\n"
        printf "Examples:\n"
        printf "%-25s: %-50s\n" "df_ops start" "Run df default environment and data service"
        printf "%-25s: %-50s\n" "df_ops start debug" "Run df default environment and data service in debug mode"
        printf "%-25s: %-50s\n" "df_ops start max debug" "Run df max environment and data service in debug mode"
        printf "%-25s: %-50s\n" "df_ops restart jar debug" "Restart df jar file in debug mode"
        printf "%-25s: %-50s\n" "df_ops stop" "Stop df and all services"
        printf "%-25s: %-50s\n" "df_ops status" "Check running status for all df and its related services"
        printf "%-25s: %-50s\n" "df_ops format" "Format environment data and logs"
        printf "%-25s: %-50s\n" "df_ops update" "Run df update software dependencies and so on"
        printf "%-25s: %-50s\n" "df_ops admin idi" "Run df admin tool - import_df_install to reset df_installed collection"
        printf "%-25s: %-50s\n" "df_ops install" "Install df software packages (master)"
        printf "%-25s: %-50s\n" "df_ops install abc" "Install df software packages from abc branch"
    printf "\n"
    exit
}

if [ "$#" -ne 1 ] && [ "$#" -ne 2 ] && [ "$#" -ne 3 ]; then
    usage
fi

action=${1}
service=${2:-default}
mode=${3:-d}

if [ -z ${DF_HOME+x} ]; then
    printf "%-15s: %-50s\n" "[INFO] \$DF_HOME" "unset, exit."
	exit
else
    printf "%-15s: %-50s\n" "[INFO] \$DF_HOME" "Found \$DF_HOME=$DF_HOME"
fi
if [ -z ${DF_APP_MNT+x} ]; then
    printf "%-15s: %-50s\n" "[INFO] \$DF_APP_MNT" "Not Found. Use \$DF_APP_MNT=/mnt"
	DF_APP_MNT=/mnt
fi

if [ -z ${DF_APP_DEP+x} ]; then
	printf "%-15s: %-50s\n" "[INFO] \$DF_APP_DEP" "Not Found. Use \$DF_APP_DEP=/opt"
	DF_APP_DEP=/opt
fi
if [ -z ${DF_CONFIG+x} ]; then
	printf "%-15s: %-50s\n" "[INFO] \$DF_CONFIG" "Not Found. Use \$DF_CONFIG=$DF_HOME/conf"
	DF_CONFIG=$DF_HOME/conf
fi
if [ -z ${DF_LIB+x} ]; then
	printf "%-15s: %-50s\n" "[INFO] \$DF_LIB" "Not Found. Use \$DF_LIB=$DF_HOME/lib"
	DF_LIB=$DF_HOME/lib
fi
if [ -z ${DF_REP+x} ]; then
	printf "%-15s: %-50s\n" "[INFO] \$DF_REP" "Not Found. Use \$DF_REP=$DF_HOME/repo"
	DF_REP=$DF_HOME/repo
fi

DF_KAFKA_CONNECT_REST_PORT=$(grep rest.port $DF_CONFIG/connect-avro-distributed.properties | sed "s/rest.port=//g")
if [ -z ${DF_KAFKA_CONNECT_REST_PORT} ]; then
	DF_KAFKA_CONNECT_REST_PORT=8083
fi

DF_KAFKA_CONNECT_URI="localhost:"$DF_KAFKA_CONNECT_REST_PORT
DF_UPDATE_HIST_FILE_NAME=.df_update_history
DF_APP_CONFIG=${DF_APP_MNT}/etc
DF_APP_LOG=${DF_APP_MNT}/logs
DF_APP_NAME_PREFIX=df-data-service
KAFKA_DAEMON_NAME=SupportedKafka
KAFKA_CONNECT_DAEMON_NAME=connectdistributed
ZOO_KEEPER_DAEMON_NAME=QuorumPeerMain
SCHEMA_REGISTRY_DAEMON_NAME=schemaregistrymain
FLINK_JM_DAEMON_NAME=JobManager
FLINK_TM_DAEMON_NAME=TaskManager
LIVY_JM_DAEMON_NAME=LivyServer
SPARK_JM_DAEMON_NAME=spark.deploy.master
SPARK_TM_DAEMON_NAME=spark.deploy.worker
HADOOP_NN_DAEMON_NAME=NameNode
HADOOP_DN_DAEMON_NAME=DataNode
HIVE_SERVER_DAEMON_NAME=hiveserver2
HIVE_METADATA_NAME=HiveMetaStore

echo "****************Starting DF Operations****************"

format_all () {
rm -rf ${DF_APP_MNT}/kafka-logs/
rm -rf ${DF_APP_MNT}/zookeeper/
rm -rf ${DF_APP_MNT}/dfs/name/*
rm -rf ${DF_APP_MNT}/dfs/data/*
rm -rf ${DF_APP_MNT}/connect.offsets
rm -rf ${DF_APP_LOG}/*
echo "Formatted all data & logs"
hadoop namenode -format -force -nonInteractive > /dev/null 2>&1
echo "Formatted hadoop"
}

start_confluent () {
if [ -h ${DF_APP_DEP}/confluent ]; then
	sid=$(getSID ${ZOO_KEEPER_DAEMON_NAME})
	if [ -z "${sid}" ]; then
		zookeeper-server-start ${DF_APP_CONFIG}/zookeeper.properties 1> ${DF_APP_LOG}/zk.log 2>${DF_APP_LOG}/zk.log &
		sleep 3
	else
		echo "[WARN] Found ZooKeeper daemon running. Please [stop] or [restart] it."
	fi
	echo "[INFO] Started [Zookeeper]"

	sid=$(getSID ${KAFKA_DAEMON_NAME})
	if [ -z "${sid}" ]; then
		kafka-server-start ${DF_APP_CONFIG}/server.properties 1> ${DF_APP_LOG}/kafka.log 2> ${DF_APP_LOG}/kafka.log &
		sleep 3
	else
		echo "[WARN] Found Kafka daemon running. Please [stop] or [restart] it."
	fi
	echo "[INFO] Started [Kafka Server]"

	sid=$(getSID ${SCHEMA_REGISTRY_DAEMON_NAME})
	if [ -z "${sid}" ]; then
		schema-registry-start ${DF_APP_CONFIG}/schema-registry.properties 1> ${DF_APP_LOG}/schema-registry.log 2> ${DF_APP_LOG}/schema-registry.log &
		sleep 5
	else
		echo "[WARN] Found Schema Registry daemon running. Please [stop] or [restart] it."
	fi
	echo "[INFO] Started [Schema Registry]"

	for jar in ${DF_LIB}/*dependencies.jar; do
	  CLASSPATH=${CLASSPATH}:${jar}
	done
	export CLASSPATH

	sid=$(getSID ${KAFKA_CONNECT_DAEMON_NAME})
	if [ -z "${sid}" ]; then
		connect-distributed ${DF_CONFIG}/connect-avro-distributed.properties 1> ${DF_APP_LOG}/distributedkafkaconnect.log 2> ${DF_APP_LOG}/distributedkafkaconnect.log &
		sleep 3
	else
		echo "[WARN] Found Kafka Connect daemon running. Please [stop] or [restart] it."
	fi

	echo "[INFO] Started [Kafka Connect]"
else
	echo "[WARN] Confluent Platform Not Found"
fi
}

stop_confluent () {
if [ -h ${DF_APP_DEP}/confluent ]; then
	echo "[INFO] Shutdown [Schema Registry]"
	schema-registry-stop ${DF_APP_CONFIG}/schema-registry.properties 1> ${DF_APP_LOG}/schema-registry.log 2> ${DF_APP_LOG}/schema-registry.log &
	echo "[INFO] Shutdown [Kafka Server]"
	kafka-server-stop ${DF_APP_CONFIG}/server.properties 1> ${DF_APP_LOG}/kafka.log 2> ${DF_APP_LOG}/kafka.log &
	sleep 15
	sid=$(getSID ${KAFKA_DAEMON_NAME})
	if [ ! -z "${sid}" ]; then
    	kill -9 ${sid}
		echo "[WARN] Kafka PID is killed after 15 sec. time out."
    fi
	echo "[INFO] Shutdown [Zookeeper]"
	zookeeper-server-stop ${DF_APP_CONFIG}/zookeeper.properties 1> ${DF_APP_LOG}/zk.log 2> ${DF_APP_LOG}/zk.log &
	echo "[INFO] Shutdown [Kafka Connect]"
    sid=$(getSID ${KAFKA_CONNECT_DAEMON_NAME})
	if [ ! -z "${sid}" ]; then
    	kill -9 ${sid}
    fi
else
	echo "[WARN] Confluent Not Found"
fi
}

start_flink () {
if [ -h ${DF_APP_DEP}/flink ]; then
	sid=$(getSID ${FLINK_JM_DAEMON_NAME})
	sid2=$(getSID ${FLINK_TM_DAEMON_NAME})
	if [ -z "${sid}" ] && [ -z "${sid2}" ]; then
		start-cluster.sh 1 > /dev/null 2 > /dev/null
		echo "[INFO] Started [Apache Flink]"
		sleep 5
	else
		echo "[WARN] Found Flink daemon running. Please [stop] or [restart]."
	fi
else
	echo "[WARN] Apache Flink Not Found"
fi
}

stop_flink () {
if [ -h ${DF_APP_DEP}/flink ]; then
	stop-cluster.sh 1 > /dev/null 2 > /dev/null
	echo "[INFO] Shutdown [Apache Flink]"
	sleep 3
else
	echo "[WARN] Apache Flink Not Found"
fi
}

start_spark () {
if [ -h ${DF_APP_DEP}/spark ]; then
	sid=$(getSID ${SPARK_JM_DAEMON_NAME})
	sid2=$(getSID ${SPARK_TM_DAEMON_NAME})
	if [ -z "${sid}" ] && [ -z "${sid2}" ]; then
		start-all.sh 1 > /dev/null 2 > /dev/null
		echo "[INFO] Started [Apache Spark]"
		sleep 5
	else
		echo "[WARN] Found Spark daemon running. Please [stop] or [restart]."
	fi
else
	echo "[WARN] Apache Spark Not Found"
fi
}

stop_spark () {
if [ -h ${DF_APP_DEP}/spark ]; then
	stop-all.sh 1 > /dev/null 2 > /dev/null
	echo "[INFO] Shutdown [Apache Spark]"
	sleep 3
else
	echo "[WARN] Apache Spark Not Found"
fi
}

start_livy () {
if [ -h ${DF_APP_DEP}/livy ]; then
	sid=$(getSID ${LIVY_JM_DAEMON_NAME})
	if [ -z "${sid}" ]; then
		${DF_APP_DEP}/livy/bin/livy-server start 1 > /dev/null 2 > /dev/null
		echo "[INFO] Started [Apache Livy]"
		sleep 5
	else
		echo "[WARN] Found Livy daemon running. Please [stop] or [restart]."
	fi
else
	echo "[WARN] Apache Livy Not Found"
fi
}

stop_livy () {
if [ -h ${DF_APP_DEP}/livy ]; then
	${DF_APP_DEP}/livy/bin/livy-server stop
	echo "[INFO] Shutdown [Apache Livy]"
	sleep 3
else
	echo "[WARN] Apache Livy Not Found"
fi
}

start_hadoop () {
if [ -h ${DF_APP_DEP}/hadoop ]; then
	sid=$(getSID ${HADOOP_NN_DAEMON_NAME})
	sid2=$(getSID ${HADOOP_DN_DAEMON_NAME})
	if [ -z "${sid}" ] && [ -z "${sid2}" ]; then
		hadoop-daemon.sh start namenode
		hadoop-daemon.sh start datanode
		echo "[INFO] Started [Hadoop]"
		sleep 3
	else
		echo "[WARN] Found Hadoop daemon running. Please [stop] or [restart] it."
	fi
else
	echo "[WARN] Apache Hadoop Not Found"
fi
if [ -h ${DF_APP_DEP}/hive ]; then
	hive --service metastore 1>> ${DF_APP_LOG}/metastore.log 2>> ${DF_APP_LOG}/metastore.log &
	echo "[INFO] Started [Apache Hive Metastore]"
	hive --service hiveserver2 1>> ${DF_APP_LOG}/hiveserver2.log 2>> ${DF_APP_LOG}/hiveserver2.log &
	echo "[INFO] Started [Apache Hive Server2]"
	sleep 3
else
	echo "[WARN] Apache Hive Not Found"
fi
}

stop_hadoop () {
echo "[INFO] Shutdown Hadoop"
hadoop-daemon.sh stop datanode
hadoop-daemon.sh stop namenode
sid=$(getSID hivemetastore)
kill -9 ${sid} 2> /dev/null
echo "[INFO] Shutdown [Apache Hive MetaStore]"
sleep 2
sid=$(getSID hiveserver2)
kill -9 ${sid} 2> /dev/null
echo "[INFO] Shutdown [Apache Hive Server2]"
}

start_df() {
sid=$(getSID ${DF_APP_NAME_PREFIX})
if [ -z "${sid}" ]; then
	while true; do
		connectStatusCode=$(curl --noproxy '*' -s -o /dev/null -w "%{http_code}" $DF_KAFKA_CONNECT_URI 2> /dev/null)
		if [ "$connectStatusCode" = "200" ]; then
		    sleep 5
			if [[ "${mode}" =~ (^| )d($| ) ]]; then
				java -jar ${DF_HOME}/lib/${DF_APP_NAME_PREFIX}* -d 1> ${DF_APP_LOG}/df.log 2> ${DF_APP_LOG}/df.log &
				echo "[INFO] Started [DF Data Service] in Debug Mode. To see log using tail -f ${DF_APP_LOG}/df.log"
			else
				java -jar ${DF_HOME}/lib/${DF_APP_NAME_PREFIX}* 1> ${DF_APP_LOG}/df.log 2> ${DF_APP_LOG}/df.log &
				echo "[INFO] Started [DF Data Service]. To see log using tail -f ${DF_APP_LOG}/df.log"
			fi
			break
		fi
		echo "[INFO] Waiting for Kafka Connect Service ..."
		sleep 15
	done
else
	echo "[WARN] Found DF daemon running. Please [stop] or [restart] it."
fi
}

stop_df() {
sid=$(getSID $DF_APP_NAME_PREFIX)
if [ -z "${sid}" ]; then
	echo "[WARN] Running DF Data Service Not Found."
else
	kill -9 ${sid}
	echo "[INFO] Shutdown [DF Data Service]"
fi
}

admin_df () {
if [ ! -z "${service}" ]; then
	java -jar ${DF_HOME}/lib/${DF_APP_NAME_PREFIX}* -a ${service}
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
local critical=$3
sid=$(getSID $service_name)
if [ ! -z "${sid}" ]; then
	printf "%-8s %-20s %-50s\n" "[INFO]"  "[$service_name_show]" "is running at [${sid}]"
fi
if [ -z "${sid}" ] && [ ! -z "${critical}" ]; then
	printf "%-8s %-20s %-50s\n" "[ERROR]" "[$service_name_show]" "is missing and mandatory !"
fi
}

start_all_service () {
if [ "${service}" = "min" ]; then
	start_confluent
	start_df
elif [ "${service}" = "max" ]; then
	start_hadoop
	start_confluent
	start_flink
	start_spark
	start_livy
	start_df
elif [ "${service}" = "default" ]; then
	start_confluent
	start_flink
	start_df
elif [ "${service}" = "jar" ]; then
	start_df
elif [ "${service:0:4}" = "mask" ]; then

	if [ "${service:4:1}" == "1" ]; then
	    start_hadoop
	fi
	if [ "${service:5:1}" == "1" ]; then
	    start_confluent
	fi
	if [ "${service:6:1}" == "1" ]; then
	    start_flink
	fi
	if [ "${service:7:1}" == "1" ]; then
	    start_spark
	    start_livy
	fi
	if [ "${service:8:1}" == "1" ]; then
	    start_df
	fi

	if [ "${service}" = "mask" ]; then
	    echo "[ERROR] No proper mask is specified."
	    echo "[INFO] DataFibers start masking setting uses 1 to enable and 0 to disable the service to start"
	    echo "[INFO] 5 bit masking represents service like hadoop (hive), kafka (schema registry), flink, spark (livy), datafibers"
	    echo "[INFO] For example, 'dfops start mask10010' only start hadoop (hive) and spark service"
	fi
else
	echo "[ERROR] No service will start because of wrong command."
fi
}

stop_all_service () {
if [ "${service}" = "min" ]; then
	stop_df
	stop_confluent
elif [ "${service}" = "max" ]; then
	stop_df
	stop_confluent
	stop_livy
	stop_spark
	stop_flink
	stop_hadoop
elif [ "${service}" = "default" ]; then
	stop_df
	stop_confluent
	stop_flink
elif [ "${service}" = "jar" ]; then
	stop_df
else
	echo "[ERROR] No service will stop because of wrong command."
fi
}

restart_all_service () {
stop_all_service
start_all_service
}

status_all () {
    status ${DF_APP_NAME_PREFIX} DataFibers yes
    status ${ZOO_KEEPER_DAEMON_NAME} ZooKeeper yes
    status ${KAFKA_DAEMON_NAME} Kafka yes
    status ${KAFKA_CONNECT_DAEMON_NAME} Kafka_Connect yes
    status ${SCHEMA_REGISTRY_DAEMON_NAME} Schema_Registry yes
    status ${FLINK_JM_DAEMON_NAME} Flink_JobManager
    status ${FLINK_TM_DAEMON_NAME} Flink_TaskManager
    status ${SPARK_JM_DAEMON_NAME} Spark_Master
    status ${SPARK_TM_DAEMON_NAME} Spark_Worker
    status ${LIVY_JM_DAEMON_NAME} Livy_Server
    status ${HADOOP_NN_DAEMON_NAME} HadoopNN
    status ${HADOOP_DN_DAEMON_NAME} HadoopDN
    status ${HIVE_SERVER_DAEMON_NAME} HiveServer2
    status ${HIVE_METADATA_NAME} HiveMetaStore
}

install_df () {
echo "[INFO] Install DataFibers ..."
cd ${DF_HOME}
./bin/install_df.sh ${service} ${DF_HOME}
}

update_df () {
# Setup download folder
if [ ! -d /tmp/vagrant-downloads ]; then
    mkdir -p /tmp/vagrant-downloads
fi
sudo chmod a+rw /tmp/vagrant-downloads

# Check or Create update history file
if [ ! -e $DF_APP_DEP/$DF_UPDATE_HIST_FILE_NAME ]; then
	touch $DF_APP_DEP/$DF_UPDATE_HIST_FILE_NAME
fi

# Fetch new update
cd $DF_REP/df_demo
git pull -q
cd $DF_REP/df_demo/df-update
for update_file in *.update; do
    cd $DF_REP/df_demo/df-update
	if grep -q $update_file $DF_APP_DEP/$DF_UPDATE_HIST_FILE_NAME 2> /dev/null; then
		echo "[IGN] Update [$update_file]."
	else
		echo "[NEW] Update [$update_file]."
		echo "======================================================"
		echo "[INFO] Update Description:"
		echo -e $(grep "update_desc" $update_file | sed "s/update_desc=//g;s/\"//g")
		echo "======================================================"

		if [ "${service}" == "yes" ]; then
		    q1=y
		else
		    read -p "Do you want to apply the update? y/n?" q1
		fi

		if [ "$q1" = "y" ]; then
			# Apply the update
			source $DF_REP/df_demo/df-update/$update_file
			cd ${DF_HOME}
            ./bin/install_soft.sh true $DF_APP_DEP/$install_soft_link $DF_APP_DEP/$install_folder $dl_link

			# Run post run scripts if available
            if [ ! -z "$post_run_script" ]; then
            	echo "[INFO] Running post update script $post_run_script"
            	chmod +x $DF_REP/df_demo/df-update/$post_run_script
            	cd $DF_HOME
            	./repo/df_demo/df-update/$post_run_script
            fi

			#Log in to history
			echo "[INFO] applied $update_file" >> $DF_APP_DEP/$DF_UPDATE_HIST_FILE_NAME
		else
			echo "[INFO] The update [$update_file] is ignored."
		fi
	fi
done
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
	admin_df
elif [ "${action}" = "help" ]; then
	usage
elif [ "${action}" = "update" ]; then
	update_df
else
    echo "[ERROR] Wrong command entered."
    usage
fi