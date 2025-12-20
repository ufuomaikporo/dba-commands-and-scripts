# Set this variable if you only want to archive backups from a specific file otherwise all backups from the servers listed in $DBServerList will be archived

#-------------------------------------- FOLDERS AND BACKUP DIRECTORIES -----------------------------

#Nightly backup storage location
$ArchiveLoc = "\\dras-dbbkp02\P_DB_Backups_Monthly\Archives\$Server\"
$TargetFolder = "\\dras-dbbkp02\P_DB_Backups_Weekly\Temp\Before Upgrade\"

$DBServerList = $arr = @([PSCustomObject]@{ServerName = 'DRASSQL2012EXT'}
                         [PSCustomObject]@{ServerName = 'SQL2014EXT'}
                         [PSCustomObject]@{ServerName = 'DRASSQL2016'}
                         [PSCustomObject]@{ServerName = 'DRASSQL2017'}
                         [PSCustomObject]@{ServerName = 'DRASSQL2019'}
                         [PSCustomObject]@{ServerName = 'DRASSQL2022'}
                         [PSCustomObject]@{ServerName = 'IRAS-PREP-SQL01'}                         
                     )

$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch

$StopWatch.Start()

# if the $TargetFolder variable is set to a non-null or whitespace value archive db backups from the target folder and it's subdirectories ONLY
if (!([string]::IsNullOrWhitespace($TargetFolder)))
{
    $ArchiveList = Get-ChildItem -Path $TargetFolder -Recurse -Include "*IRASV6*.bak" #`
    #| Where-Object {$_.FullName -notmatch "For QA Testing" -and $_.FullName -notmatch "Before Upgrade.*SQL2017.*" -and $_.FullName -notmatch "Before Upgrade.*SQL2019.*"}
      
       
#--------------------------------- Compress backups into .rar files and send to archive location ---------------------

    #Archive db backup files
    foreach ($File in $ArchiveList)
    {
        $SQL = "RESTORE HEADERONLY FROM DISK = '$($File.FullName)'" 
        $BackupInfo = Invoke-Sqlcmd -ServerInstance "DRASSQL2022" -Database "master" -Query $SQL -TrustServerCertificate 

        $ArchiveLoc = "\\dras-dbbkp02\P_DB_Backups_Monthly\Archives\$($BackupInfo.ServerName)\"
        
        if (!(Test-path $ArchiveLoc)) 
        {
            New-item -type directory $ArchiveLoc | Out-Null
	    }  
            
        #Location of the Winrar executable file  
        $WinRar = "C:\Program Files\WinRAR\rar.exe"

        #Name and location of archive file where compressed backup files will be stored
        $ArchiveFile = $ArchiveLoc + $File.BaseName +".rar"

        #Execute command to compress backup files into an archive file
        & $winrar u -ep -ibck -y -df $ArchiveFile $File.FullName  

    } #end of archive db backup block
                        
#------------------------------------ Move Zip files and rar files to the Archive location ---------------------------------

    $MoveFiles = Get-ChildItem -Path $Drive -Recurse -Include "*IRASV6*.rar", "*IRASV6*.zip"

    foreach ($File in $MoveFiles)
    {
           
        Move-Item -Path $File.FullName -Destination $ArchiveLoc
    }
}
# Otherwise archive db backups from the servers listed in $DBServerList
else
{

    foreach ($Server in $DBServerList.ServerName)
    {
    
       $Server

        #--------------------------------------- Archive BACKUPs --------------------------------------

        if (!(Test-path $ArchiveLoc)) 
        {
            New-item -type directory $ArchiveLoc | Out-Null
	    }

        $DiskInfo = Get-WmiObject -Class Win32_logicaldisk -Computername $Server

        foreach ($Drive in $DiskInfo.DeviceId)
        { 
            $Drive = "\\$Server\" + $Drive.Replace(":", "$") + "\"

            if ($Drive -notmatch "C")
            {
                $ArchiveList = Get-ChildItem -Path $Drive -Recurse -Include "*IRASV*.bak"
          
            
    #--------------------------------- Compress backups into .rar files and send to archive location ---------------------

                #Archive db backup files
                foreach ($File in $ArchiveList)
                {
           
            
                    #Location of the Winrar executable file  
                    $WinRar = "C:\Program Files\WinRAR\rar.exe"

                    #Name and location of archive file where compressed backup files will be stored
                    $ArchiveFile = $ArchiveLoc + $File.BaseName +".rar"


                    #Execute command to compress backup files into an archive file
                    & $winrar u -ep -ibck -y -df $ArchiveFile $File.FullName  

                } #end of archive db backup block
            
            
    #------------------------------------ Move Zip files and rar files to the Archive location ---------------------------------

                $MoveFiles = Get-ChildItem -Path $Drive -Recurse -Include "*IRASV6*.rar", "*IRASV6*.zip"

                foreach ($File in $MoveFiles)
                {
           
                    Move-Item -Path $File.FullName -Destination $ArchiveLoc
                }
            }

        }#End of Loop through the disk drives

    

    }# end of loop through Servers
}

$StopWatch.Stop()

$TotalTime = $StopWatch.Elapsed

Write-Output "`r`nCompleted: $(Get-Date)     Duration: $($TotalTime.ToString("hh'hr:'mm'min:'ss'sec'"))"