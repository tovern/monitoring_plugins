#######################################
# check_fileserver_space.ps1
#######################################
# Simple Nagios (NSClient) plugins to check
# customer Fileserver usage in the absence of quotas.
# v0.1
# Tom Vernon
#######################################

#Get some parameters
param(
  [string]$Cust,
  [int32]$Crit,
  [int32]$Warn
)

#Filter Data
$Data=import-csv C:\Scripts\DirStats.csv | Select Files,Folder,@{Name="Size";Expression={[int32]$_.Size}}
$Customer = $Data | Where-Object {$_.Folder -like "*" + $Cust + "*" }
$NeatFolder= $Customer.Folder -replace ".*\$"

#Check Data
If (!$Customer.Folder)
	{
	echo "UNKNOWN: Customer not found, check your config and make sure that DirStats.csv exists"
	exit 3
	}

#Calculate result
If ($Customer.size -ge $CRIT)
	{
	Write-Host "CRITICAL:" $NeatFolder "is"$Customer.size"GB, Quota is"$CRIT" GB"
	exit 2
	}
Elseif ($Customer.size -ge $WARN)
	{
	Write-Host "WARNING:" $NeatFolder "is"$Customer.size"GB, Quota is"$CRIT" GB"
	exit 1
	}
Elseif ($Customer.size -lt $WARN)
	{
	Write-Host "OK:" $NeatFolder "is"$Customer.size"GB, Quota is"$CRIT" GB"
	exit 0
	}
Else
	{
	echo "UNKNOWN: Something bad happened, check your config"
	exit 3
	}