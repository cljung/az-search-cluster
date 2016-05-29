Param(
   [Parameter(Mandatory=$False)][string]$Operation = "",
   [Parameter(Mandatory=$False)][string]$resourceGroupName = "",
   [Parameter(Mandatory=$False)][string]$LoadBalancerName = "",
   [Parameter(Mandatory=$False)][string]$VmName = ""
)

# --------------------------------------------------------------------------------------------------------------
#
function LoadBalacerAddOrRemove() {
    write-output "Getting VM $VmName"
    $vm = Get-AzureRmVM -ResourceGroupName $resourceGroupName -Name $VmName
    
    $rs = Get-AzureRmResource -ResourceId $vm.NetworkInterfaceIDs[0]
    write-output "Getting NIC $($rs.Name)"
    $nic = Get-AzureRmNetworkInterface -ResourceGroupName $resourceGroupName -Name $rs.Name
    
    write-output "Getting LoadBalancer $LoadBalancerName"
    $lb = Get-AzureRmLoadBalancer -Name $LoadBalancerName -ResourceGroupName $resourceGroupName
    
    if ( $Operation.ToLower() -eq "add" ) {
        write-output "Adding NIC from LoadBalancerBackendAddressPools $($lb.BackendAddressPools.name)"
        $nic.IpConfigurations[0].LoadBalancerBackendAddressPools = $lb.BackendAddressPools
    } else {
        write-output "Removing NIC from LoadBalancerBackendAddressPools $($lb.BackendAddressPools.name)"
        $nic.IpConfigurations[0].LoadBalancerBackendAddressPools = $null
    }
    
    write-output "Updating NIC"
    Set-AzureRmNetworkInterface -NetworkInterface $nic 
}
# --------------------------------------------------------------------------------------------------------------
#
function ShowStatus() {
    $lb = Get-AzureRmLoadBalancer -Name $LoadBalancerName -ResourceGroupName $resourceGroupName
    write-output $lb.BackendAddressPools
}
# --------------------------------------------------------------------------------------------------------------
#
switch ( $Operation.ToLower() )
{
	"status" { ShowStatus }
	"remove" { LoadBalacerAddOrRemove }
	"add" { LoadBalacerAddOrRemove }
	default { Write-Host "Operation must be status, add or remove" }
}
