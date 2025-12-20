$BULocation = "\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\Temp\Before Upgrade\"
$Destination = "B:\Archive\"

$DestinationFiles = Get-ChildItem Recurse -Path $Destination | Where-Object {$_.Extension -eq ".zip"}
Get-ChildItem -Path $BULocation | Where-Object {$_.Extension -eq ".zip" -and $_ -notin $DestinationFiles} | Select-Object -First 10| Sort-Object -Property Length -Descending `
#| Move-Item -Destination $Destination 