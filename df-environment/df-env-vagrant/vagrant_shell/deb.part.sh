
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

# Install Grafana
if [ "$install_grafana" = true ]; then 
    echo "Install - Grafana Reporting"
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

# Get lastest init scripts
rm -rf gitrepo
mkdir gitrepo
cd gitrepo
git clone https://github.com/datafibers-community/df_demo.git
git clone https://github.com/datafibers-community/df_data_service.git
git clone https://github.com/datafibers-community/df_certified_connects.git

cp df_demo/df-environment/df-env-app-init/* /home/vagrant/
cd /home/vagrant/
chmod +x *.sh

echo "DataFibers Virtual Machine Setup Completed."
echo "Note, Flink Web Admin Console's port maps to 8001 to avoid conflict with Schema Registry Service."
echo "SSH address:127.0.0.1:2222. "
echo "SSH username/password:vagrant/vagrant"
