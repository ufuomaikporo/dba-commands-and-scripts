$CurrentDate = Get-Date 
$BULocation ="B:\Fast Recovery Area\ORA19C22\Backups\"
$MonthlyLoc = "\\backups.cgy.dynamicrisk.net\DB_Backups_Monthly\ORA19C22\Testing\Monthly\"

$DeleteList = Get-ChildItem $MonthlyLoc | Where-Object {$_.Lastwritetime -lt $CurrentDate.Adddays(-60)}

$DeleteList = Get-ChildItem $BULocation -Recurse | Where-Object {$_.Lastwritetime -lt $StartOfWeek} 
$DeleteList