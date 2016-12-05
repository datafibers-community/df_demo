#!/bin/bash
set -e
cd ~
echo "Starting installation DF packages."
echo "Creating following folders"
echo "	df_config - where we put all configuration files"
echo "	df_connect - where we put certified df connect jars"
echo "	df_data - where we put test data"
echo "	gitrepo - where we download source code for build"
sleep 5

if [ ! -d df_config ]; then
    mkdir -p df_config
fi
if [ ! -d df_connect ]; then
    mkdir -p df_connect
fi
if [ ! -d df_data ]; then
    mkdir -p df_data
fi
if [ ! -d gitrepo ]; then
    mkdir -p gitrepo
fi

cd gitrepo
rm -rf df_demo
rm -rf df_data_service
rm -rf df_certified_connects
git clone https://github.com/datafibers-community/df_demo.git
git clone https://github.com/datafibers-community/df_data_service.git
git clone https://github.com/datafibers-community/df_certified_connects.git

echo "Building DF Jars..."

cd /home/vagrant/gitrepo/df_data_service
mvn mvn package -DskipTests
cd /home/vagrant/gitrepo/df_certified_connects
mvn mvn package -DskipTests

cp /home/vagrant/gitrepo/df_demo/df-environment/df-env-vagrant/etc/* /home/vagrant/df_config
cp /home/vagrant/gitrepo/df_data_certified_connects/target/*fat.jar /home/vagrant/df_connect
cp /home/vagrant/gitrepo/df_demo/df-environment/df-env-app-init/* /home/vagrant/
cp /home/vagrant/gitrepo/df_data_service/target/*fat.jar /home/vagrant/

cd /home/vagrant/
chmod +x *.sh

echo "All packages are installed successfully." 
echo "You can run ./df_env_start_kafka_flink.sh to start df running environment."
echo "Open another termial to start df jar, such as java -jar df-data-service-1.1-SNAPSHOT-fat"


