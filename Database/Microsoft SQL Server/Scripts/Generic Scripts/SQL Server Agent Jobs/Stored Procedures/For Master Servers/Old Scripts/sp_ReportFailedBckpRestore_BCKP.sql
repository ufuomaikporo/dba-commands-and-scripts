USE [DrasInternal]
GO

IF OBJECT_ID('sp_ReportFailedRestore') IS NOT NULL
BEGIN
	DROP PROCEDURE sp_ReportFailedRestore
END
GO


CREATE PROCEDURE [dbo].[sp_ReportFailedRestore] @JobName NVARCHAR(500)
AS
BEGIN
	
	DECLARE @SQL NVARCHAR(MAX)
	DECLARE @TargetDBList NVARCHAR(MAX)

	SELECT @TargetDBList = 'SELECT name COLLATE SQL_Latin1_General_CP1_CI_AS FROM sys.databases' + CHAR(10) + 'UNION' + CHAR(10) +
	STRING_AGG('SELECT name FROM [' + server_name + '].master.sys.databases' + CHAR(10) , 'UNION' + CHAR(10)) 
	FROM msdb.dbo.systargetservers

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
	AND DatabaseName IN (' + @TargetDBList + ')
	AND (LastBackupMessage <> ''SUCCESSFUL'' OR RestoreStatus <> ''VALID'' OR DaysSinceLastBackup > 1)
	AND RestoreStatus IS NOT NULL
	ORDER BY tab1.ServerName'

	EXECUTE (@SQL)
END
GO

/*

EXECUTE sp_ReportFailedBckpRestore @JobName = 'SQL Server Database Backup'

*/

