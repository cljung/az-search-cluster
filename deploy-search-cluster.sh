#!/bin/bash

resourceGroupName=""
location="westeurope"

TEMPLURI="https://raw.githubusercontent.com/cljung/az-search-cluster/master/azuredeploy.json"

operation=""
adminUid=""
adminPassword=""
NamePrefix="cljunges"
vmSizeWorkers="Standard_D1"
vmSizeProxy="Standard_D1"
WorkerNodesCount="1"
ProxyNodesCount="1"
subnetNameWorkers="workersubnet"
subnetNameProxy="proxysubnet"
storageAccountName=""
virtualNetworkName=""

while test $# -gt 0
do
    case "$1" in
    -o|--op)        shift ; operation=$1
            ;;
    -u|--uid)       shift ; adminUid=$1
            ;;
    -p|--pwd)       shift ; adminPassword=$1
            ;;
    -x|--proxy)     shift ; ProxyNodesCount=$1
            ;;
    -w|--workers)   shift ; WorkerNodesCount=$1
            ;;
    -r|--rg)         shift ; resourceGroupName=$1
            ;;
    -n|--nameprefix) shift ; NamePrefix=$1
            ;;
    -l|--location) shift ; location=$1
            ;;
    esac
    shift
done

if [ -z "$resourceGroupName" ]; then
  resourceGroupName=$NamePrefix"rg1"
fi

if [ -z "$storageAccountName" ]; then
  storageAccountName=$NamePrefix"stg1"
fi

if [ -z "$virtualNetworkName" ]; then
  virtualNetworkName=$NamePrefix"vnet1"
fi

function deleteCluster() {
  azure group delete -q -n $resourceGroupName
}

function createCluster() {
  if [ -z "$adminPassword" ]; then
     read -s -p "Password for user $adminUid:" adminPassword
  fi

# create the parameters form the tamplate in JSON format
PARAMS=$(echo "{\
\"adminUsername\":{\"value\":\"$adminUid\"},\
\"adminPassword\":{\"value\":\"$adminPassword\"},\
\"NamePrefix\":{\"value\":\"$NamePrefix\"},\
\"vmSizeWorkers\":{\"value\":\"$vmSizeWorkers\"},\
\"vmSizeProxy\":{\"value\":\"$vmSizeProxy\"},\
\"WorkerNodesCount\":{\"value\":$WorkerNodesCount},\
\"ProxyNodesCount\":{\"value\":$ProxyNodesCount},\
\"storageAccountName\":{\"value\":\"$storageAccountName\"},\
\"virtualNetworkName\":{\"value\":\"$virtualNetworkName\"},\
\"subnetNameWorkers\":{\"value\":\"$subnetNameWorkers\"},\
\"subnetNameProxy\":{\"value\":\"$subnetNameProxy\"}\
}")

#echo $PARAMS

  # create the resource group
  azure group create -n $resourceGroupName -l $location

  # deploy the template
  azure group deployment create $resourceGroupName $NamePrefix -f $TEMPLURI -p "$PARAMS"
}


case "$operation" in
   "delete")    deleteCluster
          ;;
   "create")    createCluster
          ;;
   *)           echo "bad -o switch"
          ;;
esac

