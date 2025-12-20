USE DrasInternal

/*
This stored procedure generates a report on failed, invalid or old backups from the dbo.DatabaseBackupInfo
table. 

*********************************** NOTES FOR RUNNING STORED PROC *************************************

1. MUST run on the designated master or a server with the dbo.DatabaseBackupInfo table already created 

*******************************************************************************************************

-- Example execution

EXEC sp_ReportFailedBackups @MasterServer = 'DRASSQL2022', @JobName = 'SQL Server Database Backup'

*/

IF OBJECT_ID('sp_ReportFailedBackups') IS NOT NULL
BEGIN
	DROP PROCEDURE sp_ReportFailedBackups
END
GO
CREATE PROCEDURE [dbo].[sp_ReportFailedBackups] @MasterServer NVARCHAR(100), @JobName NVARCHAR(500) 
AS
BEGIN
	--SELECT tab1.ServerName, 
	--		DatabaseName,
	--		CASE	WHEN LastBackupMessage <> 'SUCCESSFUL' THEN 'Failed Backup'
	--			WHEN RestoreStatus <> 'VALID' AND @JobName LIKE '%Restore%Test%' THEN 'Invalid For Restore'
	--			WHEN DaysSinceLastBackup > 1 THEN CAST(DaysSinceLastBackup AS NVARCHAR) + ' Days Since Last Backup'
	--			WHEN LastBackupStartDate < FORMAT(GETDATE(), 'yyyy-MM-dd 10:00:00') 
	--				AND DATEPART(HOUR, GETDATE()) >= 10 AND DATEPART(HOUR, GETDATE()) <= 15 THEN 'No Recent Backup'
	--		END AS ReportedIssue,
	--		CASE WHEN LastBackupType LIKE '%Differential%' THEN 'Differential'
	--	   		WHEN LastBackupType LIKE '%Full%' THEN 'Full'
	--		END AS LastValidBackupType,
	--		LastBackupStartDate,
	--		tmp.JobExecutionDate,
	--		 CAST(tmp.Duration/10000 AS VARCHAR) + 'hr:' + CAST((tmp.Duration % 10000)/100 AS VARCHAR) 
	--			+ 'min:' + CAST((tmp.Duration % 100) AS VARCHAR) + 'sec' AS Duration
	--FROM dbo.DatabaseBackupInfo tab1
	--JOIN Temp_JobsTable tmp
	--	ON tab1.ServerName = tmp.ServerName
	--	AND JobName = @JobName
	--WHERE DatabaseName LIKE '%IRAS%'
	--AND DatabaseName IN (SELECT name FROM sys.databases)
	--AND (LastBackupMessage <> 'SUCCESSFUL' OR RestoreStatus <> 'VALID' OR DaysSinceLastBackup > 1)
	--ORDER BY tab1.ServerName

	DECLARE @SQL NVARCHAR(MAX)

	IF @@SERVERNAME = @MasterServer
	BEGIN
		SET @SQL = 'SELECT tab1.ServerName, 
				DatabaseName,
				CASE	WHEN LastBackupMessage <> ''SUCCESSFUL'' THEN ''Failed Backup''
					WHEN RestoreStatus <> ''VALID'' AND ''' + @JobName + ''' LIKE ''%Restore%Test%'' THEN ''Invalid For Restore''
					WHEN DaysSinceLastBackup > 1 THEN CAST(DaysSinceLastBackup AS NVARCHAR) + '' Days Since Last Backup''
					WHEN LastBackupStartDate < FORMAT(GETDATE(), ''yyyy-MM-dd 10:00:00'') 
						AND DATEPART(HOUR, GETDATE()) >= 10 AND DATEPART(HOUR, GETDATE()) <= 15 THEN ''No Recent Backup''
				END AS ReportedIssue,
				CASE WHEN LastBackupType LIKE ''%Differential%'' THEN ''Differential''
		   			WHEN LastBackupType LIKE ''%Full%'' THEN ''Full''
				END AS LastValidBackupType,
				LastBackupStartDate,
				tmp.JobExecutionDate,
					CAST(tmp.Duration/10000 AS VARCHAR) + ''hr:'' + CAST((tmp.Duration % 10000)/100 AS VARCHAR) 
					+ ''min:'' + CAST((tmp.Duration % 100) AS VARCHAR) + ''sec'' AS Duration
		FROM dbo.DatabaseBackupInfo tab1
		JOIN Temp_JobsTable tmp
			ON tab1.ServerName = tmp.ServerName
			AND JobName = ''' + @JobName + '''
		WHERE DatabaseName LIKE ''%IRAS%''
		AND DatabaseName IN (SELECT name FROM sys.databases)
		AND (LastBackupMessage <> ''SUCCESSFUL'' OR RestoreStatus <> ''VALID'' OR DaysSinceLastBackup > 1)
		ORDER BY tab1.ServerName'
	END
	ELSE
	BEGIN

		SET @SQL = 'SELECT * FROM OPENQUERY([' + @MasterServer + '], ''SELECT tab1.ServerName, 
				DatabaseName,
				CASE	WHEN LastBackupMessage <> ''''SUCCESSFUL'''' THEN ''''Failed Backup''''
					WHEN RestoreStatus <> ''''VALID'''' AND ''''' + @JobName + ''''' LIKE ''''%Restore%Test%'''' THEN ''''Invalid For Restore''''
					WHEN DaysSinceLastBackup > 1 THEN CAST(DaysSinceLastBackup AS NVARCHAR) + '''' Days Since Last Backup''''
					WHEN LastBackupStartDate < FORMAT(GETDATE(), ''''yyyy-MM-dd 10:00:00'''') 
						AND DATEPART(HOUR, GETDATE()) >= 10 AND DATEPART(HOUR, GETDATE()) <= 15 THEN ''''No Recent Backup''''
				END AS ReportedIssue,
				CASE WHEN LastBackupType LIKE ''''%Differential%'''' THEN ''''Differential''''
		   			WHEN LastBackupType LIKE ''''%Full%'''' THEN ''''Full''''
				END AS LastValidBackupType,
				LastBackupStartDate,
				tmp.JobExecutionDate,
				 CAST(tmp.Duration/10000 AS VARCHAR) + ''''hr:'''' + CAST((tmp.Duration % 10000)/100 AS VARCHAR) 
					+ ''''min:'''' + CAST((tmp.Duration % 100) AS VARCHAR) + ''''sec'''' AS Duration
		FROM DrasInternal.dbo.DatabaseBackupInfo tab1
		JOIN DrasInternal.dbo.Temp_JobsTable tmp
			ON tab1.ServerName = tmp.ServerName
			AND JobName = ''''' + @JobName + '''''
		WHERE DatabaseName LIKE ''''%IRAS%''''
		AND (LastBackupMessage <> ''''SUCCESSFUL'''' OR RestoreStatus <> ''''VALID'''' OR DaysSinceLastBackup > 1)
			'') rmt
		WHERE rmt.DatabaseName IN (SELECT name FROM sys.databases)
		ORDER BY rmt.ServerName'

	END

	EXECUTE(@SQL)

END
