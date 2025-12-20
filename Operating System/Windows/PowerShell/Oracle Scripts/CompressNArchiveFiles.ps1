$ServerName = HOSTNAME.EXE

$BULocation = "B:\Backups\"
$Destination = "\\Backups.cgy.dynamicrisk.net\DB_Backups_Nightly\Archives\$ServerName\"


if(!(Test-Path -Path $Destination))
{
    New-Item -ItemType Directory $Destination | Out-Null
}


$Files = Get-ChildItem -Path $BULocation* -Exclude "*.txt", "*.zip" -File 


if($Files -ne $null)
{
    $Files = $Files.BaseName.TOUPPER()  | Select-Object -Unique

    Foreach ($File in $Files)
    { 
        $ArchiveList = Get-ChildItem -Path $BULocation* -Exclude "*.txt", "*.zip" -File | Where-Object {$_.BaseName -eq $File}
  
        if ($ArchiveList -ne $null)
        {
            #Location of the Winrar executable file  
            $WinRar = "C:\Program Files\WinRAR\rar.exe"

            #Set FullName path for the archive file where compressed backup files will be stored
            $ArchiveFile = $BULocation + $File +".zip"
            
            #Deletes the Archive file if it already exists
            if(Test-Path $ArchiveFile)
            {
	           # Remove-Item $ArchiveFile
            }
            
            #Execute command to compress backup files into an archive file
            & $winrar a -ibck -u -ep -df -m4 -y $ArchiveFile $ArchiveList.FullName


        }
      
    }
}


$DestinationFiles = Get-ChildItem -Path $Destination | Where-Object {$_.Extension -eq ".zip"}
Get-ChildItem -Path $BULocation | Where-Object {$_.Extension -eq ".zip" -and $_ -notin $DestinationFiles} | Move-Item -Destination $Destination 

 