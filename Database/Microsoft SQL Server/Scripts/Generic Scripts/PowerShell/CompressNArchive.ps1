# 
$ServerName = (HOSTNAME.EXE).ToUpper()
$FolderName = $ServerName.Replace('\', '_')

$BULocation = "\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\Temp\Ufuoma\"
$ArchiveDestination ='\\backups.cgy.dynamicrisk.net\DB_Backups_Yearly\' #"\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\Archives\"


$Files = $null


if ((Get-ChildItem -Path $BULocation -Exclude "*.txt", "*.zip") -ne $null)
{
    $Files = (Get-ChildItem -Path $BULocation | Where-Object {$_.Extension -eq ".bak"}).BaseName.Replace("LINK", "\w*").Replace("STAGE", "\w*").Replace("CONFIG", "\w*") `
    | Select-Object -Unique | Sort-Object -Property Length -Descending
}


if($Files -ne $null)
{

    Foreach ($File in $Files)
    { 
  
        $ArchiveList = Get-ChildItem -Path $BULocation | Where-Object {$_.BaseName -match $File -and $_.Extension -eq ".bak"}      

        if ($ArchiveList -ne $null)
        {
            $SQL = "RESTORE HEADERONLY FROM DISK = '$($ArchiveList.FullName | Select-Object -First 1)'"
   
            $BackupServerName = (Invoke-Sqlcmd -ServerInstance "SQL2019" -Database "master" -Query $SQL).ServerName

            
            $Destination = $ArchiveDestination + "$BackupServerName\"
        

            if(!(Test-Path -Path $Destination))
            {
                New-Item -ItemType Directory $Destination | Out-Null
            }

            #Location of the Winrar executable file  
            $WinRar = "C:\Program Files\WinRAR\rar.exe"

            #Set FullName path for the archive file where compressed backup files will be stored
            if ($ArchiveList.Count -gt 1)
            {
                $ArchiveFile = $BULocation + $File.Replace("\w*", "DATABASES") +".zip"
            }
            elseif ($ArchiveList.Count -eq 1)
            {
                $ArchiveFile = $BULocation + $ArchiveList.BaseName + ".zip"
            }
            
            
            #Execute command to compress backup files into an archive file
            Try
            {
                & $winrar a -ibck -r -u -ep -df -m4 -y $ArchiveFile $ArchiveList.FullName
            }
            Catch
            {
                Write-Host $_
                exit
            }

        }

        $DestinationFiles = Get-ChildItem -Path $Destination | Where-Object {$_.Extension -eq ".zip"}
        Get-ChildItem -Path $BULocation | Where-Object {$_.Extension -eq ".zip" -and $_ -notin $DestinationFiles} | Move-Item -Destination $Destination 
     
    }
    

}

