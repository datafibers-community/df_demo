#!/bin/bash
set -e

#install flags
install_java=true

install_hadoop=true
install_hive=true
install_confluent=true
install_flink=true
install_mongo=true
install_elastic=false
install_zeppelin=false
install_spark=false
install_hbase=false
install_oozie=false

#software repository links
dl_link_hadoop=https://archive.apache.org/dist/hadoop/common/hadoop-2.6.0/hadoop-2.6.0.tar.gz
dl_link_hive=https://archive.apache.org/dist/hive/hive-1.2.1/apache-hive-1.2.1-bin.tar.gz
release_confluent=-2.11
#dl_link_confluent=http://packages.confluent.io/archive/3.1/confluent-3.1.1-2.11.tar.gz
dl_link_confluent=http://packages.confluent.io/archive/3.0/confluent-3.0.1-2.11.tar.gz
release_flink=-bin-hadoop26-scala_2.11
dl_link_flink=http://www-us.apache.org/dist/flink/flink-1.3.2/flink-1.3.2-bin-hadoop26-scala_2.11.tgz
dl_link_elastic=https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/2.3.4/elasticsearch-2.3.4.tar.gz
dl_link_zeppelin=https://archive.apache.org/dist/zeppelin/zeppelin-0.7.2/zeppelin-0.7.2-bin-all.tgz
dl_link_grafana=https://grafanarel.s3.amazonaws.com/builds/grafana_3.1.0-1468321182_amd64.deb
dl_link_spark=https://archive.apache.org/dist/spark/spark-1.6.0/spark-1.6.0-bin-hadoop2.6.tgz
release_hbase=-bin
dl_link_hbase=https://archive.apache.org/dist/hbase/1.3.0/hbase-1.3.0-bin.tar.gz
dl_link_oozie=https://archive.apache.org/dist/oozie/4.3.0/oozie-4.3.0.tar.gz

# sample call install_flag soft_install dl_link, such as
# soft_install $install_hadoop hadoop $dl_link_hadoop

function soft_install
{
    install_flag=${1:-false}
	install_soft_link=/opt/$2
    dl_link=$3
	release_version=$4

	if [ "$install_flag" = true ]; then
		file_name=`basename $dl_link`

		case $file_name in
			(*.tar.gz) install_folder=/opt/`basename $file_name .tar.gz`;;
			(*.tar) install_folder=/opt/`basename $file_name .tar`;;
			(*.tgz) install_folder=/opt/`basename $file_name .tgz`;;
		esac

		#remove release number for confluent, which has release number in URL, but not in the unzip folder
		install_folder=${install_folder//$release_version}

		echo "install_flag=$install_flag"
		echo "dl_link=$dl_link"
		echo "file_name=$file_name"
		echo "install_folder=$install_folder"
		echo "install_soft_link=$install_soft_link"

		pushd /opt/

        if [ ! -e $install_folder ]; then
            pushd /tmp/vagrant-downloads
            if [ ! -e $file_name ]; then
                wget --progress=bar:force $dl_link --no-check-certificate
            fi
            popd
            tar xzf /tmp/vagrant-downloads/$file_name
            ln -sfn $install_folder $install_soft_link
        fi
		echo "completed installing ${2} with version ${file_name}"
		popd
    fi
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
    sudo rm -f /etc/apt/sources.list.d/mongodb*.list
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
    echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
    sudo apt-get update
    sudo apt-get install -y mongodb-org
fi

#Install Java 8
JAVA_VER=$(java -version 2>&1 | grep -i version | sed 's/.*version ".*\.\(.*\)\..*"/\1/; 1q')
if [ "$JAVA_VER" != "8" ] && [ "$install_java" = "true" ]; then
    echo "installing java 8 ..."
    cd /opt/
    wget --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u141-b15/336fa29ff2bb4ef291e347e091f7f4a7/jdk-8u141-linux-x64.tar.gz
    tar -zxf jdk-8u141-linux-x64.tar.gz
    ln -sfn /opt/jdk1.8.0_141 /opt/jdk
    sudo update-alternatives --install /usr/bin/java java /opt/jdk/bin/java 8000
    sudo update-alternatives --install /usr/bin/javac javac /opt/jdk/bin/javac 8000
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

echo "***************************************************************************************"
echo "*DataFibers Virtual Machine Setup Completed.                                          *"
echo "*Note, Flink Web Console port maps to 8001 from 8081 which is used by Schema Registry.*"
echo "*SSH address:127.0.0.1:2222.                                                          *"
echo "*SSH username/password:vagrant/vagrant                                                *"
echo "*Command: ssh vagrant@localhost -p 2222                                               *"
echo "***************************************************************************************"
