use DrasInternal

SELECT * FROM AgentJobEmailTracker;

WITH CTE AS
(SELECT REPLACE(aj.JobName, '(local)', '') AS JobName, 
	   CAST(FORMAT(StepExecutionDate, 'yyyy-MM-dd HH:mm:00') AS DATETIME) JobExecutionDate, 
	   ServerName,
	   SentEmail, 
	   CAST(StepDuration/10000 AS VARCHAR) + 'hr:' + CAST((StepDuration % 10000)/100 AS VARCHAR) 
		+ 'min:' + CAST((StepDuration % 100) AS VARCHAR) + 'sec' AS JobDuration,
		ROW_NUMBER() OVER (PARTITION BY aj.JobName, ServerName ORDER BY StepExecutionDate DESC) rownum
FROM AgentJob aj
JOIN AgentJobEmailTracker jt
ON jt.JobName = REPLACE(aj.JobName, '(Local)', '')
AND FORMAT(aj.StepExecutionDate, 'yyyy-MM-dd HH:mm:ss') >= FORMAT(jt.JobExecutionDate, 'yyyy-MM-dd HH:mm:ss')
WHERE StepName = '(Job outcome)'
)
SELECT JobName, 
        CAST(FORMAT(JobExecutionDate, 'yyyy-MM-dd HH:mm:00') AS DATETIME) JobExecutionDate, 
        COUNT(*) ServerCount, 
        SentEmail
FROM CTE 
WHERE rownum = 1
GROUP BY JobName, FORMAT(JobExecutionDate, 'yyyy-MM-dd HH:mm:00'), SentEmail;

/*
select * from AgentJOb where stepname like '%outcome%' order by LastModDatetime desc
select * from DatabaseBackupInfo where Servername = 'DRASSQL2017' ORDER BY LastModDateTime desc
sp_helptext N'tu_AgentJob'

Update AgentJobEmailTracker set SentEmail = 0 where jobname = 'SQL Server Database Backup'

EXECUTE ('SELECT SUSER_SNAME(), ORIGINAL_LOGIN(), USER_NAME(), SUSER_NAME()

') AT DRASSQL2017

SELECT SUSER_SNAME(), ORIGINAL_LOGIN(), USER_NAME(), SUSER_NAME()
select ORIGINAL_LOGIN()
*/

 

WITH CTE AS
(SELECT REPLACE(aj.JobName, '(local)', '') AS JobName, 
	   CAST(FORMAT(StepExecutionDate, 'yyyy-MM-dd HH:mm:00') AS DATETIME) JobExecutionDate, 
	   ServerName,
	   CAST(StepDuration/10000 AS VARCHAR) + 'hr:' + CAST((StepDuration % 10000)/100 AS VARCHAR) 
		+ 'min:' + CAST((StepDuration % 100) AS VARCHAR) + 'sec' AS JobDuration,
		ROW_NUMBER() OVER (PARTITION BY aj.JobName, ServerName ORDER BY StepExecutionDate DESC) rownum
FROM AgentJob aj
WHERE StepName = '(Job outcome)'
)
SELECT * 
FROM CTE 
WHERE rownum = 1 AND JobName = 'SQL Server Database Backup' order by JobExecutionDate desc, servername

return
SELECT REPLACE(aj.JobName, '(local)', '') AS JobName, 
	   CAST(FORMAT(StepExecutionDate, 'yyyy-MM-dd HH:mm:00') AS DATETIME) JobExecutionDate, 
	   ServerName,
	   SentEmail, 
	   CAST(StepDuration/10000 AS VARCHAR) + 'hr:' + CAST((StepDuration % 10000)/100 AS VARCHAR) 
		+ 'min:' + CAST((StepDuration % 100) AS VARCHAR) + 'sec' AS JobDuration,
		ROW_NUMBER() OVER (PARTITION BY aj.JobName, ServerName ORDER BY StepExecutionDate DESC) rownum
FROM AgentJob aj
JOIN AgentJobEmailTracker jt
ON jt.JobName = REPLACE(aj.JobName, '(Local)', '')
AND FORMAT(aj.StepExecutionDate, 'yyyy-MM-dd HH:00:00') = FORMAT(jt.JobExecutionDate, 'yyyy-MM-dd HH:00:00')
WHERE StepName = '(Job outcome)' and jt.JobName = 'SQL Server Database Backup'