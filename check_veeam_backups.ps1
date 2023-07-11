#################################################################################
# check_veeam_backups - Checks Veeam backup jobs to ensure their last run state wasnt a failure
# Tom Vernon 25/05/2017
# Version 1.0	                                                                        
# Add the following to your nsclient config:
# check_veeam_jobs = cmd /c echo C:\scripts\check_veeam_backups.ps1 ; exit($lastexitcode) | powershell.exe -command -
#################################################################################
#Import Modules
Add-PSSnapin VeeamPSSnapin
$FailCount=0
$FailJobs=""

#Get job data
$jobs = Get-VBRJob | ?{$_.JobType -eq "Backup"} | Sort-Object Name

Foreach($Job in $Jobs)
        {
            $JobName = $Job.Name
            $Result = $Job.GetLastResult()
            if ($Result -eq "FAILED")
                {
                $FailCount++
                $FailJobs=$FailJobs+" "+$JobName
                }
        }

#Tidy up
Remove-PSSnapin veeamPSSnapin

#Calculate result
If ($FailCount -eq 0)
	{
	Write-Host "OK: No failed jobs found"
	exit 0
	}
Elseif ($FailCount -gt 0)
	{
	Write-Host "CRITICAL:" $FailCount "job(s) have failed:"$FailJobs
	exit 2
	}
Else
	{
	echo "UNKNOWN: Something bad happened, check your config"
	exit 3
	}

