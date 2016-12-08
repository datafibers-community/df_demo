#!/bin/bash
set -e

# Starting Hadoop
echo "Formatting Hadoop NameNode"
hadoop namenode -format -force -nonInteractive
