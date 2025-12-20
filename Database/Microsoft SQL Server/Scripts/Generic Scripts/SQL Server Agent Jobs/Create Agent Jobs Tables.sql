USE DrasInternal

DECLARE @SQL NVARCHAR(MAX)

IF OBJECT_ID('dbo.AgentJobEmailTracker', 'U') IS NOT NULL
BEGIN
	DROP TABLE dbo.AgentJobEmailTracker
END

CREATE TABLE dbo.AgentJobEmailTracker (JobName NVARCHAR(100), 
									   JobExecutionDate DATETIME, 
									   SentEmail BIT, EmailDate DATETIME,
									   LastModByUserId NVARCHAR(40) DEFAULT SUSER_SNAME(),
									   LastModDateTime DATETIME DEFAULT GETDATE()
									   )
GO
IF OBJECT_ID('tu_AgentJobEmailTracker', 'TR') IS NOT NULL
BEGIN
	DROP TRIGGER [tu_AgentJobEmailTracker]
END
GO


CREATE TRIGGER [dbo].[tu_AgentJobEmailTracker] ON [dbo].[AgentJobEmailTracker] FOR UPDATE AS 
IF EXISTS(SELECT * FROM DELETED)
BEGIN
	UPDATE dbo.AgentJobEmailTracker
	SET LastModByUserId = ORIGINAL_LOGIN(), LastModDateTime = GETDATE() 
	FROM dbo.AgentJobEmailTracker as t
	JOIN DELETED as d ON t.JobName = d.JobName;
END
GO


IF OBJECT_ID ('dbo.AgentJob') IS NOT NULL
BEGIN
	DROP TABLE dbo.AgentJob
END

CREATE TABLE dbo.AgentJob (Id INT IDENTITY (1,1),
						   JobId UNIQUEIDENTIFIER,
						   JobName VARCHAR(100),
						   ServerName VARCHAR(100),
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
						   StepDuration INT,
						   LastModByUserId NVARCHAR(40) DEFAULT SUSER_SNAME(),
						   LastModDateTime DATETIME DEFAULT GETDATE(),
						   CONSTRAINT UQ_AgentJob UNIQUE (JobId, ServerName, JobInstanceId),
						   CONSTRAINT PK_AgentJob PRIMARY KEY (Id)
						   )
GO

IF OBJECT_ID('tu_AgentJob', 'TR') IS NOT NULL
BEGIN
	DROP TRIGGER [tu_AgentJob]
END
GO

CREATE TRIGGER [dbo].[tu_AgentJob] ON [dbo].[AgentJob] FOR UPDATE AS 
IF EXISTS(SELECT * FROM DELETED)
BEGIN
	UPDATE dbo.AgentJob
	SET LastModByUserId = ORIGINAL_LOGIN(), LastModDateTime = GETDATE() 
	FROM dbo.AgentJob as t
	JOIN DELETED as d ON t.Id = d.Id;
END


IF OBJECT_ID ('dbo.AgentJobsDetailProcedure', 'U') IS NOT NULL
BEGIN
	DROP TABLE dbo.AgentJobsDetailProcedure
END

CREATE TABLE dbo.AgentJobsDetailProcedure (JobName NVARCHAR(100), ProcedureName NVARCHAR(100), ReferenceTable NVARCHAR(100))

INSERT INTO AgentJobsDetailProcedure 
VALUES ('SQL Server Database Backup', 'sp_ReportFailedBackups', 'DatabaseBackupInfo'),
('SQL Server Database Backup (Local)', 'sp_ReportFailedBackups', 'DatabaseBackupInfo'),
('Backup Restore Testing', 'sp_ReportFailedRestore', 'DatabaseBackupInfo'),
('Backup Restore Testing (Local)', 'sp_ReportFailedRestore', 'DatabaseBackupInfo')

IF OBJECT_ID('dbo.DatabaseBackupInfo', 'U') IS NOT NULL
BEGIN
	DROP TABLE dbo.DatabaseBackupInfo;
END
	
CREATE TABLE dbo.DatabaseBackupInfo (Id INT IDENTITY (1,1),
								     JobId UNIQUEIDENTIFIER,
								     ServerName NVARCHAR(100) NOT NULL,
								     DatabaseName NVARCHAR(100) NOT NULL,
								     FilePosition INT,
								     LastBackupType NVARCHAR(50),
								     FileName NVARCHAR(500),
								     RestoreStatus VARCHAR(8),
								     RestoreTestDate DATETIME,
								     FailedRstrFilePosition INT,
								     DaysSinceLastBackup INT,
								     LastBackupStartDate DATETIME,
								     LastBackupFinishDate DATETIME,
								     LastBackupMessage VARCHAR(4000),
								     LastModByUserId NVARCHAR(40) DEFAULT SUSER_SNAME(),
								     LastModDateTime DATETIME DEFAULT GETDATE(),
								     CONSTRAINT PK_DatabaseBackupInfo PRIMARY KEY (Id),
								     CONSTRAINT UQ_DatabaseBackupInfo UNIQUE (JobId, ServerName, DatabaseName)
								  )
GO

IF OBJECT_ID('tu_DatabaseBackupInfo', 'TR') IS NOT NULL
BEGIN
	DROP TRIGGER tu_DatabaseBackupInfo
END
GO

CREATE TRIGGER [dbo].[tu_DatabaseBackupInfo] ON [dbo].[DatabaseBackupInfo] FOR UPDATE AS 
IF EXISTS(SELECT * FROM DELETED)
BEGIN
	UPDATE dbo.DatabaseBackupInfo
	SET LastModByUserId = ORIGINAL_LOGIN(), LastModDateTime = GETDATE() 
	FROM dbo.DatabaseBackupInfo as t, DELETED as d
	WHERE t.Id=d.Id;
END
GO

