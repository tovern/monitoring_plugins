######################################################################################
# check_cluster_resource.ps1 - Nagios plugins to Check MS Failover cluster resources #
# Tom Vernon 23-01-2018	                                                             #
# Version 1.0						                                                 #
######################################################################################
#You will need to give the computer AD account read permissions on the cluster being monitored
#Usage: check_cluster_resource.ps1
#NSClient config:
#[/settings/external scripts/scripts/check_cluster_resource]
#command = cmd /c echo c:\scripts\check_cluster_resource.ps1 ; exit($lastexitcode) | powershell.exe -command -

Import-Module FailoverClusters
$cluster = Get-Cluster
$outmsg=""
$failcount=0

$clusterresources = Get-ClusterResource -cluster $cluster | Select-Object Name,State | Sort-Object State -Descending | Select-Object Name,State

$outmsg = $clusterresources | Out-String

ForEach ($Resource in $clusterresources)
{

    If ($Resource.state -ne "Online")
    {
        $failcount = $failcount+1
    } 
}


    If ($failcount -gt 0)
    {
        Write-Host "CRITICAL: Cluster resource failures"
        Write-Host $outmsg
	    exit 2
    } 
    Elseif ($failcount -eq 0)
    {
	    Write-Host "OK: Cluster resources all online"
        Write-Host $outmsg
		exit 0
    }
	Else
	{
		Write-Host "UNKNOWN: $outmsg"
        exit 3
	}