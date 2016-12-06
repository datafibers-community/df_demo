#!/bin/bash
set -e

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

# Start Kafka Connect
rm -rf /mnt/connect.offsets

export CLASSPATH=/home/vagrant/df_connect/df-connect-file-generic-0.0.1-SNAPSHOT-jar-with-dependencies.jar

/opt/confluent/bin/connect-standalone /home/vagrant/df_config/connect-avro-standalone.properties /home/vagrant/df_config/connect-dummy.properties



