#!/bin/bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -e
echo "Starting installation DF packages at $CURRENT_DIR."
echo "Step (1/3). Creating df folders start"
echo "	df_config: 	where we put all configuration files"
echo "	df_connect:	where we put certified df connect jars"
echo "	df_data: 	where we put test data"
echo "	df_git: 	where we download source code for build"
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
if [ ! -d df_git ]; then
    mkdir -p df_git
fi

echo "Step (1/3). Creating df folders complete"

echo "Step (2/3). Downloading DF source and build start"
cd df_git
rm -rf df_demo
rm -rf df_data_service
rm -rf df_certified_connects
git clone https://github.com/datafibers-community/df_demo.git
git clone https://github.com/datafibers-community/df_data_service.git
git clone https://github.com/datafibers-community/df_certified_connects.git

cd $CURRENT_DIR/df_git/df_data_service
mvn package -DskipTests
cd $CURRENT_DIR/df_git/df_certified_connects
mvn package -DskipTests

cp -r $CURRENT_DIR/df_git/df_demo/df-environment/df-env-vagrant/etc/* $CURRENT_DIR/df_config
cp $CURRENT_DIR/df_git/df_certified_connects/df-connect-file-generic/target/*.jar $CURRENT_DIR/df_connect
cp $CURRENT_DIR/df_git/df_data_service/target/*fat.jar $CURRENT_DIR
ln -sf $CURRENT_DIR/df_connect/df-connect-file-generic-*-SNAPSHOT.jar $CURRENT_DIR/df_connect/df-connect-file-generic.jar

echo "Step (2/3). Downloading DF source and build complete"

echo "Step (3/3). Applying patch on Flink web ui port start"
# Map Flink Web Console port to 8001
rm -f /opt/flink/conf/flink-conf.yaml.bk
cp /opt/flink/conf/flink-conf.yaml /opt/flink/conf/flink-conf.yaml.bk
cp $CURRENT_DIR/df_config/flink/flink-conf.yaml /opt/flink/conf/
echo "Step (3/3). Applying patch on Flink web ui port complete"

cd $CURRENT_DIR/
cp $CURRENT_DIR/df_git/df_demo/df-environment/df-env-app-init/df* $CURRENT_DIR
chmod +x *.sh

echo "All DF packages are installed successfully." 


