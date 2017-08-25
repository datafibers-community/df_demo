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

# Starting Flink
if [ -h /opt/flink ]; then
    echo "Starting Apache Flink"
    /opt/flink/bin/start-cluster.sh
fi

for jar in $DF_HOME/lib/*.jar; do
  CLASSPATH=${CLASSPATH}:${jar}
done
export CLASSPATH

rm -f /mnt/logs/distributedkafkaconnect.log
/opt/confluent/bin/connect-distributed $DF_HOME/conf/connect-avro-distributed.properties 1>> /mnt/logs/distributedkafkaconnect.log 2>> /mnt/logs/distributedkafkaconnect.log &

echo "Starting DF Environment Complete"
echo "You can find all log files at /mnt/logs/"
echo "You can start DF applications now ..."

