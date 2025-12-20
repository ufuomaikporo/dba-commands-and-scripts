USE [DrasInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_ReportFailedBackups]    Script Date: 2025-04-29 8:45:00 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE   PROCEDURE [dbo].[sp_ReportFailedBackups] @JobName NVARCHAR(500)
AS
BEGIN
	DECLARE @SQL NVARCHAR(MAX)
	DECLARE @TargetDBList NVARCHAR(MAX)

	DROP TABLE IF EXISTS FailedAgentJobs

	SELECT @TargetDBList = 'SELECT name COLLATE SQL_Latin1_General_CP1_CI_AS FROM sys.databases 
	WHERE state_desc = ''ONLINE'' AND dbi.ServerName = @@SERVERNAME' + CHAR(10) + 'UNION' + CHAR(10) +
	STRING_AGG('SELECT name FROM [' + server_name + '].master.sys.databases WHERE state_desc = ''ONLINE'' 
	AND dbi.ServerName = ''' + server_name + '''' + CHAR(10) , 'UNION' + CHAR(10)) 
	FROM msdb.dbo.systargetservers 

	SET @SQL = 'SELECT DISTINCT dbi.JobId 
					   ,aj.JobName
					   ,dbi.ServerName
					   ,DatabaseName
					   ,CASE WHEN LastBackupFinishDate < DATEADD(DAY, -1, GETDATE())
				   				THEN ''No Recent Backup''
							WHEN LastBackupMessage NOT LIKE ''SUCCESS%'' 
								THEN LastBackupMessage
					   END Status
					   ,FilePosition
					   ,LastBackupType
					   ,StepExecutionDate
					   ,LastBackupStartDate
					   ,LastBackupFinishDate
					   ,LastBackupMessage
					   ,dbi.LastModByUserId
	INTO FailedAgentJobs
	FROM ##temp_DatabasebackupInfo dbi
	LEFT JOIN Agentjob aj ON  dbi.JobId = aj.JobId
	AND aj.StepName LIKE ''%Job%outcome%''
	WHERE DatabaseName LIKE ''%IRAS%'' AND (LastBackupMessage NOT LIKE ''SUCCESS%''
	OR LastBackupFinishDate < DATEADD(DAY, -1, GETDATE())) AND DatabaseName LIKE ''%IRAS%''
	AND DatabaseName IN (' + @TargetDBList + ');'

	EXECUTE (@SQL)

	SET @SQL = 'WITH CTE AS
	(
	SELECT * FROM FailedAgentJobs tmp
	WHERE Status LIKE ''%Fail%''
	UNION
	SELECT * FROM FailedAgentJobs tmp
	WHERE Status LIKE ''No%Backup%''
	AND EXISTS (SELECT ServerName, COUNT(DISTINCT Status)
				FROM FailedAgentJobs t2
				WHERE t2.ServerName = tmp.ServerName 
				GROUP BY ServerName HAVING COUNT(DISTINCT Status) > 1)
	UNION
	SELECT JobId
		   ,JobName
		   ,ServerName
		   ,NULL AS DatabaseName
		   ,Status
		   ,NULL AS FilePosition 
		   ,NULL AS LastBackupType
		   ,StepExecutionDate
			,NULL ASLastBackupStartDate
			,NULL AS LastBackupFinishDate
			,NULL AS LastBackupMessage
			,NULL AS LastModByUserId
	FROM FailedAgentJobs tmp
	WHERE Status LIKE ''No%Backup%''
	AND EXISTS (SELECT ServerName, COUNT(DISTINCT Status)
				FROM FailedAgentJobs t2
				WHERE t2.ServerName = tmp.ServerName
				GROUP BY ServerName HAVING COUNT(DISTINCT Status) = 1) 
	GROUP BY JobId, JobName, ServerName, Status, StepExecutionDate, LastModByUserId
	UNION 
	SELECT DISTINCT dbi.JobId, dbi2.JobName, 
	ts.server_name, NULL DatabaseName, ''No Recent Backup'' AS Status, NULL 
	, NULL, NULL, NULL, NULL, NULL, NULL
	FROM ##temp_DatabasebackupInfo dbi
	RIGHT JOIN msdb.dbo.systargetservers ts
	ON ts.server_name = dbi.ServerName
	CROSS JOIN (SELECT DISTINCT REPLACE(JobName, ''(Local)'', '''') JobName FROM FailedAgentJobs) dbi2
	WHERE dbi.ServerName IS NULL
	)
	SELECT JobId
		   ,cte.JobName
		   ,cte.ServerName
		   ,StepExecutionDate AS JobExecutionDate
		   ,DatabaseName
		   ,Status
		   ,FilePosition
		   ,LastBackupType
		   ,LastBackupStartDate
		   ,LastBackupFinishDate
		   ,LastBackupMessage
		   ,cte.LastModByUserId
	FROM CTE 
	JOIN AgentJobEmailTracker at
	ON cte.JobName = at.JobName
	AND FORMAT(cte.StepExecutionDate, ''yyyy-MM-dd HH:mm:00'') = FORMAT(at.JobExecutionDate, ''yyyy-MM-dd HH:mm:00'')
	ORDER BY cte.ServerName, DatabaseName'
	
	PRINT @SQL
	EXECUTE (@SQL);

END
GO


