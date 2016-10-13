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

# Starting Hive Metastore
if [ -h /opt/hive ]; then
    echo "Starting Hive Metastore"
    hive --service metastore 1>> /mnt/logs/metastore.log 2>> /mnt/logs/metastore.log &
fi

# Start ElasticSearch
if [ -h /opt/elastic ]; then
    echo "Starting ElasticSearch"
    /opt/elastic/bin/elasticsearch 1>> /mnt/logs/elastic.log 2>> /mnt/logs/elastic.log &
fi

# Start Zeppelin
if [ -h /opt/zeppelin ]; then
    echo "Starting Zeppelin"
    /opt/zeppelin/bin/zeppelin-daemon.sh start
fi



