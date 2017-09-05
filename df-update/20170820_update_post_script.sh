#!/bin/bash
set -e

if [ -z ${DF_HOME+x} ]; then
	echo "DF_HOME is unset, exit"
	exit
else
	echo "DF_HOME Not Found, use DF_HOME=$DF_HOME ";
fi
if [ -z ${DF_APP_MNT+x} ]; then
	DF_APP_MNT=/mnt
fi

if [ -z ${DF_APP_DEP+x} ]; then
	DF_APP_DEP=/opt
fi
if [ -z ${DF_CONFIG+x} ]; then
	DF_CONFIG=$DF_HOME/conf
fi
if [ -z ${DF_LIB+x} ]; then
	DF_LIB=$DF_HOME/lib
fi
if [ -z ${DF_REP+x} ]; then
	DF_REP=$DF_HOME/repo
fi

mv ${DF_APP_DEP}/flink/conf/flink-conf.yaml ${DF_APP_DEP}/flink/conf/flink-conf.yaml.bk
cp ${DF_REP}/df_demo/df-environment/df-env-vagrant/etc/flink/flink-conf.yaml ${DF_APP_DEP}/flink/conf/
echo "[INFO] Post update script is applied to map Flink rest port to 8001 from 8030."
