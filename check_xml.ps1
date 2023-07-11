######################################################################################
# check_xml.ps1 - Nagios plugins to Check XML webservices                            #
# Tom Vernon 22-06-2017						                                         #
# Version 1.0	                                                                     #
######################################################################################
#Usage: check_xml.ps1 -Service MYSVC -CheckURI "https://URI/path?wsdl" -CheckString "getMessagesResponse" -XMLFile "Z:\Scripts\file.xml"
#Command Line Parameters
param (
[parameter(mandatory=$true)]
[string] $Service,
[parameter(mandatory=$true)]
[string] $CheckURI,
[parameter(mandatory=$true)]
[string] $CheckString,
[parameter(mandatory=$true)]
[string] $XMLFile
)

#Exit codes
$STATE_OK=0
$STATE_WARNING=1
$STATE_CRITICAL=2
$STATE_UNKNOWN=3

[xml]$CheckXML = Get-Content $XMLFile
#$result = (Invoke-WebRequest $CheckURI -infile sfdfsdf –contentType "text/xml" –method POST)
$result = (Invoke-WebRequest $CheckURI –contentType "text/xml" –method POST -Body $CheckXML)

if ($Result.Content -match "$CheckString") {
    Write-Host "OK: $Service returned correct string $CheckString"
    #exit $STATE_OK
    }
Else {
    Write-Host "CRITICAL: $Service did not return expected string"
    #exit $STATE_CRITICAL
    }