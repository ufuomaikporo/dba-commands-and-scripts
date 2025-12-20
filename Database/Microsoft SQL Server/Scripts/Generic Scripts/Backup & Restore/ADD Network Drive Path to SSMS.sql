USE master

--Enable xp_cmdshell command in SQL Server instance
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO

EXEC sp_configure 'xp_cmdshell',1
GO
RECONFIGURE
GO

-- Add Network drive paths  ***** EXEC XP_CMDSHELL 'NET USE DRIVE: \\FolderPath'
EXEC XP_CMDSHELL 'NET USE H: \\backups.cgy.dynamicrisk.net\DB_Backups_Nightly' 
EXEC XP_CMDSHELL 'NET USE I: \\backups.cgy.dynamicrisk.net\DB_Backups_Monthly' 