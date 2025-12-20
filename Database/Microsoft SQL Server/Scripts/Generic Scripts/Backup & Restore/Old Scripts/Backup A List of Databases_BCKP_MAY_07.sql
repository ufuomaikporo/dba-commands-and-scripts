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
--SET @Reason = 'Archive'
--SET @Reason = 'ClientDBRestore'
--SET @Reason = 'Upgrade'
--SET @Reason = 'ClientDelivery'
SET @Reason = 'HelysDBBeforeCleanup'

-- Backups will be created in this directory
SET @BULocation = '\\dras-dbbkp02\P_DB_Backups_Nightly\Temporary Backups\'

-- Drop Database After Backup
SET @DropDB = 'N'

-- Take database offline AFTER backup
SET @TakeOffline = 'N'

-- Make Read Only
SET @ReadOnly = 'N'

SET @DBList1 = NULL
----- OPTION 1) A SQL Query OPTION (returns NULL if LIKE '' is used)
SELECT @DBList1 = COALESCE(@DBList1 + CHAR(10), '') + name 
FROM sys.databases 
WHERE database_id > 4 
AND name LIKE ''

-------- OPTION 2) A list of databases seperated by a new line. IF OPTION 1) is set to LIKE '', then this is used
-- List of databases to be backed up
SET @DBList2 = 'ETP_IRASv6_LINK
'

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

IF @Reason = 'Archive'
BEGIN 
	SET @DropDB = 'Y'
END

-- Preset location for specifc instances
IF @Reason LIKE '%B4%Upgrade%' OR @Reason LIKE '%Before%Upgrade%' AND (SELECT DEFAULT_DOMAIN()[DomainName]) = 'EDDYFINDT'
BEGIN
	SET @BULocation = '\\dras-dbbkp02\P_DB_Backups_Weekly\Temp\Before Upgrade\' + @@SERVERNAME + '\'
END
ELSE IF @Reason LIKE '%After%Upgrade%' AND (SELECT DEFAULT_DOMAIN()[DomainName]) = 'EDDYFINDT'
BEGIN
	SET @BULocation = '\\dras-dbbkp02\P_DB_Backups_Weekly\Temp\After Upgrade\' + @@SERVERNAME + '\'
END
ELSE IF @Reason LIKE 'ClientDBRestore' AND (SELECT DEFAULT_DOMAIN()[DomainName]) = 'EDDYFINDT'
BEGIN
	SET @BULocation = '\\dras-dbbkp02\P_DB_Backups_Nightly\Temporary Backups\Before Client DB Restore\'
END
ELSE IF (@Reason = 'ClientDelivery')
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


DECLARE @FailedList TABLE (DBName NVARCHAR(100), Reason NVARCHAR(MAX))
DECLARE @SuccessList TABLE (DBName NVARCHAR(100))

SET @StartIndex =1
SET @EndIndex = 1

SET @DBList = COALESCE(@DBList1, '') + CHAR(10) + @DBList2

print @DBList
return

WHILE @EndIndex < LEN(@DBList) 
BEGIN
	SET @EndIndex = CHARINDEX(CHAR(10), @DBList, @StartIndex + 1) 

	-- Gets index for end of name for the last database in @DBList 
	IF @EndIndex = 0
	BEGIN
		SET @EndIndex = LEN(@DBList) + 1
	END
	
	--Database to be backed up
	SET @DBName = (SUBSTRING(@DBList, @StartIndex, @EndIndex - @StartIndex))
	
	--Set backup device name
	SET @DeviceName = @BULocation + @DBName + @Tag + '.bak'

	--Perform Backup if the database exists
	IF EXISTS (SELECT 1 FROM sys.databases WHERE name = @DBName)
	BEGIN
		SET @sql = 'BACKUP DATABASE ' + @DBName + '
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
			INSERT INTO @FailedList VALUES (@DBName, ERROR_MESSAGE());
			THROW
		END CATCH

		PRINT ''
		PRINT 'COMPLETED BACKUP OF ' + @DBName + ' TO: ' + @DeviceName + CHAR(13)

		INSERT INTO @SuccessList
		SELECT @DBName

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
	END
	ELSE
	BEGIN
		SET @SQL = 'The ' + @DBName + ' database does not exist on this server ' + CHAR(13)
		INSERT INTO @FailedList VALUES(@DBname, @SQL)
	END
	
	SET @StartIndex = @EndIndex + 1
END

IF @DropDB = 'Y' 
BEGIN
	DECLARE DropDB_Cursor CURSOR FOR
	SELECT DBName 
	FROM @SuccessList
	WHERE DBName IN (SELECT name FROM sys.databases)

	OPEN DropDB_Cursor
	FETCH NEXT FROM DropDB_Cursor INTO @DBname

	WHILE @@FETCH_STATUS = 0
	BEGIN
		
		SET @SQL = 'DROP DATABASE ' + @DBName

		BEGIN TRY
			EXECUTE (@SQL)
		END TRY
		BEGIN CATCH
			THROW
			PRINT CHAR(10)
		END CATCH

		PRINT 'The ' + @DBName + ' has been DROPPED from the Server' + CHAR(10)

		FETCH NEXT FROM DropDB_Cursor INTO @DBname
	END

	CLOSE DropDB_Cursor
	DEALLOCATE DropDB_Cursor
END;

IF EXISTS (SELECT 1 FROM @FailedList) 
BEGIN
	PRINT CHAR(10) + 'FAILED to backup the following databases' + CHAR(10);

	SELECT DBName AS Failed_To_Backup, Reason 
	FROM @FailedList;
END;