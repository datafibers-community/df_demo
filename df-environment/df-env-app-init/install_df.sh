#!/bin/bash
function progress_bar
{
    installed=$1
    PID=$! 
    echo "PLEASE BE PATIENT WHILE [$installed] IS ONGOING..."
    printf "["
    # While process is running...
    while kill -0 $PID 2> /dev/null; do 
        printf  "▓"
        sleep 1
    done
    printf "] $installed IS COMPLETED!"
    echo
}

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DF_CONFIG=conf
DF_LIB=lib
DF_DATA=samples
DF_GIT=repo
DF_BIN=bin
DF_GIT_DF_DEMO=df_demo
DF_GIT_DF_SERVICE=df_data_service
DF_GIT_DF_CONNECT=df_certified_connects

set -e
echo "Starting installation DF packages at $CURRENT_DIR."
echo "Step[1/3]-Creating df folders started"
printf "%-15s: %-50s\n" "$DF_CONFIG" "where to find configuration files"
printf "%-15s: %-50s\n" "$DF_LIB" "where to find certified df connect and service jars"
printf "%-15s: %-50s\n" "$DF_DATA" "where to find sample or test data"
printf "%-15s: %-50s\n" "$DF_GIT" "where to find source code"
printf "%-15s: %-50s\n" "$DF_BIN" "where to find scripts for run and admin"

if [ ! -d $DF_CONFIG ]; then
    mkdir -p $DF_CONFIG
fi
if [ ! -d $DF_LIB ]; then
    mkdir -p $DF_LIB
fi
if [ ! -d $DF_DATA ]; then
    mkdir -p $DF_DATA
fi
if [ ! -d $DF_GIT ]; then
    mkdir -p $DF_GIT
fi
if [ ! -d $DF_BIN ]; then
    mkdir -p $DF_BIN
fi
echo "Step[1/3]-Creating df folders completed"

echo "Step[2/3]-Downloading DF source and build started"
cd $DF_GIT
rm -rf $DF_GIT_DF_DEMO 
rm -rf $DF_GIT_DF_SERVICE 
rm -rf $DF_GIT_DF_CONNECT 
git clone -q https://github.com/datafibers-community/$DF_GIT_DF_DEMO.git
git clone -q https://github.com/datafibers-community/$DF_GIT_DF_SERVICE.git
git clone -q https://github.com/datafibers-community/$DF_GIT_DF_CONNECT.git

(cd $CURRENT_DIR/$DF_GIT/$DF_GIT_DF_SERVICE && mvn package -DskipTests > /dev/null 2>&1) & 

progress_bar Compiling_DF_Service

(cd $CURRENT_DIR/$DF_GIT/$DF_GIT_DF_CONNECT && mvn package -DskipTests > /dev/null 2>&1) &

progress_bar Compiling_DF_Connectors

cp -r $CURRENT_DIR/$DF_GIT/$DF_GIT_DF_DEMO/df-environment/df-env-vagrant/etc/* $CURRENT_DIR/$DF_CONFIG
cp -r $CURRENT_DIR/$DF_GIT/$DF_GIT_DF_DEMO/df-environment/df-env-vagrant/etc/* /mnt/etc/
cp $CURRENT_DIR/$DF_GIT/$DF_GIT_DF_CONNECT/*/target/*dependencies.jar $CURRENT_DIR/$DF_LIB
cp $CURRENT_DIR/$DF_GIT/$DF_GIT_DF_SERVICE/target/*fat.jar $CURRENT_DIR/$DF_LIB

echo "Step[2/3]-Downloading DF source and build completed"

echo "Step[3/3]-Applying patch on Flink web ui port started"
# Map Flink Web Console port to 8001
rm -f /opt/flink/conf/flink-conf.yaml.bk
cp /opt/flink/conf/flink-conf.yaml /opt/flink/conf/flink-conf.yaml.bk
cp $CURRENT_DIR/$DF_CONFIG/flink/flink-conf.yaml /opt/flink/conf/
echo "Step[3/3]-Applying patch on Flink web ui port completed"

cp $CURRENT_DIR/$DF_GIT/$DF_GIT_DF_DEMO/df-environment/df-env-app-init/df* $CURRENT_DIR/$DF_BIN
chmod +x $CURRENT_DIR/$DF_BIN/*.sh
dos2unix -q $CURRENT_DIR/$DF_BIN/**
sudo chown -R vagrant:vagrant $CURRENT_DIR/$DF_BIN/*.sh

sed -i '/DF_HOME/d' ~/.profile
echo "export DF_HOME=\"$CURRENT_DIR\"" >> ~/.profile
echo "PATH=\"\$DF_HOME/bin:\$PATH\"" >> ~/.profile
source ~/.profile

echo "All DataFibers packages are installed successfully." 

