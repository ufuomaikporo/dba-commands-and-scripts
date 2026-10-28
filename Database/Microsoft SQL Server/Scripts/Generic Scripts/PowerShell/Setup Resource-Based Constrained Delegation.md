# Setup Resource-Based Constrained Delegation for SQL Server Kerberos

**Document type:** Technical procedure  
**Applies to:** Active Directory, Windows Server, and Microsoft SQL Server  
**Revision:** 1.0  
**Last reviewed:** 2026-10-21

## Revision Log

| Revision | Date | Description | Author |
| --- | --- | --- | --- |
| 1.0 | 2026-10-21 | Initial Markdown procedure based on the supplied PowerShell scripts and Microsoft Learn guidance. | Database Administration |

## Signatures

| Role | Name | Signature | Date |
| --- | --- | --- | --- |
| Database Administrator |  |  |  |
| Infrastructure/Active Directory Administrator |  |  |  |
| Change Approver |  |  |  |

## Purpose

This procedure establishes a controlled method for configuring resource-based constrained delegation (RBCD) for a SQL Server service in Active Directory. The configuration allows an approved front-end service or server to request Kerberos service tickets to the SQL Server service on behalf of an authenticated user.

The procedure also registers the SQL Server service principal names (SPNs) required for Kerberos authentication and provides commands to verify the resulting configuration.

## Scope

This procedure applies to:

- Database administrators who manage SQL Server instances running under domain accounts.
- Infrastructure or Active Directory administrators who manage computer and user account properties.
- SQL Server default and named instances that require Windows/Kerberos authentication.
- Multi-tier applications that connect to SQL Server through an intermediate service or server.

This procedure does not replace application-specific delegation design or change-management approval. Use it only for the accounts and services documented in the approved change.

## Policy Statement

RBCD must be configured only for explicitly approved source principals and resource services. Do not enable unconstrained delegation for this scenario. Do not grant delegation to broad groups, service accounts, or computers unless the approved design requires it.

The SQL Server SPN must resolve to the account running the SQL Server Database Engine service. Duplicate or incorrectly mapped SPNs can cause Kerberos authentication failures and must be resolved before testing delegation.

## Definitions

| Term | Definition |
| --- | --- |
| Active Directory (AD) | The directory service that stores domain identities, computer accounts, service accounts, and SPNs. |
| Kerberos | The Windows authentication protocol used to obtain tickets for domain services. |
| RBCD | Resource-based constrained delegation. The resource account controls which principals may act on behalf of users to services hosted by that account. |
| SPN | Service Principal Name. The unique name a Kerberos client uses to identify a service instance. |
| Source principal | The front-end computer, user service account, or gMSA that requests a service ticket on behalf of a user. |
| Resource account | The AD computer, user, or service account that owns the target service, such as the SQL Server service account. |
| S4U2Proxy | A Kerberos protocol extension used by a service to obtain a ticket to a back-end service on behalf of a user. |
| RSAT | Remote Server Administration Tools. The Active Directory PowerShell module is required for the AD cmdlets in this procedure. |

## Responsibilities

**Database administrators** are responsible for:

- Confirming the SQL Server service account and instance TCP ports.
- Confirming that the requested SPNs match the SQL Server connection names.
- Testing SQL Server authentication after the change.

**Active Directory administrators** are responsible for:

- Confirming the source and resource principals.
- Registering SPNs or granting narrowly scoped permission to register them.
- Configuring and reviewing the `PrincipalsAllowedToDelegateToAccount` property.
- Checking for duplicate SPNs and documenting the change.

**Application owners** are responsible for:

- Confirming the application connection path and the identity that must be delegated.
- Testing the application workflow that requires delegation.

## Prerequisites

Before making changes, confirm the following:

1. The client, intermediate service, and SQL Server are in the same domain or in trusted domains.
2. The SQL Server service runs under a domain account, gMSA, or other account that can own the SQL SPN.
3. The SQL Server instance uses a known TCP port. The examples below use `1433` for a default instance and `50000` for a named instance.
4. The operator has permission to modify the relevant AD objects and register SPNs.
5. The Active Directory PowerShell module is installed on the administration host.
6. The application owner has identified the source principal that must delegate to SQL Server.
7. A current backup or export of the relevant SPN and delegation properties is available.

### Install or enable RSAT

On Windows Server, install the Active Directory PowerShell module from an elevated PowerShell session:

```powershell
Install-WindowsFeature RSAT-AD-PowerShell
```

On Windows client, install **RSAT: Active Directory Domain Services and Lightweight Directory Services Tools** from **Settings > System > Optional features**.

Load the module before running the AD commands:

```powershell
Import-Module ActiveDirectory
```

## Configuration Values

Replace the example values with the values approved for the environment.

| Variable | Example | Description |
| --- | --- | --- |
| `$Hostname` | `DRASSQL2022` | SQL Server host name as represented by its AD computer account. |
| `$DomainFqdn` | `NDT.GLOBAL` | Active Directory DNS domain. |
| `$ServiceUser` | `NDTG\DatabaseUser` | Account running the SQL Server service. |
| `$DefaultPort` | `1433` | TCP port for the default instance. |
| `$NamedPort` | `50000` | TCP port for a named instance. |
| `$SourcePrincipal` | `APPWEB01$` | Front-end computer, service account, or gMSA allowed to delegate. |

## Procedures

### 1. Confirm the SQL Server service account and ports

On the SQL Server host, confirm the account running the Database Engine service. The account used in `setspn` must match the service account exactly.

```powershell
Get-CimInstance Win32_Service |
    Where-Object { $_.Name -like 'MSSQLSERVER' -or $_.Name -like 'MSSQL$*' } |
    Select-Object Name, StartName, State
```

Confirm the listening TCP ports in SQL Server Configuration Manager or with the approved SQL Server configuration inventory. Do not register port `50000` unless the instance actually listens on that port.

### 2. Review existing SPNs

List the SPNs already assigned to the SQL Server service account:

```powershell
setspn -L NDTG\DatabaseUser
```

Query the domain for each required SPN before adding it:

```powershell
setspn -Q MSSQLSvc/DRASSQL2022.NDT.GLOBAL:1433
setspn -Q MSSQLSvc/DRASSQL2022:1433
setspn -Q MSSQLSvc/DRASSQL2022.NDT.GLOBAL:50000
setspn -Q MSSQLSvc/DRASSQL2022:50000
```

If an SPN is already mapped to another account, stop and resolve the ownership conflict. Do not add a duplicate SPN to the SQL Server account.

### 3. Register SQL Server SPNs

Use `-S` rather than `-A`; `-S` checks for duplicates before adding the SPN.

For a default instance on TCP port `1433`:

```powershell
setspn -S MSSQLSvc/DRASSQL2022.NDT.GLOBAL:1433 NDTG\DatabaseUser
setspn -S MSSQLSvc/DRASSQL2022:1433 NDTG\DatabaseUser
```

For a named instance listening on TCP port `50000`:

```powershell
setspn -S MSSQLSvc/DRASSQL2022.NDT.GLOBAL:50000 NDTG\DatabaseUser
setspn -S MSSQLSvc/DRASSQL2022:50000 NDTG\DatabaseUser
```

The FQDN and NetBIOS forms must correspond to names that clients actually use. Register only the required names and ports. For non-TCP connection protocols or named-instance SPN formats, follow the SQL Server SPN guidance in the References section.

### 4. Configure resource-based constrained delegation

RBCD is configured on the **resource account**, using the `PrincipalsAllowedToDelegateToAccount` property. The property value is the approved **source principal**.

#### Option A: SQL Server service runs under a domain user account

The following example allows `APPWEB01$` to delegate to the SQL Server service account `NDTG\DatabaseUser`:

```powershell
$ServiceUser = 'NDTG\DatabaseUser'
$SourcePrincipal = Get-ADComputer -Identity 'APPWEB01'
$ResourceAccount = Get-ADUser -Identity 'DatabaseUser'

Set-ADUser -Identity $ResourceAccount `
    -PrincipalsAllowedToDelegateToAccount $SourcePrincipal
```

If the source is a domain user or service account rather than a computer, retrieve it with the appropriate cmdlet, for example:

```powershell
$SourcePrincipal = Get-ADUser -Identity 'ApplicationService'
```

#### Option B: SQL Server service runs under a computer account

For SQL Server running under the SQL host computer account, configure the SQL host as the resource account and specify the approved front-end principal as the allowed source:

```powershell
$ResourceComputer = Get-ADComputer -Identity 'DRASSQL2022'
$SourcePrincipal = Get-ADComputer -Identity 'APPWEB01'

Set-ADComputer -Identity $ResourceComputer `
    -PrincipalsAllowedToDelegateToAccount $SourcePrincipal
```

#### Option C: Self-delegation from the supplied scripts

The supplied scripts configure the same SQL identity as both the resource and allowed principal. This is a special case and should be used only when the approved design explicitly requires self-delegation.

For a SQL service account:

```powershell
$ServiceAccount = Get-ADUser -Identity 'DatabaseUser'
Set-ADUser -Identity $ServiceAccount `
    -PrincipalsAllowedToDelegateToAccount $ServiceAccount
```

For a SQL host computer account:

```powershell
$Hostname = 'DRASSQL2022'
$ServiceAccount = Get-ADUser -Identity 'DatabaseUser'
Set-ADComputer -Identity $Hostname `
    -PrincipalsAllowedToDelegateToAccount $ServiceAccount
```

Do not use the self-delegation example as a substitute for identifying the real front-end source principal. Setting the property without the intended principal can overwrite an existing allow list.

### 5. Verify the delegation property

For a user resource account:

```powershell
Get-ADUser -Identity 'DatabaseUser' `
    -Properties PrincipalsAllowedToDelegateToAccount |
    Select-Object SamAccountName, PrincipalsAllowedToDelegateToAccount
```

For a computer resource account:

```powershell
Get-ADComputer -Identity 'DRASSQL2022' `
    -Properties PrincipalsAllowedToDelegateToAccount |
    Select-Object Name, PrincipalsAllowedToDelegateToAccount
```

For a gMSA resource account, use `Get-ADServiceAccount` and `Set-ADServiceAccount` instead of the user cmdlets:

```powershell
Get-ADServiceAccount -Identity 'SqlServiceGmsa' `
    -Properties PrincipalsAllowedToDelegateToAccount |
    Select-Object SamAccountName, PrincipalsAllowedToDelegateToAccount
```

### 6. Refresh tickets and test Kerberos

On the client or front-end server, purge cached tickets and reconnect using the same server name and port represented by the SPN:

```powershell
klist purge
klist get MSSQLSvc/DRASSQL2022.NDT.GLOBAL:1433
klist
```

The ticket cache should contain an entry for the SQL Server SPN. A ticket alone does not prove that the application completed delegation; test the actual application path as well.

On the SQL Server connection, confirm the authentication scheme:

```sql
SELECT
    session_id,
    auth_scheme,
    net_transport,
    local_net_address,
    local_tcp_port
FROM sys.dm_exec_connections
WHERE session_id = @@SPID;
```

The `auth_scheme` value should be `KERBEROS`. A local connection may use NTLM; test from the remote client or application tier that requires Kerberos.

Confirm the SQL Server service account independently:

```sql
SELECT servicename, service_account
FROM sys.dm_server_services;
```

## Troubleshooting

| Symptom | Checks |
| --- | --- |
| `auth_scheme` is `NTLM` | Confirm the client uses a domain name covered by the SPN, TCP is enabled, the port is correct, and the SPN maps to the SQL Server service account. |
| `setspn -S` reports a duplicate | Run `setspn -Q <SPN>` and identify the owning account. Remove or correct the stale registration only after confirming it is not used by another service. |
| SQL Server cannot register its SPN automatically | Grant the SQL Server startup account the narrowly scoped validated write permission for SPNs, or register the SPN manually. Review the SQL Server error log. |
| Delegation property is empty or unexpected | Query the resource account with `Get-ADUser`, `Get-ADComputer`, or `Get-ADServiceAccount` and confirm the source principal was added to the resource account. |
| Kerberos works to SQL Server but delegation fails | Confirm the request is going through the intended front-end service, the source principal is the service identity actually making the request, tickets were purged after the change, and the application supports delegated Windows credentials. |
| Changes appear not to take effect | Allow AD replication to complete, purge cached tickets, reconnect using the exact SPN name, and retest from the remote client. |

## Rollback

Record the current SPNs and delegation property before changing them. To remove an SPN that was added by this procedure, first verify that it belongs to the intended account, then run:

```powershell
setspn -D MSSQLSvc/DRASSQL2022.NDT.GLOBAL:1433 NDTG\DatabaseUser
```

To remove RBCD entirely from a resource account, clear the property only with approved change authority:

```powershell
Set-ADUser -Identity 'DatabaseUser' -Clear PrincipalsAllowedToDelegateToAccount
```

For a computer resource account:

```powershell
Set-ADComputer -Identity 'DRASSQL2022' -Clear PrincipalsAllowedToDelegateToAccount
```

If other approved principals use the resource account, remove only the affected principal rather than clearing the full property. Preserve and restore the documented pre-change value when possible.

## References

- [Kerberos Constrained Delegation Overview in Windows Server](https://learn.microsoft.com/en-us/windows-server/security/kerberos/kerberos-constrained-delegation-overview)
- [Register a Service Principal Name for Kerberos Connections - SQL Server](https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/register-a-service-principal-name-for-kerberos-connections)
- [Setspn command](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/setspn)
- [Set-ADComputer cmdlet](https://learn.microsoft.com/en-us/powershell/module/activedirectory/set-adcomputer)
- [Set-ADUser cmdlet](https://learn.microsoft.com/en-us/powershell/module/activedirectory/set-aduser)
- [Set-ADServiceAccount cmdlet](https://learn.microsoft.com/en-us/powershell/module/activedirectory/set-adserviceaccount)

## Source Files

- `Setup Resource-Based Constrained Delegation.ps1`
- `Setup Resource-Based Constrained Delegation - Copy.txt`