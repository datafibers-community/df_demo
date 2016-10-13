#!/bin/bash
set -e

if [ -z "$RELEASE_VERSION" ]; then
  echo "Need to set RELEASE_VERSION, such as export RELEASE_VERSION=0.0.1"
  exit 1
fi

DF_DATA_COLLECTOR=df-data-collector-$RELEASE_VERSION-SNAPSHOT-jar-with-dependencies.jar
DF_DATA_COLLECTOR_DL=https://github.com/datafibers/df/releases/download/v$RELEASE_VERSION/$DF_DATA_COLLECTOR

DF_REACTIVE_SERVER=df-reactive-server-$RELEASE_VERSION-SNAPSHOT-jar-with-dependencies.jar
DF_REACTIVE_SERVER_DL=https://github.com/datafibers/df/releases/download/v$RELEASE_VERSION/$DF_REACTIVE_SERVER

DF_REACTIVE_AGENT=df-reactive-agent-$RELEASE_VERSION-SNAPSHOT-jar-with-dependencies.jar
DF_REACTIVE_AGENT_DL=https://github.com/datafibers/df/releases/download/v$RELEASE_VERSION/$DF_REACTIVE_AGENT

DF_KAFKA_ELASTIC_SINK=kafka-connect-elasticsearch-1.0.0-SNAPSHOT-jar-with-dependencies.jar
DF_KAFKA_ELASTIC_SINK_DL=https://github.com/datafibers/df/releases/download/v0.0.1/kafka-connect-elasticsearch-1.0.0-SNAPSHOT-jar-with-dependencies.jar

if [ ! -e $DF_DATA_COLLECTOR ]; then
	echo "Download relased Jar packages $DF_DATA_COLLECTOR"
	wget $DF_DATA_COLLECTOR_DL
fi

if [ ! -e $DF_REACTIVE_SERVER ]; then
	echo "Download relased Jar packages $DF_REACTIVE_SERVER"
	wget $DF_REACTIVE_SERVER_DL
fi

if [ ! -e $DF_REACTIVE_AGENT ]; then
	echo "Download relased Jar packages $DF_REACTIVE_AGENT"
	wget $DF_REACTIVE_AGENT_DL
fi

if [ ! -e $DF_KAFKA_ELASTIC_SINK ]; then
	echo "Download relased Jar packages $DF_REACTIVE_AGENT"
	wget $DF_KAFKA_ELASTIC_SINK_DL
fi

./clean_up.sh
rm -f /tmp/connect.offsets
./init_all.sh
./start_all.sh
echo "Starting Grafana Server"
sudo service grafana-server start
sleep 5

echo "Setup Kafka Connect for Elastic Sink"
export CLASSPATH=/home/vagrant/kafka-connect-elasticsearch-1.0.0-SNAPSHOT-jar-with-dependencies.jar
/opt/confluent/bin/connect-standalone connect-standalone.properties connect-elasticsearch-sink.properties 1>> /mnt/logs/kafkaconnectelastc.log 2>> /mnt/logs/kafkaconnectelastc.log &

echo "Start DF Server"
java -jar df-reactive-server-0.0.1-SNAPSHOT-jar-with-dependencies.jar 1>> /mnt/logs/dfserver.log 2>> /mnt/logs/dfserver.log &
sleep 5

echo "Start DF Agent"
mkdir -p /home/vagrant/cust_data/
java -jar df-reactive-agent-0.0.1-SNAPSHOT-jar-with-dependencies.jar /home/vagrant/cust_data finance STREAM_KAFKA JSON JRTKC 1>> /mnt/logs/dfagent.log 2>> /mnt/logs/dfagent.log &

echo "Start Data Collector for Demo"
java -jar df-data-collector-0.0.1-SNAPSHOT-jar-with-dependencies.jar /home/vagrant/cust_data/  1>> /mnt/logs/dfdatafetcher.log 2>> /mnt/logs/dfdatafetcher.log &

sleep 5

echo "Setup Elastic Index Mapping"
# curl -XDELETE localhost:9200/kafka_finance
curl -XPOST localhost:9200/kafka_finance -d '{
"settings" : {
"number_of_shards" : 1},
"mappings" : {
"kafka" : {
"properties":{
"ask_price":{"type":"double"},
"ask_size":{"type":"long"},
"bid_price":{"type":"double"},
"bid_size":{"type":"long"},
"exchange":{"type":"string"},
"name":{"type":"string"},
"open_price":{"type":"double"},
"price":{"type":"double"},
"symbol":{"type":"string"},
"time":{"type":"date", "format": "yyy-MM-dd HH:mm:ss"}
}}}}'

echo "All programs are started." 
echo "To see the report, please following manual reports setup procedures"
echo "1. Open you host browser at http://localhost:3000"
echo "2. Login with admin/admin as default"
echo "3. Create the Elastic data source, Name:stocks, Index name:kafka_finance, Time field name:time"
echo "4. Import the dashboard file at ./df-visualisation/dashboard_Grafana/DF Demo Dashboard-1469816495324.JSON"
echo "5. Switch the time range to last 1 year and/or 24hrs to see the visualisation in DF_Demo_Dashboard"


