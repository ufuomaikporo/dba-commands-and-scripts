/*
This script performs a COPY_ONLY database backup for all databases listed in @DBList variable. databases in @DBList should be seperated 
by a NEW LINE

***BEFORE RUNNING SCRIPT***

1) SET the varaibles specified below

*/

USE master

DECLARE @sql NVARCHAR(MAX)
DECLARE @List NVARCHAR(100)
DECLARE @BULocation NVARCHAR(100) 
DECLARE @Tag NVARCHAR(100) 
DECLARE @DBName NVARCHAR(100) 
DECLARE @StartIndex INT 
DECLARE @EndIndex INT
DECLARE @BackupSetName NVARCHAR(100)
DECLARE @BackupDescription NVARCHAR(255)
DECLARE @TakeOffline VARCHAR(100)
DECLARE @DBList2 NVARCHAR(MAX)
DECLARE @ReadOnly NVARCHAR(1)
-- List of databases to be backed up
DECLARE @DBList NVARCHAR(MAX)
DECLARE @Reason NVARCHAR(50)

--************************************* SET THE FOLLOWING VARAIBLEs BEFORE RUNNING SCRIPT **************************************
-- Reason for backup
--SET @Reason = 'Archive'
SET @Reason = 'RestoreWClientDB'
--SET @Reason = 'Upgrade'
--SET @Reason = 'ClientDelivery'
--SET @Reason = 'B4_6_5_0_Upgrade'

-- Backups will be created in this directory
SET @BULocation = '\\dras-dbbkp02\P_DB_Backups_Nightly\Temporary Backups\'

-- Take database offline AFTER backup
SET @TakeOffline = 'N'

-- Make Read Only
SET @ReadOnly = 'N'

------- OPTION 1) A SQL Query OPTION (returns NULL if LIKE '' is used)
SELECT @DBList = COALESCE(@DBList + CHAR(10), '') + name 
FROM sys.databases 
WHERE database_id > 4 
AND name LIKE ''

-------- OPTION 2) A list of databases seperated by a new line. IF OPTION 1) is set to LIKE '', then this is used
-- List of databases to be backed up
SET @DBList2 = 'IPL_Source_Risk_Data'

-- Give a description of the purpose of the backup. Can be left as null
SET @BackupDescription = NULL
--***********************************************************************************************************************

IF @DBList IS NULL
BEGIN
	SET @DBList = @DBList2
END

IF @Reason LIKE '%Upgrade' AND (SELECT DEFAULT_DOMAIN()[DomainName]) = 'EDDYFINDT'
BEGIN
	SET @BULocation = '\\dras-dbbkp02\P_DB_Backups_Nightly\Temp\Before Upgrade\' + @@SERVERNAME + '\'
END

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
END
ELSE IF (@Reason LIKE 'Upgrade%' OR @Reason LIKE '%ReplaceWClient%' OR @Reason LIKE '%Script%Run%' OR @Reason LIKE '%Cleanup%')
BEGIN
	SET @Tag = '_B4_' + @Reason + '_' + FORMAT (GETDATE(), 'MMM_dd_yyyy')  
END
ELSE
BEGIN
	SET @Tag = '_' + @Reason + '_' + FORMAT (GETDATE(), 'MMM_dd_yyyy')
END

DECLARE @FailedList TABLE (DBName NVARCHAR(100))
DECLARE @SuccessList TABLE (DBName NVARCHAR(100))

SET @StartIndex =1
SET @EndIndex = 1

SET @DBList = REPLACE(@DBList, ' ', '');
SET @DBList = REPLACE(@DBList, CHAR(10), ' ');
SET @DBList = REPLACE(@DBList, CHAR(13), '');
SET @DBList = REPLACE(@DBList, CHAR(9), '');
SET @DBList = REPLACE(@DBList, ' ', ''', ''');
SET @DBList = REPLACE(@DBList, ''''', ', '');

SET @DBList = '''' + @DBList + '''';

SELECT @DBList =  REPLACE(REPLACE(@DBLIST, '''', ''), ',', '')

WHILE @EndIndex < LEN(@DBList) 
BEGIN
	SET @EndIndex = CHARINDEX(' ', @DBList, @StartIndex + 1) 

	-- Gets index for end of name for the last database in @DBList 
	IF @EndIndex = 0
	BEGIN
		SET @EndIndex = LEN(@DBList) + 1
	END
	
	--Database to be backed up
	SET @DBName = (SUBSTRING(@DBList, @StartIndex, @EndIndex - @StartIndex))
	
	--Set backup device name
	DECLARE @DeviceName NVARCHAR(MAX) = @BULocation + @DBName + @Tag + '.bak'

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

		
		EXECUTE sp_executesql @sql
		PRINT ''
		PRINT 'COMPLETED BACKUP OF ' + @DBName + ' TO: ' + @DeviceName + CHAR(13)

		INSERT INTO @SuccessList
		SELECT @DBName

		IF @TakeOffline = 'Y'
		BEGIN
			SET @SQL = 'ALTER DATABASE ' + @DBName + ' SET OFFLINE WITH ROLLBACK IMMEDIATE'
			EXECUTE (@SQL)
		END

		IF @ReadOnly = 'Y'
		BEGIN
			SET @SQL = 'ALTER DATABASE ' + QUOTENAME(@DBName) + ' SET READ_ONLY WITH NO_WAIT'
			EXECUTE (@SQL)
		END
	END
	ELSE
	BEGIN
		PRINT CHAR(13) + 'THE ' + @DBName + ' DATABASE DOES NOT EXIST ON THIS SERVER ' + CHAR(13)

		INSERT INTO @FailedList
		SELECT @DBName
	END
	
	SET @StartIndex = @EndIndex + 1
END

IF EXISTS (SELECT 1 FROM @SuccessList)
BEGIN
	PRINT CHAR(10) + 'Performed SUCCESSFUL backups for the following databases' + CHAR(10)

	SELECT DBName AS Successfull_Backups
	FROM @SuccessList;
END;

IF EXISTS (SELECT 1 FROM @FailedList) 
BEGIN
	PRINT CHAR(10) + 'FAILED to backup the following databases' + CHAR(10);

	SELECT DBName AS Failed_To_Backup
	FROM @FailedList;
END;

