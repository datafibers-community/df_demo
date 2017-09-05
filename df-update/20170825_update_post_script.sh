#!/bin/bash
set -e
sed -i '/alias df_ops/d' ~/.profile
sed -i '/alias dfops/d' ~/.profile
echo "alias df_ops='df_ops.sh'" >> ~/.profile
echo "alias dfops='df_ops.sh'" >> ~/.profile
source ~/.profile
echo "[INFO] Post update script is applied to add df_ops & dfops alias to ~.profile."
