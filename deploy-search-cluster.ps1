Param(
   [Parameter(Mandatory=$False)][string]$Operation = "",
   [Parameter(Mandatory=$False)][string]$resourceGroupName = "",
   [Parameter(Mandatory=$False)][string]$NamePrefix = "cljunges",
   [Parameter(Mandatory=$False)][string]$Location = "West Europe",
   [Parameter(Mandatory=$False)][string]$AdminUid = "",
   [Parameter(Mandatory=$False)][string]$AdminPwd = "",
   [Parameter(Mandatory=$False)][int]$ProxyNodesCount = 1,
   [Parameter(Mandatory=$False)][int]$WorkerNodesCount = 1
)

$vmSizeProxy = "Standard_D1"
$vmSizeWorkers = "Standard_D1"
if ( $resourceGroupName -eq "") {
    $resourceGroupName = "$($NamePrefix)rg1"
}
$storageAccountName = "$($NamePrefix)stg1"
$virtualNetworkName = "$($NamePrefix)vnet1"
$subnetNameWorkers = "workersubnet"
$subnetNameProxy = "proxysubnet"

$templateUri = "https://raw.githubusercontent.com/cljung/az-search-cluster/master/azuredeploy.json"
# --------------------------------------------------------------------------------------------------------------
#
function Login()
{
	Login-AzureRmAccount
}

# --------------------------------------------------------------------------------------------------------------
# Deploy Cluster solution
function CreateCluster()
{
    # ----------------------------------------------------------------------------
    # if pwd specified on cmdline, ask for uid/pwd here (good when demoing on a projector)
    if ( $AdminPwd -eq "" ) {
	    $Credential = Get-Credential $AdminUid -Message "Enter VM user"
	    $AdminUid = $Credential.UserName
	    $AdminPwd = $Credential.GetNetworkCredential().password
    }
    $password = $AdminPwd | ConvertTo-SecureString -asPlainText -Force

    New-AzureRmResourceGroup -Name $resourceGroupName -Location $Location
    
    # deploy JSOn template    
    get-Date -format 's'

    New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name $NamePrefix `
        -TemplateUri $templateUri `
        -adminUsername $adminUid -adminPassword $password `
        -NamePrefix $NamePrefix -vmSizeWorkers $vmSizeWorkers -vmSizeProxy $vmSizeProxy `
        -WorkerNodesCount $WorkerNodesCount -ProxyNodesCount $ProxyNodesCount `
        -storageAccountName $storageAccountName `
        -virtualNetworkName $virtualNetworkName -subnetNameWorkers $subnetNameWorkers -subnetNameProxy $subnetNameProxy

    get-Date -format 's'
}

# --------------------------------------------------------------------------------------------------------------
# Remove ResourceGroup and ALL resources
function DeleteResourceGroup()
{
    get-Date -format 's'
    Remove-AzureRmResourceGroup -Name $resourceGroupName
    get-Date -format 's'
}
# --------------------------------------------------------------------------------------------------------------
#
switch ( $Operation.ToLower() )
{
	"login" { Login }
	"create" { CreateCluster }
	"delete" { DeleteResourceGroup }    # delete vhds also
	default { Write-Host "Operation must be create or delete" }
}
