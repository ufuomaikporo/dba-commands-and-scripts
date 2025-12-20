# This script sets the compability level for all databases on a server to the maximum compatibility level

$ServerName = "SQL2019"

$GetCompatLevel = "SELECT database_id AS DBID, name AS DBName, Compatibility_Level 
FROM sys.databases
WHERE is_read_only != 1
"
$UpgradeCompatLevel = "ALTER DATABASE {0} SET COMPATIBILITY_LEVEL = {1}"

# A before and after report is generated before and after the compatibility upgrade
$ReportDir = "C:\Users\Ufuoma_Ikporo\Documents\DatabaseMaintenanceReports\"
$ReportFile = $ReportDir + $ServerName.Replace('\','_') + "_DBCompatibilityLevelUpgrade.txt"

# Create report directory if it does not already exist
if ($false -eq (Test-Path $ReportDir))
{
    New-Item -Path $ReportDir -ItemType Directory  | Out-Null
}

# Get current compatibility level settings and get maximum compatibility level based on current max level found on the server
$CompatLevels = Invoke-Sqlcmd -ServerInstance $ServerName -Database master -Query $GetCompatLevel
$MaxCompatLevel = ($CompatLevels | Measure-Object -Property compatibility_level -Maximum).Maximum
$Databases = ($CompatLevels | Where-Object {$_.DBID -gt 4 -and $_.compatibility_level -ne $MaxCompatLevel}).DbName

# Write Compatibility level before change to output file
Write-Output "################################## Before Compatibility Level Upgrade ############################`r`n" | Out-File $ReportFile
$CompatLevels | Format-Table -AutoSize | Out-File -Append $ReportFile

# Upgrade compatibility level to max level found on the server for all non-system databases
foreach($DB in $Databases)
{
    $SQL = $UpgradeCompatLevel -f $DB, $MaxCompatLevel
    Invoke-Sqlcmd -ServerInstance $ServerName -Database $DB -Query $SQL -ConnectionTimeout 120
}

# Get compatibility level after upgrade and write it to output file
$CompatLevels = Invoke-Sqlcmd -ServerInstance $ServerName -Database master -Query $GetCompatLevel

Write-Output "`r`n################################## After Compatibility Level Upgrade ############################`r`n" | Out-File -Append $ReportFile

$CompatLevels | Format-Table -AutoSize | Out-File -Append $ReportFile
#>
