#!/bin/bash
set -e

# Starting Hadoop
echo "Formatting Hadoop NameNode Start"
hadoop namenode -format -force -nonInteractive > /dev/null 2>&1
echo "Formatting Hadoop NameNode Complete"
