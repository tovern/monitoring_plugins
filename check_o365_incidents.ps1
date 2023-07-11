#################################################################################
# Checks O365 to see if they have any current outages affecting your tenancy
# Tom Vernon 19/09/2017
# Add the following to your nsclient config:
# check_o365_incident = cmd /c echo C:\scripts\check_o365_incidents.ps1 ; exit($lastexitcode) | powershell.exe -command -
# Requires O365 service communications API https://github.com/mattmcnabb/O365ServiceCommunications
# You could do this directly with Invoke-RestMethod but I dont have time
#################################################################################
#Import Modules
Import-Module O365ServiceCommunications

#Initiliase variables
$Events=""
$ErrorMsg=""
$Eventcount=0

# Import a credential object to use against the Service Communications API
# this needs to be a global admin for your Office 365 tenant
# To save a credential, run Get-Credential | Export-CliXml -Path c:\scripts\cred.xml
$Credential = Import-Clixml -Path "c:\scripts\cred.xml"
$MySession = New-SCSession -Credential $Credential

#Gather events from the Service Communications API. We are interested in issues that havent ended only.
$Events = Get-SCEvent -EventTypes Incident -PastDays 7 -SCSession $MySession | Where-Object { $_.EndTime -eq $null -AND $_.AffectedServiceHealthStatus -match "Exchange" }


#Formulate some useful output
foreach ($Event in $Events)
{
$ErrorMsg = $ErrorMsg + "ID:" + $Event.ID + " " + $Event.AffectedServiceHealthStatus.ServiceName + " " + $Event.Status + " started at " + $Event.StartTime + ". "
$Eventcount=$Eventcount+1
}

#Calculate result and alert if necessary
If ($EventCount -eq 0)
	{
	Write-Host "OK: No O365 Incidents reported"
	exit 0
	}
Elseif ($EventCount -gt 0)
	{
	Write-Host "CRITICAL: $Eventcount O365 Incident(s) are currently active:- $ErrorMsg"
	exit 2
	}
Else
	{
	echo "UNKNOWN: Something bad happened, check your config"
	exit 3
	}
