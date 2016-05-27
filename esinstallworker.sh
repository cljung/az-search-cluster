#!/bin/bash

echo $(date +"%F %T%z") "starting script esinstallworker.sh"

# arguments
clustername=$1
numberOfNodes=$2
hostbase=$3
accountname=$4
accountkey=$5

# https://github.com/Azure/WALinuxAgent/issues/178
yum update -y --exclude=WALinuxAgent

# install wget and nano
yum install -y wget
yum install -y nano

# ---------------------------------------------------------------------------
# setup of data disk
# ---------------------------------------------------------------------------

echo $(date +"%F %T%z") "mounting DataDisk"

# https://azure.microsoft.com/sv-se/documentation/articles/virtual-machines-linux-how-to-attach-disk/
# https://alexandrebrisebois.wordpress.com/2015/09/01/provisioning-a-data-disk-on-a-centos-virtual-machine-on-azure/

# partition data disk. The <<EOF stuff is piping answers into fdisk
fdisk /dev/sdc <<EOF > /tmp/fdisk.log 2>&1
n
p
1


w
EOF

# create file-system, mount it as /data, make it read-writeable
mkfs -t ext4 /dev/sdc1
mkdir /data
mount /dev/sdc1 /data
chmod go+w /data

# make data disk reappear after reboot
diskid=$(blkid /dev/sdc1)
uuid=${diskid:17:36}
echo $(printf "UUID=$uuid\t/data\text4\tdefaults\t1\t2\n") >> /etc/fstab

# install EPEL Repo
yum -y install http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-6.noarch.rpm

# ---------------------------------------------------------------------------
# install Salt-minion for management
# ---------------------------------------------------------------------------

# http://centoshowtos.org/configuration-management/saltstack/

if false; then
    # Salt - install and start. This is where the rest of the installation will take place
    #yum -y install salt-minion
    yum -y install salt-minion --enablerepo epel

    # Q&D change config to add ip addr of salt-master
    echo "master: 10.10.1.4" >> /etc/salt/minion

    mkdir /etc/salt/minion.d
    echo "master: 10.10.1.4" > /etc/salt/minion.d/99-master-address.conf

    chkconfig salt-minion on
    service salt-minion start
fi 

# ---------------------------------------------------------------------------
# install ElasticSearch
# ---------------------------------------------------------------------------
echo $(date +"%F %T%z") "INSTALLING ElasticSearch"

# https://www.elastic.co/guide/en/kibana/3.0/import-some-data.html

# ElasticSearch install
# https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-elasticsearch-on-centos-7

yum -y install java-1.8.0-openjdk.x86_64
java -version
wget https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.7.3.noarch.rpm
rpm -ivh elasticsearch-1.7.3.noarch.rpm

echo $(date +"%F %T%z") "INSTALLING ElasticSearch Plugins"

/usr/share/elasticsearch/bin/plugin -install royrusso/elasticsearch-HQ

# https://www.elastic.co/blog/azure-cloud-plugin-for-elasticsearch
/usr/share/elasticsearch/bin/plugin -install elasticsearch/elasticsearch-cloud-azure/2.8.2
/usr/share/elasticsearch/bin/plugin --install elasticsearch/elasticsearch-analysis-icu/2.6.0
/usr/share/elasticsearch/bin/plugin --install elasticsearch/elasticsearch-mapper-attachments/2.6.0
/usr/share/elasticsearch/bin/plugin --url https://github.com/episerver/elasticsearch-analysis-morfologik/releases/download/elasticsearch-analysis-morfologik-2.0.1/elasticsearch-analysis-morfologik-2.0.1.zip --install elasticsearch-analysis-morfologik

echo $(date +"%F %T%z") "INSTALLING ElasticSearch Config"

datapath="/data/elastic"
mkdir -p $datapath
chown -R elasticsearch:elasticsearch $datapath
chmod 755 $datapath

# re-write conf for heap
sysconf="/etc/sysconfig/elasticsearch"
mv $sysconf $sysconf.bak
heapsize="2g"

echo "ES_HEAP_SIZE=2g" > $sysconf

# create a ip addr list of servers in the cluster
i=1
iEnd=$numberOfNodes
hosts="$hostbase$i"
i=2
for i in $(seq 1 $iEnd); do
  hosts="$hosts,$hostbase$i";
done

# https://www.elastic.co/blog/azure-cloud-plugin-for-elasticsearch

cfgfile="/etc/elasticsearch/elasticsearch.yml"
mv $cfgfile $cfgfile.bak

echo "
cluster.name: $clustername
node.name: $HOSTNAME
path.data: $datapath
discovery.zen.ping.multicast.enabled:
discovery.zen.ping.unicast.hosts: $hosts
node.master: true
node.data: true
cloud:
  azure:
    storage:
    account: $accountname
    key: $accountkey
" > $cfgfile

echo $(date +"%F %T%z") "STARTING ElasticSearch"

systemctl start elasticsearch

echo $(date +"%F %T%z") "ending script esinstallworker.sh"
