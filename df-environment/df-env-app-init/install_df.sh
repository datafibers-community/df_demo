#!/bin/bash
set -e
#check if bc command is available. It uses by progress bar
if ! bc_loc="$(type -p "bc")" || [ -z "$bc_loc" ]; then
  sudo apt-get install -qq bc > /dev/null
fi

branch=${1:-default}
install_dir=${2}

progress_bar()
{
  local PID=$!
  local DURATION=$1
  local INT=0.25      # refresh interval
  local TIME=0
  local CURLEN=0
  local SECS=0
  local FRACTION=0
  local FB=2588       # full block
  local COLS=75       # full bar length

  trap "echo -e $(tput cnorm); trap - SIGINT; return" SIGINT

  echo -ne "$(tput civis)\r$(tput el)│"                # clean line

  local START=$( date +%s%N )

  while [ $SECS -lt $DURATION ]; do
    # local COLS=$( tput cols )
    # main bar
    local L=$( bc -l <<< "( ( $COLS - 5 ) * $TIME  ) / ($DURATION-$INT)" | awk '{ printf "%f", $0 }' )
    local N=$( bc -l <<< $L                                              | awk '{ printf "%d", $0 }' )

    [ $FRACTION -ne 0 ] && echo -ne "$( tput cub 1 )"  # erase partial block

    if [ $N -gt $CURLEN ]; then
      for i in $( seq 1 $(( N - CURLEN )) ); do
        echo -ne \\u$FB
      done
      CURLEN=$N
    fi

    # partial block adjustment
    FRACTION=$( bc -l <<< "( $L - $N ) * 8" | awk '{ printf "%.0f", $0 }' )

    if [ $FRACTION -ne 0 ]; then 
      local PB=$( printf %x $(( 0x258F - FRACTION + 1 )) )
      echo -ne \\u$PB
    fi

    # percentage progress
    local PROGRESS=$( bc -l <<< "( 100 * $TIME ) / ($DURATION-$INT)" | awk '{ printf "%.0f", $0 }' )
    echo -ne "$( tput sc )"                            # save pos
    echo -ne "\r$( tput cuf $(( COLS - 6 )) )"         # move cur
    echo -ne "│ $PROGRESS%"
    echo -ne "$( tput rc )"                            # restore pos

    TIME=$( bc -l <<< "$TIME + $INT" | awk '{ printf "%f", $0 }' )
    SECS=$( bc -l <<<  $TIME         | awk '{ printf "%d", $0 }' )

    # take into account loop execution time
    local END=$( date +%s%N )
    local DELTA=$( bc -l <<< "$INT - ( $END - $START )/1000000000" \
                   | awk '{ if ( $0 > 0 ) printf "%f", $0; else print "0" }' )
    sleep $DELTA
    START=$( date +%s%N )
    # when 95% check if the PID is still running
    if [ $PROGRESS -ge 98 ]; then
        while kill -0 $PID 2> /dev/null; do
           sleep 1
        done
    fi
  done

  echo $(tput cnorm)
  trap - SIGINT
}

if [ -z ${install_dir} ]; then
    CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
else
    CURRENT_DIR=${install_dir}
fi

DF_USER_HOME=/home/vagrant
DF_CONFIG=conf
DF_LIB=lib
DF_DATA=samples
DF_GIT=repo
DF_BIN=bin
DF_GIT_DF_DEMO=df_demo
DF_GIT_DF_SERVICE=df_data_service
DF_GIT_DF_CONNECT=df_certified_connects

echo "[INFO] Start DataFibers installation at $CURRENT_DIR"
echo "[INFO] Step[1/5] - Creating Folders"

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

echo "[INFO] Step[2/5] - Downloading Source"
cd $DF_GIT
rm -rf $DF_GIT_DF_DEMO 
rm -rf $DF_GIT_DF_SERVICE 
rm -rf $DF_GIT_DF_CONNECT 
(git clone -q https://github.com/datafibers-community/$DF_GIT_DF_DEMO.git &&
git clone -q https://github.com/datafibers-community/$DF_GIT_DF_SERVICE.git &&
git clone -q https://github.com/datafibers-community/$DF_GIT_DF_CONNECT.git) & progress_bar 20

if [ "${branch}" == "default" ] ; then
    echo "[INFO] Step[3/5] - Installing Core Service"
    (cd $CURRENT_DIR/$DF_GIT/$DF_GIT_DF_SERVICE && mvn package -DskipTests > /dev/null 2>&1) & progress_bar 30
else
    echo "[INFO] Step[3/5] - Installing Core Service Branch ${branch}"
    (cd $CURRENT_DIR/$DF_GIT/$DF_GIT_DF_SERVICE && git checkout -q ${branch} > /dev/null && mvn package -DskipTests > /dev/null 2>&1) & progress_bar 30
fi

echo "[INFO] Step[4/5] - Installing Certified Connectors"
(cd $CURRENT_DIR/$DF_GIT/$DF_GIT_DF_CONNECT && mvn package -DskipTests > /dev/null 2>&1) & progress_bar 30

cp -r $CURRENT_DIR/$DF_GIT/$DF_GIT_DF_DEMO/df-environment/df-env-vagrant/etc/* $CURRENT_DIR/$DF_CONFIG
cp -r $CURRENT_DIR/$DF_GIT/$DF_GIT_DF_DEMO/df-environment/df-env-vagrant/etc/* /mnt/etc/
cp $CURRENT_DIR/$DF_GIT/$DF_GIT_DF_CONNECT/*/target/*dependencies.jar $CURRENT_DIR/$DF_LIB
cp $CURRENT_DIR/$DF_GIT/$DF_GIT_DF_CONNECT/resources/jdbc_driver/*dependencies.jar $CURRENT_DIR/$DF_LIB
cp $CURRENT_DIR/$DF_GIT/$DF_GIT_DF_SERVICE/target/*fat.jar $CURRENT_DIR/$DF_LIB

echo "[INFO] Step[5/5] - Applying Patches and Settings"
# Map Flink Web Console port to 8001
rm -f /opt/flink/conf/flink-conf.yaml.bk
cp /opt/flink/conf/flink-conf.yaml /opt/flink/conf/flink-conf.yaml.bk
cp $CURRENT_DIR/$DF_CONFIG/flink/flink-conf.yaml /opt/flink/conf/

cp $CURRENT_DIR/$DF_GIT/$DF_GIT_DF_DEMO/df-environment/df-env-app-init/*.sh $CURRENT_DIR/$DF_BIN
chmod +x $CURRENT_DIR/$DF_BIN/*.sh
dos2unix -q $CURRENT_DIR/$DF_BIN/**
sudo chown -R vagrant:vagrant $CURRENT_DIR/*

sed -i '/DF_HOME/d' $DF_USER_HOME/.profile
sed -i '/alias df_ops/d' $DF_USER_HOME/.profile
sed -i '/alias dfops/d' $DF_USER_HOME/.profile

echo "export DF_HOME=\"$CURRENT_DIR\"" >> $DF_USER_HOME/.profile
echo "PATH=\"\$DF_HOME/bin:\$PATH\"" >> $DF_USER_HOME/.profile
echo "alias df_ops='df_ops.sh'" >> $DF_USER_HOME/.profile
echo "alias dfops='df_ops.sh'" >> $DF_USER_HOME/.profile
source $DF_USER_HOME/.profile

echo "[INFO] Complete DataFibers Installation! :)" 

