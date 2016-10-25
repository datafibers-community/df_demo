#!/bin/bash

#Install profile - development
dl_link_hadoop=http://mirrors.koehn.com/apache/hadoop/common/hadoop-2.6.0/hadoop-2.6.0.tar.gz
install_hadoop=true

dl_link_hive=http://apache.parentingamerica.com/hive/hive-1.2.1/apache-hive-1.2.1-bin.tar.gz
install_hive=true

release_confluent=-2.11
dl_link_confluent=http://packages.confluent.io/archive/3.0/confluent-3.0.1-2.11.tar.gz
install_confluent=true

release_confluent=-bin-hadoop26-scala_2.11
dl_link_flink=http://apache.mirror.gtcomm.net/flink/flink-1.1.3/flink-1.1.3-bin-hadoop26-scala_2.11.tgz
install_flink=true

install_mongo=true

dl_link_elastic=https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/2.3.4/elasticsearch-2.3.4.tar.gz
install_elastic=false

dl_link_zeppelin=http://mirror.its.dal.ca/apache/zeppelin/zeppelin-0.6.0/zeppelin-0.6.0-bin-all.tgz
install_zeppelin=false

dl_link_grafana=https://grafanarel.s3.amazonaws.com/builds/grafana_3.1.0-1468321182_amd64.deb
install_grafana=false

set -e

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
soft_install $install_flink flink $dl_link_flink

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

# Get lastest init scripts
rm -f master.zip
rm -rf df_demo-master
wget --progress=bar:force https://github.com/datafibers-community/df_demo/archive/master.zip
unzip master.zip
cp df_demo-master/df-environment/df-env-app-init/* /home/vagrant/
chmod +x *.sh
rm -rf master.zip
