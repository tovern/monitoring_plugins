######################################################################################
# check_cluster_node.ps1 - Nagios plugins to Check MS Failover cluster nodes         #
# Tom Vernon 23-01-2018                                                              #
# Version 1.0						                                                 #
######################################################################################
#You will need to give the computer AD account read permissions on the cluster being monitored
#Usage: check_cluster_node.ps1
#NSClient config:
#[/settings/external scripts/scripts/check_cluster_node]
#command = cmd /c echo c:\scripts\check_cluster_node.ps1 ; exit($lastexitcode) | powershell.exe -command -

Import-Module FailoverClusters
$cluster = Get-Cluster
$clusternodes = @()
$outmsg=""

$clusternodes = Get-ClusterNode -cluster $cluster | Select Name,State | Sort-Object State -Descending | Select-Object Name,State

$outmsg = $clusternodes | Out-String

    If ($clusternodes.state -contains "Down")
    {
        Write-Host "CRITICAL: Cluster node down"
        Write-Host $outmsg
	    exit 2
    } 
    Elseif ($clusternodes.state -contains "Paused")
    {
		Write-Host “WARNING: Cluster nodes degraded”
        Write-Host $outmsg
		exit 1
    }
    Elseif ($clusternodes.state -contains "Up")
    {
	    Write-Host “OK: Cluster nodes up”
        Write-Host $outmsg
		exit 0
    }
	Else
	{
		Write-Host “UNKNOWN: $outmsg”
        exit 3
	}