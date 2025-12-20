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
	DECLARE @TargetServer VARCHAR(100)

	SET @TargetServer = @@SERVERNAME

	IF OBJECT_ID ('tempdb..##Temp_AgentJob', 'U') IS NOT NULL
	BEGIN
		DROP TABLE ##Temp_AgentJob
	END;

	WITH CTE AS 
	(SELECT ROW_NUMBER() OVER (PARTITION BY J.name, T.step_name ORDER BY msdb.dbo.agent_datetime(T.run_date, T.run_time) DESC) row_num,
			j.Job_Id AS JobId,
			JobName = J.name,
			@@SERVERNAME AS ServerName,
			JobInstanceId = T.instance_id,
			StepNumber = T.step_id,
			StepName = T.step_name,
			StepStatus = CASE T.run_status
			WHEN 0 THEN 'Failed'
			WHEN 1 THEN 'Completed'
			WHEN 2 THEN 'Retry'
			WHEN 3 THEN 'Canceled'
			WHEN 4 THEN 'Running' END,
			Message = T.message,
			LogId = jsl.log_id,
			LogMessage = jsl.log,
			LogSize = jsl.log_size,
			LogCreateDate = jsl.date_created,
			StepExecutionDate = msdb.dbo.agent_datetime(T.run_date, T.run_time),
			StepDuration = T.run_duration
	FROM msdb.dbo.sysjobhistory T
	JOIN  msdb.dbo.sysjobs J
	ON J.job_id = T.job_id  
	JOIN msdb.dbo.sysjobsteps js
	ON T.job_id = js.job_id
	JOIN (SELECT * FROM msdb.dbo.sysjobstepslogs ) AS jsl
	ON js.step_uid = jsl.step_uid
	)SELECT JobId,
			ServerName,
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
	INTO ##Temp_AgentJob
	FROM CTE tab1
	WHERE row_num = 1
	AND tab1.JobName NOT LIKE '%Report%Agent%Job%'
	ORDER BY tab1.JobName, tab1.StepNumber

 
	IF (@MasterServer = @@SERVERNAME)
	BEGIN
		SET @SQL = 'MERGE DrasInternal.dbo.AgentJob tgt
					USING (SELECT * FROM ##Temp_AgentJob) AS src
					ON (tgt.JobId = src.JobId AND tgt.JobInstanceId = src.JobInstanceId 
					   AND tgt.ServerName = src.ServerName)
					WHEN MATCHED THEN 
						UPDATE SET StepNumber = src.StepNumber,
								   StepName = src.StepName,
								   StepStatus = src.StepStatus,
								   Message = src.Message,
								   LogId = src.LogId,
								   LogMessage = src.LogMessage,
								   LogSize = src.LogSize,
								   LogCreateDate = src.LogCreateDate,
								   StepExecutionDate = src.StepExecutionDate,
								   StepDuration = src.StepDuration
					WHEN NOT MATCHED THEN
						INSERT (JobId,
								JobName,
								ServerName,
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
						VALUES (JobId,
								JobName,
								ServerName,
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
								StepDuration);
		
		DELETE FROM DrasInternal.dbo.AgentJob 
		WHERE StepExecutionDate < DATEADD(MONTH, -6, GETDATE())
		
		INSERT INTO DrasInternal.dbo.AgentJobEmailTracker (JobName, JobExecutionDate, SentEmail, EmailDate)
		SELECT RTRIM(LTRIM(REPLACE(tmp.JobName, ''(Local)'', ''''))), StepExecutionDate, 0, NULL
		FROM ##Temp_AgentJob tmp WHERE StepName LIKE ''%Job%Outcome%''
		AND NOT EXISTS (SELECT * FROM DrasInternal.dbo.AgentJobEmailTracker tgt
							WHERE RTRIM(LTRIM(REPLACE(tmp.JobName, ''(Local)'', ''''))) = tgt.JobName)
							
		UPDATE DrasInternal.dbo.AgentJobEmailTracker
		SET JobExecutionDate = FORMAT(src.StepExecutionDate, ''yyyy-MM-dd HH:mm:00''),
			SentEmail = 0,
			EmailDate = NULL
		FROM DrasInternal.dbo.AgentJobEmailTracker tgt
		JOIN ##Temp_AgentJob src
		ON RTRIM(LTRIM(REPLACE(src.JobName, ''(Local)'', ''''))) = tgt.JobName
		WHERE FORMAT(tgt.JobExecutionDate, ''yyyy-MM-dd HH:mm:00'') < FORMAT(src.StepExecutionDate, ''yyyy-MM-dd HH:mm:00'')'

	END
	ELSE
	BEGIN

		SET @SQL = 'INSERT INTO ' + QUOTENAME(@MasterServer) + '.DrasInternal.dbo.AgentJob (JobId,
																				 JobName,
																				 ServerName,
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
						SELECT  JobId,
								JobName,
								ServerName,
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
						FROM ##Temp_AgentJob src
						WHERE NOT EXISTS (SELECT * FROM ' + QUOTENAME(@MasterServer) + '.DrasInternal.dbo.AgentJob tgt
										WHERE tgt.JobId = src.JobId AND tgt.JobInstanceId = src.JobInstanceId 
										AND tgt.ServerName = src.ServerName)

				UPDATE ' + QUOTENAME(@MasterServer) + '.DrasInternal.dbo.AgentJob 
				SET StepNumber = src.StepNumber,
				    StepName = src.StepName,
				    StepStatus = src.StepStatus,
				    Message = src.Message,
				    LogId = src.LogId,
				    LogMessage = src.LogMessage,
				    LogSize = src.LogSize,
				    LogCreateDate = src.LogCreateDate,
				    StepExecutionDate = src.StepExecutionDate,
				    StepDuration = src.StepDuration
				FROM ' + QUOTENAME(@MasterServer) + '.DrasInternal.dbo.AgentJob tgt
				JOIN ##Temp_AgentJob src 
				ON tgt.JobId = src.JobId AND tgt.JobInstanceId = src.JobInstanceId 
				AND tgt.ServerName = src.ServerName
				
		DELETE FROM OPENQUERY(' + QUOTENAME(@MasterServer) + ', ''SELECT * FROM DrasInternal.dbo.AgentJob 
														WHERE StepExecutionDate < DATEADD(MONTH, -6, GETDATE()) '')
		
		INSERT INTO ' + QUOTENAME(@MasterServer) + '.DrasInternal.dbo.AgentJobEmailTracker (JobName, JobExecutionDate, SentEmail, EmailDate)
		SELECT RTRIM(LTRIM(REPLACE(tmp.JobName, ''(Local)'', ''''))), StepExecutionDate, 0, NULL
		FROM ##Temp_AgentJob tmp WHERE StepName LIKE ''%Job%Outcome%''
		AND NOT EXISTS (SELECT * FROM ' + QUOTENAME(@MasterServer) + '.DrasInternal.dbo.AgentJobEmailTracker tgt
							WHERE RTRIM(LTRIM(REPLACE(tmp.JobName, ''(Local)'', ''''))) = tgt.JobName)
							
		UPDATE ' + QUOTENAME(@MasterServer) + '.DrasInternal.dbo.AgentJobEmailTracker
		SET JobExecutionDate = FORMAT(src.StepExecutionDate, ''yyyy-MM-dd HH:mm:00''),
			SentEmail = 0,
			EmailDate = NULL
		FROM ' + QUOTENAME(@MasterServer) + '.DrasInternal.dbo.AgentJobEmailTracker tgt
		JOIN ##Temp_AgentJob src
		ON RTRIM(LTRIM(REPLACE(src.JobName, ''(Local)'', ''''))) = tgt.JobName
		WHERE FORMAT(tgt.JobExecutionDate, ''yyyy-MM-dd HH:mm:00'') < FORMAT(src.StepExecutionDate, ''yyyy-MM-dd HH:mm:00'')'

	END

	EXECUTE (@SQL)
	
END

/*

EXEC sp_GatherAgentJobInfo @MasterServer = 'DRASSQL2022'


*/