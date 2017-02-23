#!/bin/bash
echo "************************************************************************"
echo "**************Welcome DataFibers Environment Setup Guide****************"
echo "************************************************************************"
echo "Note: In order to run this guide, make sure following soft are installed"
echo "      1. Vagrant   - https://www.vagrantup.com "
echo "      2. Virtulbox - https://www.virtualbox.org  "
echo "************************************************************************"
echo "* Please go through this guideline to complete the installation/setup. *"
echo "* You can exit by Ctrl+C or 0 from any step.                            *"
echo "************************************************************************"
echo "The default installation includes the following core software along with"
echo "the latest Git, Maven, Java 1.8, MongoDB, and MySQL."
echo "# Apache Hadoop      v2.6.0"
echo "# Apache Hive        v1.2.1"
echo "# Confluent/Kafka    v3.0.1"
echo "# Apache Flink       v1.1.3"

while true; do
    read -p "Q1. Do you want to proceed above installation softwares, y/n?" q1
    case $q1 in
        [y]* ) break;;
        [n]* ) exit;;       
        [0]* ) exit;;
        * ) echo "Please answer y|n or exit with 0.";;     
    esac
done

echo "Q2. There are following optinal software to choose as well"
while true; do
    read -p "Q2.1. Install Apache Zeppelin notebook (~700M), y/n?" q2   
    case $q2 in 
        [y|* ) sed -i '/install_zeppelin=true/a install_zeppelin=true' ./vagrant_shell/deb.sh; break;;
        [n]* ) sed -i '/install_zeppelin=true/a install_zeppelin=false' ./vagrant_shell/deb.sh; break;;      
        [0]* ) exit;;
        * ) echo "Please answer y/n or exit with 0.";;
    esac
done
while true; do
    read -p "Q2.2. Install Elastic Search (~300M), y/n?" q2   
    case $q2 in 
        [y]* ) sed -i '/install_mongo=true/a install_elastic=true' ./vagrant_shell/deb.sh; break;;
        [n]* ) sed -i '/install_mongo=true/a install_elastic=false' ./vagrant_shell/deb.sh; break;;      
        [0]* ) exit;;
        * ) echo "Please answer y/n or exit with 0.";;
    esac
done
while true; do
    read -p "Q2.3. Install Grafana Reporting (~100M), y/n?" q2   
    case $q2 in 
        [y]* ) sed -i '/install_mongo=true/a install_grafana=true' ./vagrant_shell/deb.sh; break;;
        [n]* ) sed -i '/install_mongo=true/a install_grafana=false' ./vagrant_shell/deb.sh; break;;      
        [0]* ) exit;;
        * ) echo "Please answer y/n or exit with 0.";;
    esac
done
while true; do
    read -p "Q2.4. Install Apache Spark (~180M), y/n?" q2   
    case $q2 in 
        [y]* ) sed -i '/install_mongo=true/a install_spark=true' ./vagrant_shell/deb.sh; break;;
        [n]* ) sed -i '/install_mongo=true/a install_spark=false' ./vagrant_shell/deb.sh; break;;      
        [0]* ) exit;;
        * ) echo "Please answer y/n or exit with 0.";;
    esac
done
while true; do
    read -p "Q2.5. Install Apache HBase (~180M), y/n?" q2   
    case $q2 in 
        [y]* ) sed -i '/install_mongo=true/a install_hbase=true' ./vagrant_shell/deb.sh; break;;
        [n]* ) sed -i '/install_mongo=true/a install_hbase=false' ./vagrant_shell/deb.sh; break;;      
        [0]* ) exit;;
        * ) echo "Please answer y/n or exit with 0.";;
    esac
done
while true; do
    read -p "Q2.6. Install Apache Oozie (~320M), y/n?" q2   
    case $q2 in 
        [y]* ) sed -i '/install_mongo=true/a install_oozie=true' ./vagrant_shell/deb.sh; break;;
        [n]* ) sed -i '/install_mongo=true/a install_oozie=false' ./vagrant_shell/deb.sh; break;;      
        [0]* ) exit;;
        * ) echo "Please answer y/n or exit with 0.";;
    esac
done

while true; do
    read -p "Q3. Do you wish to fresh install(i) or update (u) the VM (choose i or u)?" q3
    case $q3 in
        [iI]* ) vagrant up; break;;
        [uU]* ) vagrant provision; break;;       
        [0]* ) exit;;
        * ) echo "Please answer i|u or exit with 0.";;
    esac
done
