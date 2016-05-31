#!/bin/bash

# this script uses jq to parse JSON, so you neet to download it using
# sudo apt-get install jq

resourceGroupName=""
loadBalancerName=""
vmName=""

while test $# -gt 0
do
    case "$1" in
    -o|--op)        shift ; operation=$1
            ;;
    -g|--rg)        shift ; resourceGroupName=$1
            ;;
    -n|--vmname)    shift ; vmName=$1
            ;;
    -l|--lb)        shift ; loadBalancerName=$1
            ;;
    esac
    shift
done

if [ -z "$resourceGroupName" ]; then
  echo "resourceGroupName not specified"
  exit 1
fi

if [ -z "$loadBalancerName" ]; then
  echo "loadBalancerName not specified"
  exit 1
fi

function LoadBalancerAddOrRemove() {
  if [ -z "$vmName" ]; then
    echo "vmName not specified"
    exit 1
  fi
  
  # get vm nic id
  echo "Getting NIC for VM $vmName"
  nicID=$(azure vm show -g $resourceGroupName -n $vmName --json | jq '.networkProfile.networkInterfaces[0].id')
  # remove double quotes at start/end
  nicID="${nicID%\"}"
  nicID="${nicID#\"}"
  # get just the name and not the long resourceId
  nicName=$(echo $nicID | cut -f9 -d '/')

  # get id of LB BE pool
  echo "Getting LoadBalancer $loadBalancerName"
  lbbeID=$(azure network lb address-pool list  -g $resourceGroupName -l $loadBalancerName --json | jq '.[0].id')
  # remove double quotes at start/end
  lbbeID="${lbbeID%\"}"
  lbbeID="${lbbeID#\"}"

  if [ "$operation" == "remove" ]; then
    # remove nic from lb by passing nothing as the id
    echo "Removing NIC from LoadBalancer..."
    azure network nic set -g $resourceGroupName -n $nicName --lb-address-pool-ids 
  fi

  if [ "$operation" == "add" ]; then
    # add nic to lb
    echo "Adding NIC to LoadBalancer..."
    azure network nic set -g $resourceGroupName -n $nicName --lb-address-pool-ids $lbbeID 
  fi
}

function statusOfLoadBalancer() {
  azure network lb address-pool list -g $resourceGroupName -l $loadBalancerName --json
}

case "$operation" in
   "status")    statusOfLoadBalancer
          ;;
   "remove")    LoadBalancerAddOrRemove
          ;;
   "add")       LoadBalancerAddOrRemove
          ;;
   *)           echo "bad -o switch"
          ;;
esac
