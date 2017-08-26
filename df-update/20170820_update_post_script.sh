#!/bin/bash
set -e

if [ -z ${DF_HOME+x} ]; then
	echo "DF_HOME is unset, exit"
	exit
else
	echo "DF_HOME is set, use DF_HOME=$DF_HOME ";
fi
if [ -z ${DF_APP_MNT+x} ]; then
	echo "DF_APP_MNT is unset, use DF_APP_MNT=/mnt ";
	DF_APP_MNT=/mnt
fi

if [ -z ${DF_APP_DEP+x} ]; then
	echo "DF_APP_DEP is unset, use DF_APP_DEP=/opt ";
	DF_APP_DEP=/opt
fi
if [ -z ${DF_CONFIG+x} ]; then
	echo "DF_CONFIG is unset, use DF_CONFIG=$DF_HOME/conf ";
	DF_CONFIG=$DF_HOME/conf
fi
if [ -z ${DF_LIB+x} ]; then
	echo "DF_LIB is unset, use DF_LIB=$DF_HOME/lib ";
	DF_LIB=$DF_HOME/lib
fi
if [ -z ${DF_REP+x} ]; then
	echo "DF_REP is unset, use DF_REP=$DF_HOME/repo ";
	DF_REP=$DF_HOME/repo
fi

echo "Post update script will map rest api to 8001 to avoid conflict with Kafka connect at 8030."
mv ${DF_APP_DEP}/flink/conf/flink-conf.yaml ${DF_APP_DEP}/flink/conf/flink-conf.yaml.bk
cp ${DF_REP}/df_demo/df-environment/df-env-vagrant/etc/flink/flink-conf.yaml ${DF_APP_DEP}/flink/conf/
echo "Post update script completed."
