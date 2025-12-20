# Get script input params
$ORACLE_SID = HOSTNAME.EXE

# Output logfile for this script run
$BULogFile="B:\Backups\RMAN_Testing\$($ORACLE_SID)_BULog_Nightly.txt"

# Command file containg RMAN commands
$CMDFile = "B:\Backups\RMAN_Testing\RMAN_Backup_CMDFILE.rman"
  
#Save the location from where the Script file is being executed to the output logfile.
Out-File -FilePath $BuLogFile  -Force -InputObject ("Script Ran from: " + $MyInvocation.MyCommand.Path)

#Add the data of the script execution of the logfile
Get-Date | Out-File $BuLogFile -Append

# Execute the RMAN command file and pipe the results to the output logfile
RMAN @$CMDFile | Out-File $BuLogFile –Append

Write-Ouput "The Backup logfile file can be found at $BULogFile"