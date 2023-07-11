##############################################################################
# Checks for any ABP violations in O365. Nagios version
# Tom Vernon 20/09/2017
##############################################################################

#Import Modules
Import-Module ActiveDirectory
Import-Module MSOnline

##############################################################################
$VIOLATION = 0
$SKIPS = 0
$ERRORMSG = @()
$RESULTS = @{}

$User = "automation@mydomain"
$PassFile = "C:\scripts\encryptionstring.txt" #Generate via '"MYPASSWORD" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString | Out-File "C:\scripts\encryptionstring.txt'

##############################################################################

#Connect to O365 & Exchange Online
$MyCredential=New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (Get-Content $PassFile | ConvertTo-SecureString)
$O365Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $MyCredential -Authentication Basic -AllowRedirection -ErrorAction stop
Connect-MsolService –Credential $MyCredential  -ErrorAction stop

#Check ABP's
Import-PSSession $O365Session -CommandName *mailbox* -verbose:$false | Out-Null
$RESULTS=`Get-Mailbox -resultsize unlimited | Select-Object Name,UserPrincipalName,AddressBookPolicy,@{n="AddressBookPolicyStripped";e={$_.AddressBookPolicy.trimstart("ABP_") }},@{n="Company";e={(get-aduser $_.Alias -properties Company).Company}}`
Remove-PSSession -Session (Get-PSSession)


foreach ($mailbox in $RESULTS)
 {
    $OUTEST=$mailbox.'UserPrincipalName'
    #Lets skip ones in the old OU as they havent been migrated yet
    if (Get-ADUser -filter {UserPrincipalName -eq $OUTEST} -SearchBase "OU=Microsoft Exchange Hosted Organizations,DC=msp,DC=local")
        {
        $SKIPS++

        }
    else
    {
        if ($mailbox.AddressBookPolicyStripped -ne $mailbox.Company)
        {
            $ABP=$mailbox.AddressBookPolicy
            $COMPANY=$mailbox.Company
            $NAME=$mailbox.Name
            $ERRORMSG += "`nWARNING: Address book policy $ABP does not match company $COMPANY for user $NAME"
            $VIOLATION++
        }
    }
 }


 #Calculate result and alert if necessary
If ($VIOLATION -eq 0)
	{
	Write-Host "OK: No O365 Address Book Policy violations"
	exit 0
	}
Elseif ($VIOLATION -gt 0)
	{
	Write-Host "CRITICAL: $VIOLATION O365 Address Book Policy violations.  Take corrective action immediately! \n$ErrorMsg"
	exit 2
	}
Else
	{
	Write-Host "UNKNOWN: Something bad happened, check your config"
	exit 3
	}
