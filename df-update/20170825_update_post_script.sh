#!/bin/bash
set -e
echo "Post update script will add df_ops and dfops alias to ~.profile."
sed -i '/alias df_ops/d' ~/.profile
sed -i '/alias dfops/d' ~/.profile
echo "alias df_ops='df_ops.sh'" >> ~/.profile
echo "alias dfops='df_ops.sh'" >> ~/.profile
source ~/.profile
echo "Post update script completed."
