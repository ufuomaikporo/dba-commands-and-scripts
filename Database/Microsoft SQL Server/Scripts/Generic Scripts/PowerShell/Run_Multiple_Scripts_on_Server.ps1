
$ScriptDirectory = "C:\Users\Ufuoma_Ikporo\OneDrive - dynamicrisk.net\Scripts\dba-commands-and-scripts\Database\Microsoft SQL Server\Scripts\Generic Scripts\SQL Server Agent Jobs\Stored Procedures\For Target Servers"
$ScriptList = Get-ChildItem -Path $ScriptDirectory -Depth 0 -File | Where-Object {$_.extension -like ".sql"}
$TargetDB = "DrasInternal"


Write-Host "`r`nThe following scripts are being executed on each server`r`n"
$ScriptList.Name
Write-Host "`r`n`r`n"

$ServerList = $arr = @(

                         [PSCustomObject]@{ServerName = 'DRASSQL2016'; ServerType = "Internal"; Role = "target"}
                         [PSCustomObject]@{ServerName = 'DRASSQL2016\latin1_general'; ServerType = "Internal"; Role = "target"}
                         [PSCustomObject]@{ServerName = 'DRASSQL2017'; ServerType = "Internal"; Role = "target"}
                         [PSCustomObject]@{ServerName = 'DRASSQL2019'; ServerType = "Internal"; Role = "target"}                        
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
    try
    {
        foreach ($File in $ScriptList)
        {      
            try
            {
                if ($Server.ServerType -eq "Production")
                {
                    Invoke-Sqlcmd -ServerInstance $Server.ServerName  -Database $TargetDB -Username "sa" -Password ((New-Object PSCredential 0, $Password).GetNetworkCredential().Password) `
                    -InputFile $File.FullName -TrustServerCertificate
                }
                else
                {
                    Invoke-Sqlcmd -ServerInstance $Server.ServerName  -Database $TargetDB -InputFile $File.FullName -TrustServerCertificate
                }  
            }
            catch
            {
               Write-Host "ERROR running script `"$($File.Name)`" on $($Server.ServerName)`r`n"
            }  
        }

        Write-Host "All scripts from the given directory were successfully executed on $($Server.ServerName) " 
    }
    catch
    {
        Write-Host "There were some errors running the scripts on $($Server.ServerName)`r`n"
        Write-Host $_
    }
    

} 

   