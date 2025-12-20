USE DrasInternal
/*

The following table needs to be created on the master Agent server

IF OBJECT_ID ('AgentJobStatus') IS NOT NULL
BEGIN
	DROP TABLE AgentJobStatus
END

CREATE TABLE AgentJobStatus (ServerName VARCHAR(100),
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

IF OBJECT_ID('dbo.sp_UpdateAgentJobStatusTable') IS NOT NULL
BEGIN
	DROP PROCEDURE [dbo].[sp_UpdateAgentJobStatusTable]
END
GO

CREATE PROCEDURE [dbo].[sp_UpdateAgentJobStatusTable] 
AS
BEGIN
	INSERT OPENQUERY ([DRASSQL2022], 'SELECT * FROM DrasInternal.dbo.AgentJobStatus') 
	SELECT	@@SERVERNAME,
			JobName = J.name,
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
			StepDuration = CAST(T.run_duration/10000 AS VARCHAR) + 'hr:' + CAST((T.run_duration % 10000)/100 AS VARCHAR) 
				+ 'min:' + CAST((T.run_duration % 100) AS VARCHAR) + 'sec'
	FROM msdb.dbo.sysjobhistory T
	JOIN  msdb.dbo.sysjobs J
	ON J.job_id = T.job_id  
	JOIN msdb.dbo.sysjobsteps js
	ON T.run_date = js.last_run_date
	AND T.run_time = js.last_run_time
	AND T.step_id = js.step_id
	JOIN (SELECT  * FROM msdb.dbo.sysjobstepslogs ) AS jsl
	ON js.step_uid = jsl.step_uid
	WHERE NOT EXISTS (SELECT * FROM OPENQUERY ([DRASSQL2022], 'SELECT * FROM DrasInternal.dbo.AgentJobStatus') rmt
	WHERE rmt.ServerName = @@SERVERNAME AND rmt.JobName = J.name AND rmt.JobInstanceId = T.instance_id
	)
	ORDER BY T.instance_id
END