/*
This script performs a COPY_ONLY database backup for all databases listed in @DBList variable. databases in @DBList should be seperated 
by a NEW LINE

***BEFORE RUNNING SCRIPT***

1) SET the varaibles specified below

*/

USE master

DECLARE @SQL NVARCHAR(MAX)
DECLARE @List NVARCHAR(100)
DECLARE @BULocation NVARCHAR(100) 
DECLARE @Tag NVARCHAR(100) 
DECLARE @DBName NVARCHAR(100) 
DECLARE @StartIndex INT 
DECLARE @EndIndex INT
DECLARE @BackupSetName NVARCHAR(100)
DECLARE @BackupDescription NVARCHAR(255)
DECLARE @DeviceName NVARCHAR(MAX) 
DECLARE @TakeOffline VARCHAR(100)
DECLARE @DBList NVARCHAR(MAX)
DECLARE @DBList1 NVARCHAR(MAX)
DECLARE @DBList2 NVARCHAR(MAX)
DECLARE @ReadOnly NVARCHAR(1)
-- List of databases to be backed up
DECLARE @Reason NVARCHAR(50)
DECLARE @DropDB NVARCHAR(1)
DECLARE @Void TABLE (Output VARCHAR(MAX))

--************************************* SET THE FOLLOWING VARAIBLEs BEFORE RUNNING SCRIPT **************************************
-- Reason for backup
--SET @Reason = 'Archived'
SET @Reason = 'DBRestore'
--SET @Reason = 'After_Upgrade'
--SET @Reason = 'ClientDelivery'
--SET @Reason = 'B4_Upgrade_Redo'

-- Backups will be created in this directory
SET @BULocation = '\\dras-dbbkp02\P_DB_Backups_Nightly\Temporary Backups\'

-- Drop Database After Backup
SET @DropDB = 'N'

-- Take database offline AFTER backup
SET @TakeOffline = 'N'

-- Make Read Only
SET @ReadOnly = 'N'

IF OBJECT_ID('tempdb..#BackupDBList') IS NOT NULL
BEGIN
	DROP TABLE #BackupDBList
END

CREATE TABLE #BackupDBList (name VARCHAR(100))

----- OPTION 1) A SQL Query OPTION (returns NULL if LIKE '' is used)
INSERT INTO #BackupDBList
SELECT name
FROM sys.databases 
WHERE database_id > 4 
AND name LIKE ''

-------- OPTION 2) A list of databases seperated by a new line. IF OPTION 1) is set to LIKE '', then this is used
-- List of databases to be backed up
SET @DBList2 = ''

-- Give a description of the purpose of the backup. Can be left as null
SET @BackupDescription = NULL

--***********************************************************************************************************************

-------------------------- Configure xp_cmdshell if not already configured -------------------

-- Show advanced settings 
EXEC sp_configure 'show advanced options', '1'
RECONFIGURE

IF NOT EXISTS (SELECT * FROM sys.configurations WHERE name = 'xp_cmdshell' AND value = 1)
BEGIN
	EXEC sp_configure 'xp_cmdshell', '1' 
	RECONFIGURE
END 
-- hides advanced settings for security reasons
EXEC sp_configure 'show advanced options', 0;
RECONFIGURE;

IF @Reason = 'Archived'
BEGIN 
	SET @DropDB = 'Y'
END

-- Preset location for specifc instances
IF @Reason LIKE '%B4%Upgrade%' OR @Reason LIKE '%Before%Upgrade%' AND (SELECT DEFAULT_DOMAIN()[DomainName]) = 'EDDYFINDT'
BEGIN
	SET @BULocation = '\\dras-dbbkp02\P_DB_Backups_Weekly\Temp\Upgrade\Before Upgrade\' + @@SERVERNAME + '\'
END
ELSE IF @Reason LIKE '%After%Upgrade%' AND (SELECT DEFAULT_DOMAIN()[DomainName]) = 'EDDYFINDT'
BEGIN
	SET @BULocation = '\\dras-dbbkp02\P_DB_Backups_Weekly\Temp\Upgrade\After Upgrade\' + @@SERVERNAME + '\'
END
ELSE IF @Reason LIKE '%ClientDBRestore%' AND (SELECT DEFAULT_DOMAIN()[DomainName]) = 'EDDYFINDT'
BEGIN
	SET @BULocation = '\\dras-dbbkp02\P_DB_Backups_Nightly\Temporary Backups\Before Client DB Restore\'
END
ELSE IF (@Reason = '%ClientDelivery%')
BEGIN
	SET @BULocation = '\\dras-dbbkp02\P_DB_Backups_Nightly\Temporary Backups\Deliver To Client\'
END


IF @@SERVERNAME = 'CTSQL01'
BEGIN
	SET @BULocation = 'B:\Database_Backups\Temporary Backups\'
END

IF @@SERVERNAME = 'PAA-SQL01'
BEGIN
	SET @BULocation = 'E:\Backups\Temporary\'
END

-- Create directory if it does not exists
SET @SQL = 'EXEC master..xp_cmdshell ''IF NOT EXIST "' + @BULocation + '" mkdir  "' + @BULocation + '"'''

IF OBJECT_ID('tempdb..#ReportTable') IS NULL
BEGIN
	CREATE TABLE #ReportTable (DatabaseName VARCHAR(100), FileLocation VARCHAR(1000), Details VARCHAR(MAX), CompletionTime DATETIME DEFAULT GETDATE())
END

INSERT INTO @Void
EXECUTE (@SQL)

-- Name of backupset
SET @BackupSetName = 'Copy-Only Backup for ' + @Reason

--Backup description 
IF @BackupDescription IS NULL OR @BackupDescription = ''
BEGIN
	SET @BackupDescription = 'Copy-Only Full backup from the ' + @@SERVERNAME + ' Server' + ' ' + CAST(GETDATE() AS NVARCHAR) 
END

-- Tag that will be added to the end of each backup file
IF (@Reason LIKE '%Archive%')
BEGIN
	SET @Tag = '_' + @Reason + 'd_' + FORMAT (GETDATE(), 'MMM_dd_yyyy')  
	SET @BULocation = '\\dras-dbbkp02\P_DB_Backups_Monthly\Archives\' + @@SERVERNAME + '\'

	SET @SQL = 'EXEC master..xp_cmdshell ''IF NOT EXIST "' + @BULocation + '" mkdir  "' + @BULocation + '"'''

	INSERT INTO @Void
	EXECUTE (@SQL)
END
ELSE IF (@Reason LIKE 'Upgrade%' OR @Reason LIKE '%ClientDBRestore%' OR @Reason LIKE '%Script%Run%' OR @Reason LIKE '%Cleanup%')
BEGIN
	SET @Tag = '_B4_' + @Reason + '_' + FORMAT (GETDATE(), 'MMM_dd_yyyy')  
END
ELSE
BEGIN
	SET @Tag = '_' + @Reason + '_' + FORMAT (GETDATE(), 'MMM_dd_yyyy')
END

IF CHARINDEX('_', @Reason) <> 1
BEGIN
	SET @Reason = '_' + @Reason
END

SET @Reason = @Reason + FORMAT(GETDATE(), '_MMM_dd_yyyy')

--DECLARE @FailedList TABLE (DBName NVARCHAR(100), Reason NVARCHAR(MAX))
--DECLARE @SuccessList TABLE (DBName NVARCHAR(100))

SET @DBList2 = REPLACE(@DBList2, CHAR(32), '')
SET @DBList2 = REPLACE(@DBList2, CHAR(13), ''',')
SET @DBList2 = REPLACE(@DBList2, CHAR(10), '''')
SET @DBList2 = REPLACE(@DBList2, CHAR(9), '')

SET @DBList2 = '''' + @DBList2 + ''''

SET @SQL = 'INSERT INTO #BackupDBList
SELECT name FROM sys.databases WHERE name IN (' + @DBList2 + ')'

EXECUTE (@SQL)

DECLARE DBList_cursor CURSOR FOR 
SELECT * FROM #BackupDBList

OPEN DBList_cursor
FETCH NEXT FROM DBList_cursor INTO @DBName

WHILE @@FETCH_STATUS = 0
BEGIN

	SET @DeviceName = @BULocation + @DBName + @Reason + '.bak'

	--Perform Backup if the database exists
	BEGIN TRY
		SET @SQL = 'BACKUP DATABASE ' + @DBName + '
		TO DISK = ''' + @DeviceName + '''
		WITH COPY_ONLY, 
		FORMAT, 
		CHECKSUM,
		COMPRESSION,
		NAME = ''' + @BackupSetName + ''',
		DESCRIPTION = ''' + @BackupDescription + ''';'

		-- Set Database to online mode if it is offline. Then set it back offline after performing backup
		IF EXISTS (SELECT * FROM sys.databases WHERE name = @DBName AND state_desc = 'OFFLINE')
		BEGIN
			SET @SQL = 'ALTER DATABASE ' + @DBName + ' SET ONLINE' + CHAR(10) + @SQL 
				+ CHAR(10) + 'ALTER DATABASE ' + @DBName + ' SET OFFLINE' 
		END

		BEGIN TRY
			EXECUTE sp_executesql @SQL
		END TRY
		BEGIN CATCH
			INSERT INTO #ReportTable (DatabaseName, Details) VALUES (@DBName, ERROR_MESSAGE());
			THROW
		END CATCH

		PRINT CHAR(10) + 'COMPLETED BACKUP OF ' + @DBName + ' TO: ' + @DeviceName + CHAR(13)

		MERGE #ReportTable tgt
		USING (SELECT @DBName, @DeviceName, 'The database backup was successful') AS src (DatabaseName, FileLocation, Details)
		ON (tgt.DatabaseName = src.DatabaseName)
		WHEN MATCHED
			THEN UPDATE
			SET Details = src.Details,
				FileLocation = src.FileLocation
		WHEN NOT MATCHED
			THEN
			INSERT (DatabaseName, FileLocation, Details)
			VALUES (src.DatabaseName, src.FileLocation, src.Details);
		-- Take the Database OFFLINE
		IF @TakeOffline = 'Y'
		BEGIN
			SET @SQL = 'ALTER DATABASE ' + @DBName + ' SET OFFLINE WITH ROLLBACK IMMEDIATE'
			EXECUTE (@SQL)
		END

		-- Set the database to READ-ONLY
		IF @ReadOnly = 'Y'
		BEGIN
			SET @SQL = 'ALTER DATABASE ' + QUOTENAME(@DBName) + ' SET READ_ONLY WITH NO_WAIT'
			EXECUTE (@SQL)
		END
	END TRY
	BEGIN CATCH
		PRINT 'The database backup failed for ' + @DBName + CHAR(10)

		MERGE #ReportTable tgt
		USING (SELECT @DBName, @DeviceName, ERROR_MESSAGE()) AS src (DatabaseName, FileLocation, Details)
		ON (tgt.DatabaseName = src.DatabaseName)
		WHEN MATCHED
			THEN 
			UPDATE
			SET Details = src.Details
		WHEN NOT MATCHED
			THEN
			INSERT (DatabaseName, Details)
			VALUES (src.DatabaseName, src.Details);
	END CATCH
	
	FETCH NEXT FROM DBList_cursor INTO @DBName
END

CLOSE DBList_cursor
DEALLOCATE DBList_cursor

IF @DropDB = 'Y' 
BEGIN
	DECLARE DropDB_Cursor CURSOR FOR
	SELECT name
	FROM #BackupDBList
	WHERE name IN (SELECT name FROM sys.databases d
	JOIN #ReportTable rt ON rt.DatabaseName = d.name AND Details LIKE '%Success%')

	OPEN DropDB_Cursor
	FETCH NEXT FROM DropDB_Cursor INTO @DBname

	WHILE @@FETCH_STATUS = 0
	BEGIN
		
		SET @SQL = 'DROP DATABASE ' + @DBName

		BEGIN TRY
			EXECUTE (@SQL)
			PRINT 'The ' + @DBName + ' has been DROPPED from the Server' + CHAR(10)
			UPDATE #ReportTable
			SET Details = 'The database was backed up and dropped from the server'
		END TRY
		BEGIN CATCH
			UPDATE #ReportTable  
			SET Details = ERROR_MESSAGE()
			WHERE DatabaseName = @DBName;
		END CATCH

		FETCH NEXT FROM DropDB_Cursor INTO @DBname
	END

	CLOSE DropDB_Cursor
	DEALLOCATE DropDB_Cursor
END;

SELECT * FROM #ReportTable WHERE DatabaseName IN (SELECT name FROM #BackupDBList)