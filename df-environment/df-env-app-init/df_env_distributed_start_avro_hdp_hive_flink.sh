#!/bin/bash
set -e
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Starting Hadoop
if [ -h /opt/hadoop ]; then
    echo "Starting Hadoop. Make sure you format HDP using init_all.sh if any error happens"
    hadoop-daemon.sh start namenode
    hadoop-daemon.sh start datanode
fi

# Starting Confluent Platform
if [ -h /opt/confluent ]; then
    echo "Starting Confluent Kafka"
    zookeeper-server-start /mnt/etc/zookeeper.properties 1>> /mnt/logs/zk.log 2>>/mnt/logs/zk.log &
    sleep 5
    kafka-server-start /mnt/etc/server.properties 1>> /mnt/logs/kafka.log 2>> /mnt/logs/kafka.log &
    sleep 5
    schema-registry-start /mnt/etc/schema-registry.properties 1>> /mnt/logs/schema-registry.log 2>> /mnt/logs/schema-registry.log &
    sleep 5
fi

# Starting Flink
if [ -h /opt/flink ]; then
    echo "Starting Apache Flink"
    /opt/flink/bin/start-cluster.sh
fi

# Starting Hive Metastore and server2
if [ -h /opt/hive ]; then
    echo "Starting Hive Metastore"
    hive --service metastore 1>> /mnt/logs/metastore.log 2>> /mnt/logs/metastore.log &
	echo "Starting Hive Server2"
    hive --service hiveserver2 1>> /mnt/logs/hiveserver2.log 2>> /mnt/logs/hiveserver2.log &
fi

for jar in $CURRENT_DIR/df_connect/*.jar; do
  CLASSPATH=${CLASSPATH}:${jar}
done
export CLASSPATH

rm -f /mnt/logs/distributedkafkaconnect.log
/opt/confluent/bin/connect-distributed $CURRENT_DIR/df_config/connect-avro-distributed.properties 1>> /mnt/logs/distributedkafkaconnect.log 2>> /mnt/logs/distributedkafkaconnect.log &

echo "Starting DF Environment Complete"
echo "You can find all log files at /mnt/logs/"
echo "You can start DF applications now ..."

