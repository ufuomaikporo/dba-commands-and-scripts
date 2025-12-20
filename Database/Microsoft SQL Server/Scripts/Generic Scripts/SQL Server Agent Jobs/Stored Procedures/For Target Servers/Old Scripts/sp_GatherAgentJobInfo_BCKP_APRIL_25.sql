USE DrasInternal
/*
This stored procedure gathers information on completed SQL Server agent jobs and sends the info
to the DrasInternal.dbo.AgentJob table

*********************************** NOTES FOR RUNNING STORED PROC *************************************

1. MUST Run on the target server
2. A master server should be designated with the dbo.AgentJob table already created 

*******************************************************************************************************

-- Sample execution

EXECUTE sp_GatherAgentJobInfo @MasterServer = 'DRASSQL2022'

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
	DECLARE @TargetServer NVARCHAR(100)

	SET @TargetServer = @@SERVERNAME

	IF OBJECT_ID ('tempdb..##Temp_AgentJob', 'U') IS NOT NULL
	BEGIN
		DROP TABLE ##Temp_AgentJob
	END;

	WITH CTE AS 
	(SELECT ROW_NUMBER() OVER (PARTITION BY J.name, T.step_name ORDER BY msdb.dbo.agent_datetime(T.run_date, T.run_time) DESC) row_num,
			JobName = J.name,
			@@SERVERNAME AS ServerName,
			JobInstanceId = T.instance_id,
			StepNumber = T.step_id,
			StepName = T.step_name,
			StepStatus = CASE T.run_status
			WHEN 0 THEN 'Failed'
			WHEN 1 THEN 'Succeeded'
			WHEN 2 THEN 'Retry'
			WHEN 3 THEN 'Canceled'
			ELSE 'Running' END,
			Message = T.message,
			LogId = jsl.log_id,
			LogMessage = jsl.log,
			LogSize = jsl.log_size,
			LogCreateDate = jsl.date_created,
			JobExecuteDate = msdb.dbo.agent_datetime(T.run_date, T.run_time),
			StepDuration = T.run_duration
	FROM msdb.dbo.sysjobhistory T
	JOIN  msdb.dbo.sysjobs J
	ON J.job_id = T.job_id  
	JOIN msdb.dbo.sysjobsteps js
	ON T.job_id = js.job_id
	JOIN (SELECT * FROM msdb.dbo.sysjobstepslogs ) AS jsl
	ON js.step_uid = jsl.step_uid
	)SELECT ServerName,
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
	INTO ##Temp_AgentJob
	FROM CTE tab1
	WHERE row_num = 1
	AND tab1.JobName NOT LIKE '%Agent%Job%Status%'
	ORDER BY tab1.JobName, tab1.StepNumber
 
	IF (@MasterServer = @@SERVERNAME)
	BEGIN
		SET @SQL = 'INSERT INTO DrasInternal.dbo.AgentJob (ServerName,
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
														   StepExecutionDate,
														   StepDuration)
		SELECT ServerName,
			   JobName,
			   JobInstanceId,
			   StepNumber,
			   StepName,
			   CASE WHEN PATINDEX(''%Operation canceled%'', LogMessage) <> 0 THEN ''Canceled''
					WHEN PATINDEX(''%Error%'', LogMessage) <> 0 THEN ''Failed''
					ELSE StepStatus
			   END,
			   Message,
			   LogId,
			   LogMessage,
			   LogSize,
			   LogCreateDate,
			   JobExecuteDate,
			   StepDuration 
		FROM ##Temp_AgentJob tab1
		WHERE NOT EXISTS (SELECT * FROM DrasInternal.dbo.AgentJob ajs 
						WHERE tab1.ServerName = ajs.ServerName
						AND tab1.JobName = ajs.JobName AND tab1.StepNumber = ajs.StepNumber
						AND tab1.JobExecuteDate = ajs.StepExecutionDate)
		ORDER BY tab1.JobName, tab1.StepNumber
		
		DELETE FROM DrasInternal.dbo.AgentJob 
		WHERE StepExecutionDate < DATEADD(MONTH, -6, GETDATE())'

	END
	ELSE
	BEGIN

		SET @SQL = 'INSERT INTO OPENQUERY([' + @MasterServer + '], ''SELECT ServerName,
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
																			StepExecutionDate,
																			StepDuration
																	FROM DrasInternal.dbo.AgentJob'')
		SELECT ServerName,
			   JobName,
			   JobInstanceId,
			   StepNumber,
			   StepName,
			   CASE WHEN PATINDEX(''%Operation canceled%'', LogMessage) <> 0 THEN ''Canceled''
					WHEN PATINDEX(''%Error%'', LogMessage) <> 0 THEN ''Failed''
					ELSE StepStatus
			   END,
			   Message,
			   LogId,
			   LogMessage,
			   LogSize,
			   LogCreateDate,
			   JobExecuteDate,
			   StepDuration 
		FROM ##Temp_AgentJob tab1
		WHERE NOT EXISTS (SELECT * FROM OPENQUERY([' + @MasterServer + '], ''SELECT * FROM DrasInternal.dbo.AgentJob'') ajs 
						WHERE tab1.ServerName = ajs.ServerName
						AND tab1.JobName = ajs.JobName AND tab1.StepNumber = ajs.StepNumber
						AND tab1.JobExecuteDate = ajs.StepExecutionDate)
		ORDER BY tab1.JobName, tab1.StepNumber

		DELETE FROM OPENQUERY([' + @MasterServer + '], ''SELECT * FROM DrasInternal.dbo.AgentJob 
														WHERE StepExecutionDate < DATEADD(MONTH, -6, GETDATE()) '')'
		
	END

	EXECUTE (@SQL)

END

/*

EXEC sp_GatherAgentJobInfo @MasterServer = 'DRASSQL2022'

*/