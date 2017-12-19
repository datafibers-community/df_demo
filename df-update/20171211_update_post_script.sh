#!/bin/bash
set -e
echo "[INFO] Copying configuration files"

if [ "$install_spark" = true ]; then
  cp /mnt/etc/hive/hive-site.xml /opt/spark/conf/
  cp /mnt/etc/spark/* /opt/spark/conf/
fi

if [ "$install_livy" = true ]; then
  cp /mnt/etc/livy/* /opt/livy/conf/
fi

echo "Copied configuration files "