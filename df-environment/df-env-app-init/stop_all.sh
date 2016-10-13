#!/bin/bash
set -e

# Shutdown Confluent Platform
if [ -h /opt/confluent ]; then
    echo "Shutting down Confluent Platform"
    schema-registry-stop /mnt/etc/schema-registry.properties 1>> /mnt/logs/schema-registry.log 2>> /mnt/logs/schema-registry.log &
    kafka-server-stop /mnt/etc/server.properties 1>> /mnt/logs/kafka.log 2>> /mnt/logs/kafka.log &
    zookeeper-server-stop /mnt/etc/zookeeper.properties 1>> /mnt/logs/zk.log 2>>/mnt/logs/zk.log &
fi

# Shutdown Hadoop
if [ -h /opt/hadoop ]; then
    echo "Shutting down Hadoop"
    hadoop-daemon.sh stop datanode
    hadoop-daemon.sh stop namenode
fi

# Stop Zeppelin
if [ -h /opt/zeppelin ]; then
    echo "Shutting down Zeppelin"
    /opt/zeppelin/bin/zeppelin-daemon.sh stop
fi

# Shutdown Hive Metastore and ElasticSearch
echo "Shutting down all other Java process, Hive Meta, ElasticSearch"
killall java





