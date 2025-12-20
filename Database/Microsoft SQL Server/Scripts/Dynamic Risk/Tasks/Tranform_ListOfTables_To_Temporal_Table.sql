/* This script is not client-specific. The INSERT INTO statements for the @TableList table variable can be modified as needed. This script converts non-temporal (regular permanent tables) into temporal tables by adding the ValidFrom and ValidTo period columns and creating a history table to track changes to a table's data
*/
-- Variable Declaration
DECLARE @TableName VARCHAR(200);
DECLARE @ModifyTable NVARCHAR(MAX);
DECLARE @SQL NVARCHAR(MAX)
DECLARE @HistoryTableName NVARCHAR(100)

---- Create table to store list of tables that need to be turned into a temporal table
--DECLARE @TableList TABLE (id INT IDENTITY(1,1), tableName VARCHAR(200)) 

---- Add tables that need to be converted to temporal tables
--BEGIN TRANSACTION
--	INSERT INTO @TableList VALUES ('dbo.InlineInspectionFeature');
--	INSERT INTO @TableList VALUES ('dbo.InlineInspectionCrackAnomaly');
--	INSERT INTO @TableList VALUES ('dbo.InlineInspectionNonCrsnDfct');
--COMMIT;

USE [DRAS_IRASV5_EXPLORER_DEMO]
-- Create a cursor to loop through the tables in the list
DECLARE TableCursor CURSOR FOR
SELECT SUBSTRING(name, 3, LEN(name)) FROM sys.tables 
WHERE name LIKE 'H[_]%'
				

--SELECT * FROM sys.tables 
--WHERE name LIKE 'H[_]%'
--ORDER BY name

--select * from sys.tables where name like 'history%'

---- Creates a History schema to store history table
--IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'History')
--BEGIN
--	EXECUTE ('CREATE SCHEMA History');
--END

-- Use cursor to loop through and modify tables into temporal table
OPEN TableCursor;
FETCH NEXT FROM TableCursor INTO @TableName

--select * from sys.tables where name like 'history%'

WHILE @@FETCH_STATUS = 0
BEGIN
	--Check if a user table with the name in variable the @TableName exists
	IF EXISTS (SELECT 1 FROM sys.tables WHERE name = @TableName)
	BEGIN
		SET @HistoryTableName = 'History_' + @TableName

		-- Create a temporal table on each table on the user table if the history table name is not already in use
		IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = @HistoryTableName)
		BEGIN
			-- Create DDL to alter each table and add the period start and end date columns
			SET @SQL = 'ALTER TABLE ' + @TableName + ' 
					ADD ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START HIDDEN
							CONSTRAINT DF_'+ @TableName + '_ValidFrom DEFAULT SYSUTCDATETIME(),
						ValidTo DATETIME2 GENERATED ALWAYS AS ROW END HIDDEN
							CONSTRAINT DF_' + @TableName + '_ValidTo DEFAULT CONVERT(DATETIME2,''9999-12-31 23:59:59.9999999''),
						PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo);
				
						ALTER TABLE ' +  @TableName + '
							SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.' + @HistoryTableName + '));'

				EXECUTE sp_executesql @SQL
			
		END -- End of inner IF-statement
	END -- End of outer IF-statement

	--select @TableName
	--select @SQL
	--bReak

	FETCH NEXT FROM TableCursor INTO @TableName
END -- End of While-Loop

DEALLOCATE TableCursor

-----------------------------------------------------Script Tracking--------------------------------------------------------------

---- Create ScriptTracker Table if it does not already exist
--IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.tables WHERE table_name= 'ScriptTracker')
--BEGIN

--	CREATE TABLE ScriptTracker
--	(Id numeric(10) IDENTITY,
--	ScriptName varchar(100),
--	ScriptDetails varchar(255),
--	Reason varchar(255),
--	ClientSpecific varchar(10), --yes, no
--	ScriptedByUser varchar (45),
--	ScriptCreateDate datetime,
--	ScriptDeliveredDate datetime,
--	Version varchar(20),
--	CreatedDate datetime NOT NULL,
--	CreatedUser varchar(45) NOT NULL,
--	LastModByUserId varchar(45) NOT NULL,
--	LastModDateTime datetime NOT NULL,
--	CONSTRAINT PK_ScriptTracker PRIMARY KEY CLUSTERED
--	(
--	Id ASC)
--	);

--	ALTER TABLE dbo.ScriptTracker ADD  DEFAULT (suser_sname()) FOR LastModByUserId;

--	ALTER TABLE dbo.ScriptTracker ADD  DEFAULT (getdate()) FOR LastModDateTime;

--	ALTER TABLE dbo.ScriptTracker ADD  DEFAULT (getdate()) FOR CreatedDate;

--	ALTER TABLE dbo.ScriptTracker ADD  DEFAULT (suser_sname()) FOR CreatedUser;


--END;
--GO

----Create trigger for the ScriptTracker table
--IF EXISTS (SELECT * FROM sys.objects WHERE TYPE = 'TR' AND NAME = 'tu_ScriptTracker')
--	DROP TRIGGER [dbo].[tu_ScriptTracker]
--GO

--CREATE TRIGGER dbo.tu_ScriptTracker ON dbo.ScriptTracker FOR UPDATE AS
--IF EXISTS(SELECT * FROM DELETED)
--	BEGIN   UPDATE dbo.ScriptTracker   
--			SET LastModByUserId = suser_sname(), 
--				LastModDateTime = getdate()    
--			FROM dbo.ScriptTracker as t, DELETED as d    
--			WHERE t.Id=d.Id;
--END
--GO

--ALTER TABLE dbo.ScriptTracker ENABLE TRIGGER tu_ScriptTracker
--GO

---- Add a new entry into ScriptTracker table
--INSERT INTO dbo.ScriptTracker
--(ScriptName,   
-- ScriptDetails,    
-- Reason,    
-- ClientSpecific,    
-- ScriptedByUser,    
-- ScriptCreateDate,    
-- ScriptDeliveredDate,    
-- Version
--)
--SELECT  'Tranform_Tables_To_Temporal_Table.sql', 
--		'Converts regular permanent tables to temporal tables and creates history tables for each table', 
--		'To track changes to table data',
--		'No', 
--		'Ufuoma Ikporo',
--		'November 15, 2022',
--		getdate(), 
--		1
--WHERE NOT EXISTS (SELECT * FROM dbo.ScriptTracker st 
--				  WHERE st.ScriptName = 'Tranform_Tables_To_Temporal_Table.sql' 
--				  AND Version = 1)
--GO
