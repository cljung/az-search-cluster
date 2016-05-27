#!/bin/bash

echo $(date +"%F %T%z") "starting script esinstallproxy.sh"

# arguments
userid=$1
proxyFqdn=$2
numberOfNodes=$3
lbIpAddressES=$4
hostbase=$5
accountname=$6
accountkey=$7
nodeIndex=$8

echo "user=$userid fqdn=$proxyFqdn lbip=$lbIpAddressES stgacct=$accountname nodeidx=$nodeIndex"

curdir=$PWD

# https://github.com/Azure/WALinuxAgent/issues/178
yum update -y --exclude=WALinuxAgent

# install wget and nano
yum -y install wget
yum -y install nano

#
# http://centoshowtos.org/configuration-management/saltstack/
# http://centoshowtos.org/configuration-management/saltstack/
# http://stackoverflow.com/questions/25119091/installing-saltstack-on-rhel-7
# http://bencane.com/2013/09/03/getting-started-with-saltstack-by-example-automatically-installing-nginx/
# http://www.cloudkb.net/saltstack-installation-on-centos-7/
#

# Salt - install and start. This is where the rest of the installation will take place

# first clear the yum cache
yum clean all
# install EPEL Repo
yum -y install http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-6.noarch.rpm
 
if false; then
    # install salt-master and salt-minion
    yum -y install salt-master salt-minion

    # Q&D change config to add ip addr of salt-master
    echo "interface: 10.10.1.100" >> /etc/salt/master
    echo "#
    file_roots:
    base:
        - /srv/salt/base" >> /etc/salt/master

    mkdir -p /srv/salt/base

    chkconfig salt-master on
    service salt-master start
fi 

# run salt-key -A -y to accept the minions

homedir="/home/$userid"

# create a quick way of cd to dir where Azure's Custom Script Extension is located
cdwace="$homedir/cdwacse.sh"
echo "#!/bin/bash
cd $curdir
" > $cdwace
chmod +x $cdwace
chown $userid:$userid $cdwace

# prep for loading of Shakespeare data into elasticsearch. 
# This is only done by the first proxy node since it only needs to be done once
# The script shakespeare.sh monitors when the ES cluster is ready and imports data 
if [ $nodeIndex -eq "1" ] ; then
    loadscript="$homedir/shakespeare.sh"
    echo $(date +"%F %T%z") "INSTALLING Shakespeare $loadscript"
    cp $curdir/shakespeare.sh $loadscript
    chown $userid:$userid $loadscript
    chmod +x $loadscript
    # spawn it in the background 
    $loadscript $lbIpAddressES &>/tmp/shakespeare.log &
fi

echo $(date +"%F %T%z") "INSTALLING NodeJS and NPM..."

# setup the reverse proxy for ElasticSearch
yum install -y nodejs
yum install -y npm

echo $(date +"%F %T%z") "INSTALLING Redbird NodeJS proxy..."

# cd to get npm package in correct directory
cd $homedir

# https://github.com/OptimalBits/redbird
npm install redbird
npm install redis

# rproxy.js is a tiny, tiny reverse proxy
rproxyscript="$homedir/rproxy.js"
echo $(date +"%F %T%z") "STARTING Redbird NodeJS proxy $rproxyscript"
cp $curdir/rproxy.js $rproxyscript
chown $userid:$userid $rproxyscript

echo "#!/bin/bash
cd $homedir
node $rproxyscript $proxyFqdn http://$lbIpAddressES:9200 &>/tmp/rproxy.log &
#" > $rproxyscript.sh

chown $userid:$userid $rproxyscript.sh
chmod +x $rproxyscript.sh

# start reverse proxy
#node $rproxyscript $proxyFqdn http://$lbIpAddressES:9200 &>/tmp/rproxy.log &
$rproxyscript.sh

# disown started scripts so they run on their own and disconnects from stdout/stderr
disown

echo $(date +"%F %T%z") "ending script esinstallproxy.sh"
