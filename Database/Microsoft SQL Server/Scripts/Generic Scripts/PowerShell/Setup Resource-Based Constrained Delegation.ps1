<# 

The Active Directory PowerShell module (RSAT) is required and can be installed via the following

powershell command (For Windows Server)

- Run the line below to install Active Directory PowerShell module (RSAT)
Install-WindowsFeature RSAT-AD-PowerShell

- OR MANUALLY install (RSAT) in Windows Server by doing the folloing 

Go to Settings > Apps > Optional features and search for RSAT: Active Directory Domain Services.

#>

#---------- Register SPN for Multi-instance Node (DRASSQL2016)

$Hostname = "DRASSQL2022"
$ServiceUser = "NDTG\DatabaseUser"

# Register the FQDN for the default instance
setspn -S MSSQLSvc/$Hostname.NDT.GLOBAL:1433 $ServiceUser

# Register the NetBIOS name for default instance
setspn -S MSSQLSvc/$Hostname:1433 $ServiceUser

# Register the FQDN and NetBIOS for a named instance (make sure port number matches)
setspn -S MSSQLSvc/$Hostname.NDT.GLOBAL:50000 $ServiceUser
setspn -S MSSQLSvc/$Hostname:50000 $ServiceUser

#------------------------- Grant delegation permission ------------------

# 1. Identify the SQL Server service account (NDTG\DatabaseUser)
$ServiceAccount  = Get-ADUser -Identity "$ServiceUser"

# 3. Grant permission for the service account to delegate to itself
Set-ADComputer -Identity $Hostname -PrincipalsAllowedToDelegateToAccount $ServiceAccount

#---------------------------------- Verify -------------------------

<#
#------ Run the following in powershell is RSAT is enabled
Get-ADUser -Identity $ServiceUser -Properties PrincipalsAllowedToDelegateToAccount

#------ Run the following (server-side) in powershell if RSAT is not available or is disabled. Should return the list of services registered to the service user

setspn -L $ServiceUser

#------ Run the following (client-side) when connected to the database server to see if you can see the database service listed with 

klist

The output of the klist command should look like the following for MS SQL Server database on the DRASSQL2019 server host

#4>     Client: Ufuoma_Ikporo @ NDT.GLOBAL
        Server: MSSQLSvc/DRASSQL2019:1433 @ NDT.GLOBAL
        KerbTicket Encryption Type: AES-256-CTS-HMAC-SHA1-96
        Ticket Flags 0x40a10000 -> forwardable renewable pre_authent name_canonicalize
        Start Time: 7/6/2026 13:27:46 (local)
        End Time:   7/6/2026 23:19:17 (local)
        Renew Time: 7/13/2026 13:19:17 (local)
        Session Key Type: AES-256-CTS-HMAC-SHA1-96
        Cache Flags: 0
        Kdc Called: NDTG-FRA-DC01.NDT.GLOBAL

#------ If succesful, the following should return the service user names and authentication scheme should show "KERBEROS" if set up correctly in SQL Server 

SELECT servicename, service_account
FROM sys.dm_server_services;

SELECT session_id, auth_scheme, net_transport, local_net_address, local_tcp_port
FROM sys.dm_exec_connections
WHERE session_id = @@SPID;
#>
