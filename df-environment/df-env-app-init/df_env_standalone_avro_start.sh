#!/bin/bash
set -e

# Starting Hadoop
if [ -h /opt/hadoop ]; then
    echo "Starting Hadoop"
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

# Start Kafka Connect
rm -rf /mnt/connect.offsets

export CLASSPATH=/home/vagrant/df_connect/df-connect-file-generic-0.0.1-SNAPSHOT-jar-with-dependencies.jar

/opt/confluent/bin/connect-standalone /home/vagrant/df_config/connect-avro-standalone.properties /home/vagrant/df_config/connect-dummy.properties 1>> /mnt/logs/kafkaconnect.log 2>> /mnt/logs/kafkaconnect.log &

sleep 20

curl -X "DELETE" http://localhost:8083/connectors/dummy

echo "Start DF Environment Completed with AVRO support. You can see Kafka Connect log at"
echo "tail -f /mnt/logs/kafkaconnect.log"



