# Deployment of an ElasticSearch cluster on Azure

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcljung%2Faz-search-cluster%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fcljung%2Faz-search-cluster%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>


This template allows you to deploy a ElasticSearch cluster on CentOS Linux VMs. The cluster consists of publically load balanced proxy nodes that exposes port 80 and internally load balanced worker nodes running ElasticSearch.
The public endpoint will be <your-prefix>proxy.<your-location>.cloudapp.azure.com

# About the template
The JSON Template lets you specify prefix that is used for naming all resources, VM Sizes for proxy and worker nodes, number of proxy and worker nodes, name of storage account to be used and virtual network details.

Both the proxy and worker nodes have a bash script that runs via the CustomScriptExtension during vm creation to customize the VMs. Once the search cluster is ready, Shakespeare quotes are loaded as test data.

# Provisioning

Provisioning can be done via the link or via automation scripts. This github repo provides both a PowerShell script for Windows and a bash script using Azure CLI that can be used for Mac/Linux
 
