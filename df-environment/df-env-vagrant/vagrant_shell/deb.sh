#!/bin/bash
set -e

#install flags
install_hadoop=true
install_hive=true
install_confluent=true
install_flink=true
install_mongo=true

#software repository links
dl_link_hadoop=https://archive.apache.org/dist/hadoop/common/hadoop-2.6.0/hadoop-2.6.0.tar.gz
dl_link_hive=http://apache.parentingamerica.com/hive/hive-1.2.1/apache-hive-1.2.1-bin.tar.gz
release_confluent=-2.11
#dl_link_confluent=http://packages.confluent.io/archive/3.1/confluent-3.1.1-2.11.tar.gz
dl_link_confluent=http://packages.confluent.io/archive/3.0/confluent-3.0.1-2.11.tar.gz
release_flink=-bin-hadoop26-scala_2.11
dl_link_flink=http://apache.mirror.globo.tech/flink/flink-1.2.0/flink-1.2.0-bin-hadoop26-scala_2.11.tgz
dl_link_elastic=https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/2.3.4/elasticsearch-2.3.4.tar.gz
dl_link_zeppelin=http://muug.ca/mirror/apache-dist/zeppelin/zeppelin-0.7.0/zeppelin-0.7.0-bin-all.tgz
dl_link_grafana=https://grafanarel.s3.amazonaws.com/builds/grafana_3.1.0-1468321182_amd64.deb
dl_link_spark=http://d3kbcqa49mib13.cloudfront.net/spark-2.1.0-bin-hadoop2.6.tgz
release_hbase=-bin
dl_link_hbase=http://apache.mirror.globo.tech/hbase/stable/hbase-1.2.4-bin.tar.gz
dl_link_oozie=http://apache.mirror.vexxhost.com/oozie/4.3.0/oozie-4.3.0.tar.gz

# sample call install_flag soft_install dl_link, such as
# soft_install $install_hadoop hadoop $dl_link_hadoop

function soft_install
{
    install_flag=$1
    dl_link=$3
    file_name=`basename $dl_link`

    case $file_name in
        (*.tar.gz) install_folder=/opt/`basename $file_name .tar.gz`;;
        (*.tar) install_folder=/opt/`basename $file_name .tar`;;
        (*.tgz) install_folder=/opt/`basename $file_name .tgz`;;
    esac

    install_soft_link=/opt/$2
    release_version=$4

    #remove release number for confluent, which has release number in URL, but not in the unzip folder
    install_folder=${install_folder//$release_version}

    echo "$install_flag"
    echo "$dl_link"
    echo "$file_name"
    echo "$install_folder"
    echo "$install_soft_link"

    pushd /opt/

    if [ "$install_flag" = true ]; then

        echo "Start installing ${2} with version ${file_name}"

        if [ ! -e $install_folder ]; then
            pushd /tmp/vagrant-downloads
            if [ ! -e $file_name ]; then
                wget --progress=bar:force $dl_link
            fi
            popd
            tar xvzf /tmp/vagrant-downloads/$file_name
            ln -sfn $install_folder $install_soft_link
        fi
    fi
    popd
}

# Setup install staging folders
if [ ! -d /tmp/vagrant-downloads ]; then
    mkdir -p /tmp/vagrant-downloads
fi
chmod a+rw /tmp/vagrant-downloads

chmod a+rw /opt

if [ ! -e /mnt ]; then
    mkdir /mnt
fi
chmod a+rwx /mnt

sudo apt-get -y update

# Install and configure Apache Hadoop
echo "install - hdp"
soft_install $install_hadoop hadoop $dl_link_hadoop

# Install and configure Hive
soft_install $install_hive hive $dl_link_hive

# Install CP
soft_install $install_confluent confluent $dl_link_confluent $release_confluent

# Install Elastic
soft_install $install_elastic elastic $dl_link_elastic

# Install Zeppelin
soft_install $install_zeppelin zeppelin $dl_link_zeppelin

# Install Flink
soft_install $install_flink flink $dl_link_flink $release_flink

# Install Spark
soft_install $install_spark spark $dl_link_spark

# Install HBase
soft_install $install_hbase hbase $dl_link_hbase $release_hbase

# Install Oozie
soft_install $install_oozie oozie $dl_link_oozie

# Install Grafana
if [ "$install_grafana" = true ]; then
    grafana_file_name=$(basename $dl_link_grafana)
    if [ ! -e $grafana_file_name ]; then
        wget --progress=bar:force $dl_link_grafana
    fi
    sudo apt-get install -y adduser libfontconfig
    sudo dpkg -i $grafana_file_name
fi

# Install MongoDB
if [ "$install_mongo" = true ]; then
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org
fi

#Install Maven and Git
sudo apt-get install -y maven git
sudo apt-get install dos2unix

# Convert all files to Linux in case git setting wrong in Win
find /vagrant/ -type f -print0 | xargs -0 dos2unix --

# Copy .profile and change owner to vagrant
cp /vagrant/.profile /home/vagrant/
chown vagrant:vagrant /home/vagrant/.profile
source /home/vagrant/.profile

cp -r /vagrant/etc /mnt/
chown -R vagrant:vagrant /mnt/etc
mkdir -p /mnt/logs
chown -R vagrant:vagrant /mnt/logs

mkdir -p /mnt/dfs/name
mkdir -p /mnt/dfs/data

chown -R vagrant:vagrant /mnt/dfs
chown -R vagrant:vagrant /mnt/dfs/name
chown -R vagrant:vagrant /mnt/dfs/data
sudo chown -R vagrant:vagrant /opt

# Map Flink Web Console port to 8001
mv /opt/flink/conf/flink-conf.yaml /opt/flink/conf/flink-conf.yaml.bk
cp /mnt/etc/flink/flink-conf.yaml /opt/flink/conf/

# Enable mongodb access from out side of vm
sudo mv /etc/mongod.conf /etc/mongod.conf.bk
cp /mnt/etc/mongo/mongod.conf /etc/

# Install MySQL Metastore for Hive - do this after creating profiles in order to use hive schematool
sudo apt-get -y update
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password mypassword'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password mypassword'
sudo apt-get -y install mysql-server
sudo apt-get -y install libmysql-java

sudo ln -sfn /usr/share/java/mysql-connector-java.jar /opt/hive/lib/mysql-connector-java.jar
sudo ln -sfn /usr/share/java/mysql-connector-java.jar /opt/confluent/share/java/kafka-connect-jdbc/mysql-connector-java.jar

# Configure Hive Metastore
mysql -u root --password="mypassword" -f \
-e "DROP DATABASE IF EXISTS metastore;"

mysql -u root --password="mypassword" -f \
-e "CREATE DATABASE IF NOT EXISTS metastore;"

mysql -u root --password="mypassword" \
-e "GRANT ALL PRIVILEGES ON metastore.* TO 'hive'@'localhost' IDENTIFIED BY 'mypassword'; FLUSH PRIVILEGES;"

schematool -dbType mysql -initSchema

echo "***********************************************************************************************"
echo "* 	DataFibers Virtual Machine Setup Completed."
echo "*		Note, Flink Web Console port maps to 8001 from 8081 which is used by Schema Registry."
echo "*		SSH address:127.0.0.1:2222."
echo "*		SSH username/password:vagrant/vagrant"
echo "*		Command: ssh vagrant@localhost -p 2222"
echo "***********************************************************************************************"
