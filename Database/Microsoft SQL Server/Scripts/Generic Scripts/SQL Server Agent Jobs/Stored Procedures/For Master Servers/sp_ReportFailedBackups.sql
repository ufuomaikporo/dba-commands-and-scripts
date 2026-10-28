USE [DrasInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_ReportFailedBackups]    Script Date: 2025-02-04 9:14:17 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

USE [DrasInternal]
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_ReportFailedBackups] @JobName NVARCHAR(500)    
AS    
BEGIN    
     
	DECLARE @SQL NVARCHAR(MAX)    
	DECLARE @TargetDBList NVARCHAR(MAX)    
	DROP TABLE IF EXISTS FailedAgentJobs    
      
	SELECT @TargetDBList = 'SELECT name COLLATE SQL_Latin1_General_CP1_CI_AS FROM sys.databases WHERE @@SERVERNAME = tmp.ServerName' + CHAR(10) + 'UNION' + CHAR(10) +    
	STRING_AGG('SELECT name FROM [' + server_name + '].master.sys.databases WHERE ''' + server_name + ''' = tmp.ServerName' + CHAR(10) , 'UNION' + CHAR(10))     
	FROM msdb.dbo.systargetservers    
 
	-- Find Servers with Agent Jobs that failed to complete (have a failed StepStatus)    
	SET @SQL = 'WITH CTE AS     
	(SELECT JobId    
	  ,JobName    
	  ,ServerName    
	  ,CAST(NULL AS VARCHAR(100)) AS DatabaseName    
	  ,StepStatus    
	  ,NULL AS FilePosition    
	  ,CAST(NULL AS VARCHAR(100)) AS LastBackupType    
	  ,StepExecutionDate    
	  ,StepDuration    
	  ,CAST(NULL AS DATETIME) AS LastBackupStartDate    
	  ,CAST(NULL AS DATETIME) AS LastBackupFinishDate    
	  ,LogMessage    
	  ,LastModByUserId    
	  ,ROW_NUMBER() OVER (PARTITION BY JobName, ServerName ORDER BY StepExecutionDate DESC) rownum    
	FROM AgentJob WHERE StepName LIKE ''%Job%outcome%''    
	 )    
	 SELECT JobId    
	  ,JobName    
	  ,ServerName    
	  ,CAST(NULL AS VARCHAR(100)) AS DatabaseName    
	  ,StepStatus AS JobStatus    
	  ,StepExecutionDate AS JobExecutionDate    
	  ,StepDuration    
	  ,LastBackupStartDate    
	  ,LastBackupFinishDate    
	  ,CAST (LogMessage AS NVARCHAR(MAX)) AS ReportedIssue    
	  ,LastModByUserId    
	INTO FailedAgentJobs    
	FROM CTE WHERE rownum = 1    
	AND StepStatus NOT LIKE ''Succee%'' AND StepStatus <> ''Completed''    
	AND JobName = ''' + @JobName + '''
	AND ServerName IN (SELECT server_name FROM msdb.dbo.systargetservers)';    
    
	EXECUTE (@SQL)  

	-- Find target databases that did not initiate the latest Agent Job    
	SET @SQL = 'WITH CTE AS     
	(SELECT JobId, aet.JobName, ServerName, MAX(StepExecutionDate) StepExecutionDate     
	FROM AgentJob aj    
	JOIN AgentJobEmailTracker aet    
	ON aet.JobName = REPLACE(aj.JobName, ''(Local)'', '''')    
	   AND FORMAT(aj.StepExecutionDate, ''yyyy-MM-dd HH:mm:00'') = FORMAT(aet.JobExecutionDate, ''yyyy-MM-dd HH:mm:00'')    
	WHERE REPLACE(aj.JobName, ''(Local)'', '''') = ''' + @JobName + '''    
	GROUP BY JobId, aet.JobName, ServerName    
	)    
	INSERT INTO FailedAgentJobs    
	SELECT DISTINCT (SELECT TOP 1 JobId FROM AgentJob WHERE JobName = ''' + @JobName + '''    
	    AND ServerName <> @@SERVERNAME)    
	  ,cte.JobName    
	  ,server_name    
	  ,CAST(NULL AS VARCHAR(100)) AS DatabaseName    
	  ,''Missed last job run''    
	  ,(SELECT MAX(StepExecutionDate) FROM cte)    
	  ,NULL    
	  ,NULL    
	  ,NULL    
	  ,''Latest job was not initiated on target server'' AS ReportedIssue    
	  ,NULL    
	FROM msdb.dbo.systargetservers ts    
	CROSS JOIN cte    
	WHERE server_name NOT IN (SELECT ServerName FROM cte)    
	UNION    
	SELECT DISTINCT (SELECT TOP 1 JobId FROM AgentJob WHERE JobName = ''' + @JobName + '''    
	    AND ServerName = @@SERVERNAME)    
	  , cte.JobName, @@SERVERNAME    
	  ,CAST(NULL AS VARCHAR(100)) AS DatabaseName    
	  ,''Missed last job run''    
	  ,(SELECT MAX(StepExecutionDate) FROM cte)    
	  ,NULL    
	  ,NULL    
	  ,NULL    
	  ,''Latest job was not initiated on target server'' AS ReportedIssue    
	  ,NULL    
	FROM cte    
	WHERE @@SERVERNAME NOT IN (SELECT ServerName FROM cte)'    
    
	print @sql
	EXECUTE (@SQL)    
    
	-- Find Servers with agent jobs that completed with errors    
	SET @SQL = 'WITH CTE AS    
	   (SELECT tab1.JobId,    
	       tmp.JobName,    
	       tab1.ServerName,     
	       DatabaseName,    
	       StepStatus,    
	       StepExecutionDate    
	       RestoreStatus,    
	       CASE WHEN RestoreStatus LIKE ''%INVALID%'' THEN ''Invalid For Restore''    
	        WHEN DaysSinceLastBackup > 1 THEN CAST(DaysSinceLastBackup AS NVARCHAR) + '' Days Since Last Backup''    
	        WHEN LastBackupStartDate < FORMAT(GETDATE(), ''yyyy-MM-dd 10:00:00'')     
	         AND DATEPART(HOUR, GETDATE()) >= 10 AND DATEPART(HOUR, GETDATE()) <= 15 THEN ''No Recent Backup''    
	       END AS ReportedIssue,    
	  CASE WHEN LastBackupType LIKE ''%Differential%'' THEN ''Differential''    
	      WHEN LastBackupType LIKE ''%Full%'' THEN ''Full''    
	  END AS LastValidBackupType,    
	  LastBackupStartDate,    
	  LastBackupFinishDate,    
	  tmp.StepExecutionDate,    
	  tab1.LastModByUserId,    
	  ROW_NUMBER() OVER (PARTITION BY JobName, tab1.ServerName, DatabaseName ORDER BY StepExecutionDate DESC) rownum    
	FROM dbo.DatabaseBackupInfo tab1    
	JOIN AgentJob tmp    
	 ON tab1.ServerName = tmp.ServerName    
	 AND tab1.JobId = tmp.JobId    
	WHERE RestoreStatus <> ''Valid'' AND JobName = ''' + @JobName + '''    
	AND DatabaseName IN (' + @TargetDBList + ')    
	)    
	INSERT INTO FailedAgentJobs    
	SELECT JobId    
	  ,JobName    
	  ,ServerName    
	  ,DatabaseName    
	  ,StepStatus     
	  ,StepExecutionDate     
	  ,NULL    
	  ,LastBackupStartDate    
	  ,LastBackupFinishDate    
	  ,ReportedIssue    
	  ,LastModByUserId    
	FROM CTE    
	WHERE rownum = 1     
	AND ServerName NOT IN (SELECT ServerName FROM FailedAgentJobs)  
	AND EXISTS (SELECT * FROM AgentJobEmailTracker WHERE JobName = CTE.JobName  
	AND FORMAT(CTE.StepExecutionDate, ''yyyy-MM-dd HH:mm:00'') = FORMAT(JobExecutionDate, ''yyyy-MM-dd HH:mm:00''))'    
    
	EXECUTE (@SQL)   
	
	SELECT * FROM FailedAgentJobs
	ORDER BY ServerName, DatabaseName

END    
GO

/*

EXEC dbo.sp_ReportFailedBackups @JobName= 'SQL Server Database Backup'

*/