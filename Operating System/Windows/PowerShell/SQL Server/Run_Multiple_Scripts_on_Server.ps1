
$ScriptDirectory = "C:\Users\Ufuoma_Ikporo\OneDrive - dynamicrisk.net\Scripts\Microsoft SQL Server\Scripts\Generic Scripts\SQL Server Agent Jobs\Stored Procedures\For Master Servers"
$ScriptList = Get-ChildItem -Path $ScriptDirectory -Depth 0 -File | Where-Object {$_.extension -like ".sql"}
$TargetDB = "DrasInternal"

Write-Host "`r`nThe following scripts are beign executed on each server`r`n"
$ScriptList.Name
Write-Host "`r`n`r`n"

$ServerList = $arr = @([PSCustomObject]@{ServerName = 'DRASSQL2012EXT'; ServerType = "Internal"; Role = "target"}
                         [PSCustomObject]@{ServerName = 'SQL2014EXT'; ServerType = "Internal"; Role = "target"}
                         [PSCustomObject]@{ServerName = 'DRASSQL2016'; ServerType = "Internal"; Role = "target"}
                         [PSCustomObject]@{ServerName = 'DRASSQL2016\latin1_general'; ServerType = "Internal"; Role = "target"}
                         [PSCustomObject]@{ServerName = 'DRASSQL2017'; ServerType = "Internal"; Role = "target"}
                         [PSCustomObject]@{ServerName = 'DRASSQL2019'; ServerType = "Internal"; Role = "target"}                        
                         [PSCustomObject]@{ServerName = 'IRAS-PREP-SQL01'; ServerType = "Internal"; Role = "target"}
                         [PSCustomObject]@{ServerName = 'DRASSQL2022'; ServerType = "Internal"; Role = "master"}
                         [PSCustomObject]@{ServerName = 'CTSQL01'; ServerType = "Production"; Role = "master"}
                         [PSCustomObject]@{ServerName = 'PAA-SQL01'; ServerType = "Production"; Role = "target"}
                     )

if ($ScriptDirectory -match 'master')
{
    $ServerList = $ServerList | Where-Object {$_.Role -eq "master"}
}


$Password = Read-Host -Prompt "Enter production server user passwrod" -AsSecureString

foreach ($Server in $ServerList)
{
    
    foreach ($File in $ScriptList.FullName)
    {
        if ($Server.ServerType -eq "Production")
        {
            Invoke-Sqlcmd -ServerInstance $Server.ServerName  -Database $TargetDB -Username "sa" -Password ((New-Object PSCredential 0, $Password).GetNetworkCredential().Password) `
            -InputFile $File -TrustServerCertificate
        }
        else
        {
            try
            {
                Invoke-Sqlcmd -ServerInstance $Server.ServerName  -Database $TargetDB -InputFile $File -TrustServerCertificate
            }
            catch
            {
                Write-Host "ERROR running script `"$($File.Name)`" on $($Server.ServerName)`r`n"
                Write-Host $_
            }
        }
       
    }
      
    Write-Host "All scripts from the given directory were executed on $($Server.ServerName) " 

} 

   