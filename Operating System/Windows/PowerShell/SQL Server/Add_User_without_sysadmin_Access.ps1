<#

This script allows you to add a new sysadmin user if the sysadmin is locked out of a SQL Server Instance. Before running the script
 
1. This script must be opened in PowerShell ISE as an administrator
2. You must set the $InstanceName and $Login variables

#>

#############################################   THE FOLLOWING 2 VARIABLES NEED TO BE SET BEFORE RUNNING THE SCRIPT    ##############################################
<#
    Set the SQL Server instance name. If using a default instance use "MSSQLSERVER" otherwise find the instance name listed in
    Windows Services. The instance name should appear as "SQL Server(InstanceName)"
#>

$InstanceName = "MSSQLSERVER"

# User that will be added to the server level sysadmin role
$Login = "EDDYFINDT\Daniel_Cheung"

###################################################################################################################################################################

$ServerName = HostName.exe 

if ($InstanceName -ne "MSSQLSERVER")
{
    $ServerName += "\$InstanceName"
    $InstanceName = "MSSQL`$$($InstanceName)"
}

# Stop SQL Server Service/Instance
net stop $InstanceName

# Start SQL Server Instance in single-user mode
net start $InstanceName /f /mSQLCMD

$Query = "IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = '$Login')
BEGIN
    CREATE LOGIN [$Login] FROM WINDOWS; 
END

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'EDDYFINDT\DBA')
BEGIN
    CREATE LOGIN [EDDYFINDT\DBA] FROM WINDOWS; 
END

ALTER SERVER ROLE sysadmin ADD MEMBER [$Login]; 
ALTER SERVER ROLE sysadmin ADD MEMBER [EDDYFINDT\DBA];"


# Add a new user to the sysadmin group
sqlcmd.exe -E -S $ServerName -Q $Query

# Stop and restart the server in multi-user mode
net stop $InstanceName
net start $InstanceName