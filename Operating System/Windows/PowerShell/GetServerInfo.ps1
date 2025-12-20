$ServerName = 'PAA-SQL01'

if ([string]::IsNullOrWhitespace($ServerName))
{
    $ServerName = Hostname.exe
}

Write-Host "`r`n$Servername"

# Get Disk info
Get-WmiObject -Class Win32_logicaldisk -Computername $ServerName | `
Select-Object -Property DeviceId, ProviderName, `
@{Name= 'Size(GB)'; Expression = {[math]::Round($_.Size/1024/1024/1024, 0)}}, `
@{Name= 'FreeSpace(GB)'; Expression = {[math]::floor($_.FreeSpace/1024/1024/1024)}}, `
@{Name = 'PercentFree(GB)'; Expression = {[math]::Round($_.FreeSpace/$_.Size * 100, 0)}} | Format-Table

# Get CPU info (number of sockets = number of rows displayed. Number of cores = sum of number of cores in each row, number of logical/virtualProcessors = sum of number of logicalProcessors in each row
Get-WmiObject -Class Win32_Processor -ComputerName $ServerName | Select-Object NumberOfCores, NumberOfEnabledCore, NumberOfLogicalProcessors | Format-Table

# Get RAM info
(Get-WmiObject -Class Win32_PhysicalMemory -ComputerName $ServerName | Measure-Object -Property capacity -Sum) | SELECT @{Name = 'RAM(GB)'; Expression = {[math]::Round($_.sum/1024/1024/1024)}}


# Get CPU and RAM usage (Use ctrl+C to stop the loop)
<#
$totalRam = (Get-CimInstance Win32_PhysicalMemory -ComputerName "DRASSQL2017" | Measure-Object -Property capacity -Sum).Sum
while($true) {
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $cpuTime = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
    $availMem = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
    $date + ' > CPU: ' + $cpuTime.ToString("#,0.000") + '%, Avail. Mem.: ' + $availMem.ToString("N0") + 'MB (' + (104857600 * $availMem / $totalRam).ToString("#,0.0") + '%)'
    Start-Sleep -s 2
}
#>