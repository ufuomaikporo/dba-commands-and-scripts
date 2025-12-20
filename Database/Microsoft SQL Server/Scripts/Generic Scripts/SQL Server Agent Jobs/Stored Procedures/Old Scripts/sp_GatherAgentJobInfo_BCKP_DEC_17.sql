USE DrasInternal
/*

The following table needs to be created on the master Agent server

IF OBJECT_ID ('AgentJob') IS NOT NULL
BEGIN
	DROP TABLE AgentJob
END

CREATE TABLE AgentJob (ServerName VARCHAR(100),
							 JobName VARCHAR(100),
							 JobInstanceId INT,
							 StepNumber INT,
							 StepName VARCHAR(256),
							 StepStatus VARCHAR(40),
							 Message NTEXT,
							 LogId INT,
							 LogMessage NTEXT,
							 LogSize BIGINT,
							 LogCreateDate DATETIME,
							 StepExecutionDate DATETIME,
							 StepDuration VARCHAR(20)
							 )

*/

IF OBJECT_ID('dbo.sp_GatherAgentJobInfo') IS NOT NULL
BEGIN
	DROP PROCEDURE [dbo].[sp_GatherAgentJobInfo]
END
GO

CREATE PROCEDURE [dbo].[sp_GatherAgentJobInfo] @MasterServer NVARCHAR(100)
AS
BEGIN
	DECLARE @SQL NVARCHAR(MAX)

	IF (@MasterServer = @@SERVERNAME)
	BEGIN
		SET @SQL = 'DELETE FROM DrasInternal.dbo.AgentJob WHERE ServerName = @@SERVERNAME'
	END
	ELSE
	BEGIN
		SET @SQL = 'DELETE FROM OPENQUERY ([' + @MasterServer + '], ''SELECT * FROM DrasInternal.dbo.AgentJob
		WHERE ServerName = ''''' + @@SERVERNAME + ' '''' '')'
	END

	EXECUTE (@SQL);


 
	IF (@MasterServer = @@SERVERNAME)
	BEGIN
		SET @SQL = 'WITH CTE AS 
		(SELECT ROW_NUMBER() OVER (PARTITION BY J.name, T.step_name ORDER BY msdb.dbo.agent_datetime(T.run_date, T.run_time) DESC) row_num,
					JobName = J.name,
					@@SERVERNAME AS ServerName,
					JobInstanceId = T.instance_id,
					StepNumber = T.step_id,
					StepName = T.step_name,
					StepStatus = CASE T.run_status
					WHEN 0 THEN ''Failed''
					WHEN 1 THEN ''Succeeded''
					WHEN 2 THEN ''Retry''
					WHEN 3 THEN ''Canceled''
					ELSE ''Running'' END,
					Message = T.message,
					LogId = jsl.log_id,
					LogMessage = jsl.log,
					LogSize = jsl.log_size,
					LogCreateDate = jsl.date_created,
					JobExecuteDate = msdb.dbo.agent_datetime(T.run_date, T.run_time),
					StepDuration = CAST(T.run_duration/10000 AS VARCHAR) + ''hr:'' + CAST((T.run_duration % 10000)/100 AS VARCHAR) 
						+ ''min:'' + CAST((T.run_duration % 100) AS VARCHAR) + ''sec''
			FROM msdb.dbo.sysjobhistory T
			JOIN  msdb.dbo.sysjobs J
			ON J.job_id = T.job_id  
			JOIN msdb.dbo.sysjobsteps js
			ON T.job_id = js.job_id
			JOIN (SELECT * FROM msdb.dbo.sysjobstepslogs ) AS jsl
			ON js.step_uid = jsl.step_uid
		)
		INSERT DrasInternal.dbo.AgentJob
		SELECT ServerName,
			   JobName,
			   JobInstanceId,
			   StepNumber,
			   StepName,
			   StepStatus,
			   Message,
			   LogId,
			   LogMessage, 
			   LogSize,
			   LogCreateDate,
			   JobExecuteDate,
			   StepDuration
		FROM CTE tab1
		WHERE row_num = 1
		AND (SELECT MAX(JobInstanceId) FROM CTE WHERE StepNumber = 0 AND JobName = tab1.JobName) - JobInstanceId 
		<= (SELECT MAX(StepNumber) FROM CTE WHERE JobName = tab1.JobName)
		AND tab1.JobName <> ''Gather SQL Server Agent Jobs Status''
		ORDER BY tab1.JobName, tab1.StepNumber'

		EXECUTE (@SQL)
	END
	ELSE
	BEGIN

		SET @SQL = 'WITH CTE AS 
		(SELECT ROW_NUMBER() OVER (PARTITION BY J.name, T.step_name ORDER BY msdb.dbo.agent_datetime(T.run_date, T.run_time) DESC) row_num,
					JobName = J.name,
					@@SERVERNAME AS ServerName,
					JobInstanceId = T.instance_id,
					StepNumber = T.step_id,
					StepName = T.step_name,
					StepStatus = CASE T.run_status
					WHEN 0 THEN ''Failed''
					WHEN 1 THEN ''Succeeded''
					WHEN 2 THEN ''Retry''
					WHEN 3 THEN ''Canceled''
					ELSE ''Running'' END,
					Message = T.message,
					LogId = jsl.log_id,
					LogMessage = jsl.log,
					LogSize = jsl.log_size,
					LogCreateDate = jsl.date_created,
					JobExecuteDate = msdb.dbo.agent_datetime(T.run_date, T.run_time),
					StepDuration = CAST(T.run_duration/10000 AS VARCHAR) + ''hr:'' + CAST((T.run_duration % 10000)/100 AS VARCHAR) 
						+ ''min:'' + CAST((T.run_duration % 100) AS VARCHAR) + ''sec''
			FROM msdb.dbo.sysjobhistory T
			JOIN  msdb.dbo.sysjobs J
			ON J.job_id = T.job_id  
			JOIN msdb.dbo.sysjobsteps js
			ON T.job_id = js.job_id
			JOIN (SELECT * FROM msdb.dbo.sysjobstepslogs ) AS jsl
			ON js.step_uid = jsl.step_uid
		)
		INSERT OPENQUERY ([' + @MasterServer + '], ''SELECT * FROM DrasInternal.dbo.AgentJob'') 
		SELECT ServerName,
			   JobName,
			   JobInstanceId,
			   StepNumber,
			   StepName,
			   StepStatus,
			   Message,
			   LogId,
			   LogMessage, 
			   LogSize,
			   LogCreateDate,
			   JobExecuteDate,
			   StepDuration
		FROM CTE tab1
		WHERE row_num = 1
		AND (SELECT MAX(JobInstanceId) FROM CTE WHERE StepNumber = 0 AND JobName = tab1.JobName) - JobInstanceId 
		<= (SELECT MAX(StepNumber) FROM CTE WHERE JobName = tab1.JobName)
		AND tab1.JobName <> ''Gather SQL Server Agent Jobs Status''
		ORDER BY tab1.JobName, tab1.StepNumber'

		EXECUTE (@SQL)
	END
END