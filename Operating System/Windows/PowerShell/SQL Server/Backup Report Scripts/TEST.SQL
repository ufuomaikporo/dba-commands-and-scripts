USE master

DECLARE @SQL NVARCHAR(MAX)
DECLARE @NumOfBackups INT 
DECLARE @Counter INT 
DECLARE @Recovery NVARCHAR(10)
DECLARE @DBName NVARCHAR(100) 
DECLARE @RestoreDBName NVARCHAR(100)
DECLARE @BULocation NVARCHAR(500)
DECLARE @BUFile NVARCHAR(500)
DECLARE @BaseRestore NVARCHAR(MAX)
DECLARE @Stopper INT
DECLARE @LogicalName NVARCHAR(100)
DECLARE @Type NVARCHAR(100)
DECLARE @FileName NVARCHAR(100)
DECLARE @DataFileName NVARCHAR(100)
DECLARE @LogFileName NVARCHAR(100)
DECLARE @DataFileLoc NVARCHAR(100) 
DECLARE @LogFileLoc NVARCHAR(100)
DECLARE @ServerName NVARCHAR(100)
DECLARE @BUFolder NVARCHAR(200)
DECLARE @FileList NVARCHAR(MAX)

---------------------------------------------------------------------------------------------------------------------------------
--Location where database datafile will be created
SET @DataFileLoc = 'D:\SQLDATA\MSSQL\Data\' ;

-- Location where database logfile will be created
SET @LogFileLoc = 'L:\SQLDATA\';

-- Folder location of backup files being used for restore
SET @BULocation = '\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\Temporary Backups\'

-- File names for the list of backup files being restored
SET @FileList = 'PGE_IRASv6_CONFIG_AFTER_UPGRADE_June_22.bak
PGE_IRASv6_LINK_AFTER_UPGRADE_June_22.bak
PGE_IRASv6_STAGE_AFTER_UPGRADE_June_22.bak'
---------------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb.dbo.##DataFileInfo') IS NOT NULL
BEGIN
	EXECUTE ('DROP TABLE dbo.##DataFileInfo');
END

IF OBJECT_ID('tempdb.dbo.##DataFileInfo') IS NULL
BEGIN
	EXECUTE  ('CREATE TABLE ##DataFileInfo (Id INT IDENTITY(1,1),
							 LogicalName NVARCHAR(500),
							 PhysicalName NVARCHAR(500),
							 Type CHAR(1),
							 FileGroupName NVARCHAR(255),
							 Size NUMERIC(30),
							 MaxSize NUMERIC(30),
							 FileId NUMERIC(2),
							 CreateLSN NUMERIC(30),
							 DropLSN NUMERIC(30),
							 UniqueId NVARCHAR(100),
							 ReadOnlyLSN NUMERIC(30),
							 ReadWriteLSN NUMERIC(30),
							 BackupSizeInBytes NUMERIC(30),
							 SourceBlockSize NUMERIC(5),
							 FileGroupId SMALLINT,
							 LogGroupGUID NVARCHAR(300),
							 DifferentialBaseLSN NVARCHAR(300),
							 DifferentialBaseGUID NVARCHAR(300),
							 IsReadOnly NUMERIC(1),
							 IsPresent NUMERIC(10),
							 TDEThumbprint NVARCHAR(100),
							 SnapShotUrl NVARCHAR(100))
							');
END

	-- Table to store info on a single backupset
	DECLARE @BackupSetInfo TABLE(Name NVARCHAR(100),
								 Descripion NVARCHAR(255),
								 Type SMALLINT,
								 ExpirationDate DATETIME,
								 Compressed INT,
								 Position SMALLINT,
								 Device INT,
								 UserName NVARCHAR(100),
								 ServerName NVARCHAR(100),
								 DatabaseName NVARCHAR(100),
								 DatabaseVersion INT,
								 DBCreationDate DATETIME,
								 BackupSize BIGINT,
								 FirstLSN NUMERIC(30),
								 LastLSN NUMERIC(30),
								 CheckPointLSN NUMERIC(30),
								 DatabaseBackupLSN NUMERIC(30),
								 BackupStartDate DATETIME,
								 BackupFinishDate DATETIME,
								 SortOrder INT,
								 CodePage INT,
								 UniCodeLocaleId INT,
								 UnicodeComparisonStyle INT,
								 CompatibilityLevel INT,
								 SoftwareVendorId INT,
								 SoftwareVersionMajor INT,
								 SoftwareVersionMinor INT,
								 SoftwareVersionBuild INT,
								 MachineName NVARCHAR(100),
								 Flags INT,
								 BindingId NVARCHAR(100),
								 RecoveryFokId NVARCHAR(100),
								 Collation NVARCHAR(100),
								 FamilyGUID NVARCHAR(100),
								 HasBulkLoggedData INT,
								 IsSnapshot INT,
								 IsReadOnly INT,
								 IsSingleUser INT,
								 HasBackupChecksums INT,
								 IsDamaged INT,
								 BeginsLogChain INT,
								 HasIncompleteMetaData INT,
								 IsForceOffline INT,
								 IsCopyOnly INT,
								 FirstRecoveryForkId NVARCHAR(100),
								 ForkPointLSN NUMERIC(30),
								 RecoveryModel NVARCHAR(50),
								 DifferentialLSN NUMERIC(30),
								 DifferentialBaseGUID NVARCHAR(100),
								 BackupTypeDescription NVARCHAR(50),
								 BackupSetGUID NVARCHAR(100),
								 CompressedBackupSize BIGINT,
								 Containment INT,
								 KeyAlgorithm NVARCHAR(100),
								 EncryptorThumbprint NVARCHAR(100),
								 EncryptorType NVARCHAR(100)
								 --LastValidRestoreTime DATETIME,
								 --TimeZone INT,
								 --CompressionAlgorithm NVARCHAR(100)
								 )

SET @FileList = REPLACE(@FileList, ' ', '')
SET @FileList = REPLACE(@FileList, CHAR(10), ' ')
SET @FileList = REPLACE(@FileList, CHAR(13), '')
SET @FileList = REPLACE(@FileList, CHAR(9), '')
SET @FileList = REPLACE(@FileList, ' ', ''', ''')
SET @FileList = REPLACE(@FileList, ''''', ', '')

SET @FileList = '''' + @FileList + ''''

-- Create tables to store a list of the backup files
IF OBJECT_ID ('tempdb..##BUDirFiles') IS NOT NULL
BEGIN
	EXECUTE ('DROP TABLE tempdb..##BUDirFiles');
END

IF OBJECT_ID ('tempdb.dbo.##BUDirFiles') IS NULL
BEGIN
	SET @SQL = 'CREATE TABLE  dbo.##BUDirFiles  (SubDirectory NVARCHAR(255),
										     Depth SMALLINT,
										     FileFlag BIT,
										     ParentDirectoryID INT)';
	EXECUTE (@SQL);
END

DECLARE @BUDirFiles TABLE(Id INT IDENTITY(1,1),
						  SubDirectory NVARCHAR(255),
						  Depth SMALLINT,
						  FileFlag BIT,
						  ParentDirectoryID INT)
						  
-- Get the list of all files in the backup directory
SET @SQL = 'INSERT INTO ##BUDirFiles (SubDirectory, Depth, FileFlag)
			EXEC master..xp_dirtree ''' + @BULocation + ''' , 10, 1';

EXECUTE (@SQL)

SET @SQL = 'DECLARE @Result TABLE (SubDirectory NVARCHAR(255),
								   Depth SMALLINT,
								   FileFlag BIT,
								   ParentDirectoryID INT)
INSERT INTO @Result
SELECT * FROM ##BUDirFiles
WHERE Subdirectory IN (' + @FileList + ')

SELECT * FROM @Result';

INSERT INTO @BUDirFiles
EXECUTE (@SQL)

DECLARE FileList_Cursor CURSOR FOR
SELECT SubDirectory FROM @BUDirFiles

OPEN FileList_Cursor
FETCH NEXT FROM FileList_Cursor INTO @FileName

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @BUFile = @BULocation + @FileName
	SELECT @BUFile

	DELETE FROM @BackupSetInfo
	
	-- Backup backup set header info in table
	INSERT INTO @BackupSetInfo
	EXECUTE ('RESTORE HEADERONLY FROM DISK = ''' + @BUFile + '''')

	-- NUmber of backups in backupset
	SELECT @NumOfBackups = MAX(Position) FROM @BackupSetInfo
	
	IF @NumOfBackups = 1
	BEGIN
		SET @Recovery = 'RECOVERY'
	END
	ELSE
	BEGIN
		SET @Recovery = 'NORECOVERY'
	END

	--Command to get datafile and logfile info for restore (i.e. logical filenames) 
	
	SET @SQL = 'RESTORE FILELISTONLY  
	FROM DISK = ''' + @BUFile + '''' 

	-- Refresh table for storing datafile and logfile info
	EXECUTE ('TRUNCATE TABLE ##DataFileInfo');

	-- Insert datafile and logfile info into table
	EXECUTE ('INSERT INTO ##DataFileInfo
	EXECUTE sp_executesql ''' + @SQL + '')

	--SELECT * FROM ##DataFileInfo
	--BREAK
	--############################################# RESTORE BASE FULL BACKUP ########################################

	SELECT @DBName = DatabaseName FROM @BackupSetInfo

	-- Construct command to perform the first restore using the base full backup 
	SET @BaseRestore = 'RESTORE DATABASE ' + @DBName + '
	FROM DISK = ''' +  @BUFile + '''
	WITH REPLACE, ' + @Recovery + ', '

	SELECT @Stopper = COUNT(1) FROM ##DataFileInfo
	SET @Counter = 1

	-- Loop to contruct command to perform first restore with base backup file 
	WHILE @Counter <= @Stopper
	BEGIN
		--WITH query AS (
		--SELECT  ROW_NUMBER() OVER(ORDER BY Id ASC) AS RowNum, LogicalName
		--FROM ##DataFileInfo
		--)
		SELECT @LogicalName = LogicalName 
		FROM ##DataFileInfo
		WHERE Id = @Counter;

		--WITH query AS (
		--SELECT  ROW_NUMBER() OVER(ORDER BY ID ASC) AS RowNum, FileId
		--FROM ##DataFileInfo
		--)
		SELECT @Type = CASE 
						WHEN FileId = 1 THEN '.mdf'','
						WHEN FileId = 2 THEN '_LOG.ldf'''
						ELSE CAST(@Counter AS NVARCHAR) + '.ndf'','
						END
		FROM ##DataFileInfo
		WHERE Id = @Counter;

		IF (SELECT type FROM ##DataFileInfo WHERE Id = @Counter) = 'L'
		BEGIN
			SET @BaseRestore += CHAR(10) + 'MOVE ''' + @LogicalName +''' TO ''' + @LogFileLoc + @DBName + @Type;
		END
		ELSE
		BEGIN
			SET @BaseRestore += CHAR(10) + 'MOVE ''' + @LogicalName +''' TO ''' + @DataFileLoc + @DBName + @Type;
		END;

		select * from ##DataFileInfo
		SET @Counter += 1;
	END;

	-- Restore Base Full-backup (File 1)
	--EXECUTE (@BaseRestore)
	SELECT @BaseRestore

	--####################################### RESTORE DIFFERENTIAL BACKUPS ################################################

	-- Reset counter for each file being processed
	SET @Counter = 2

	-- Use While-Loop to restore Differential backups
	WHILE @Counter <= @NumOfBackups
	BEGIN
		-- Restore the last differential backup with RECOVERY
		IF @Counter = @NumOfBackups
		BEGIN
			SET @Recovery = 'RECOVERY'
		END

		BEGIN TRY
			SET @SQL = 'RESTORE DATABASE ' + @DBName + '
						FROM DISK = ''' + @BUFile + '''    
						WITH FILE = ' + CAST(@Counter AS NVARCHAR) + ', ' + @Recovery 
			EXECUTE (@SQL)
			--SELECT @SQL
		END TRY
		BEGIN CATCH
		
			PRINT CHAR(10) + 'COULD NOT PERFORM THE RESTORE FOR FILE ' + CAST(@Counter AS NVARCHAR)
			PRINT ERROR_MESSAGE()

			-- Recover the database to the last valid backup if last differential backup is not valid
			IF @Counter = @NumOfBackups
			BEGIN
				BEGIN TRY
					-- Restore and recover dummy database with base backup file		
					SET @BaseRestore = REPLACE(@BaseRestore, 'NORECOVERY', 'RECOVERY')
					EXECUTE (@BaseRestore)
					--SELECT @BaseRestore
				END TRY
				BEGIN CATCH
					PRINT ERROR_MESSAGE()
				END CATCH
			END
		END CATCH

		SET @Counter += 1
	END -- End of While-Loop
	

	FETCH NEXT FROM FileList_Cursor INTO @FileName;

END

CLOSE FileList_Cursor;
DEALLOCATE FileList_Cursor;