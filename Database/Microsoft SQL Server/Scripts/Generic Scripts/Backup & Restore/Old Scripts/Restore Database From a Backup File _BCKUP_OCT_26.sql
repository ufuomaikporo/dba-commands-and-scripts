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
DECLARE @StrRestoreList NVARCHAR(MAX)
DECLARE @CursorIndex INT = 1
DECLARE @EndOfLine INT
DECLARE @StartOfLine INT
DECLARE @SubstringLine NVARCHAR(MAX)
DECLARE @RestorePoint NVARCHAR(100)
DECLARE @FullbkpFile INT
DECLARE @SubCounter INT
DECLARE @BackupPosition INT
DECLARE @DBList NVARCHAR(MAX)
DECLARE @LastValidBackup DateTime

---------------------------------------------------------------------------------------------------------------------------------

-- Folder location of backup files being used for restore
SET @BULocation = '\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\SQL2019\Nightly\'

/*
	List of backup file names and database names (to be restored as) seperated by tab-spacing. If no database name is listed
	then the default database name in the restore file is used
*/
SET @StrRestoreList = 'PAA_PODS_PROD_DELETE_ME.bak'

-- You can use this to specify the databases you want restored (Set to 'NULL' if you want all listed backupfiles to be restored)
SET @DBList = NULL

-- Set the Date and time for the restore (Set to 'NULL' to restore to the latest valid backup)
SET @RestorePoint = NULL

---------------------------------------------------------------------------------------------------------------------------------

DECLARE @DataFileInfo TABLE (Id INT IDENTITY(1,1),
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
							 SnapShotUrl NVARCHAR(100)
							);
							
IF OBJECT_ID('tempdb..##BackupSetInfo') IS NOT NULL
BEGIN
	DROP TABLE ##BackupSetInfo;
END;

IF OBJECT_ID('tempdb..##BackupSetInfo') IS NULL
BEGIN
	-- Table to store info on a single backupset
	CREATE TABLE ##BackupSetInfo (Name NVARCHAR(100),
								 Descripion NVARCHAR(255),
								 BackupType SMALLINT,
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
END;

SET @DBList = REPLACE(@DBList, ' ', '')
SET @DBList = REPLACE(@DBList, CHAR(10), ' ')
SET @DBList = REPLACE(@DBList, CHAR(13), '')
SET @DBList = REPLACE(@DBList, CHAR(9), '')
SET @DBList = REPLACE(@DBList, ' ', ''', ''')

SET @DBList = '''' + @DBList + ''''

IF OBJECT_ID('tempdb..##RestoreList') IS NOT NULL
BEGIN
	DROP TABLE ##RestoreList
END

IF OBJECT_ID('tempdb..RestoreList') IS NULL
BEGIN
	CREATE TABLE ##RestoreList (FileName NVARCHAR(500), RestoredDatabaseName NVARCHAR(100))
END

-- Create table variable to store the results of the report
DECLARE @MissingBackupReport TABLE (DatabaseName NVARCHAR(100),
									FilePosition INT,
									BackupType NVARCHAR(50),
									FileName NVARCHAR(500),
									BackupStartDate DATETIME,
									BackupFinishDate DATETIME)

-- Create tables to store a list of the backup files
IF OBJECT_ID ('tempdb.dbo.##BUDirFiles') IS NOT NULL
BEGIN
	EXECUTE ('DROP TABLE dbo.##BUDirFiles');
END

IF OBJECT_ID ('tempdb.dbo.##BUDirFiles') IS NULL
BEGIN
	SET @SQL = 'CREATE TABLE  dbo.##BUDirFiles  (SubDirectory NVARCHAR(255),
										     Depth SMALLINT,
										     FileFlag BIT,
										     ParentDirectoryID INT)';
	EXECUTE (@SQL);
END

-- Must initialize the string variable to be dynamically modifed in loop
SET @SQL = ''

SET @CursorIndex = 1

-- Loop to dynamically construct INSERT command
WHILE 1=1
BEGIN
	SET @StartOfLine = @CursorIndex 
	SET @EndofLine = CHARINDEX(CHAR(10), @StrRestoreList, @CursorIndex) 

	IF(@EndOfLine <> 0)
	BEGIN
		SET @SubstringLine = SUBSTRING(@StrRestoreList, @StartOfLine, @EndOfLine - @StartOfLine - 1)
	END
	ELSE
	BEGIN
		SET @SubstringLine = @StrRestoreList
		SET @EndOfLine = LEN(@StrRestoreList)
	END

	IF (@SubstringLine != '')
	BEGIN
		IF (CHARINDEX(CHAR(9), @SubstringLine) = 0)
		BEGIN
			SET @SQL += 'INSERT INTO ##RestoreList VALUES (''' + @SubstringLine + ''', NULL);' + CHAR(10)
		END
		ELSE
		BEGIN
			SET @SQL += 'INSERT INTO ##RestoreList VALUES (''' + REPLACE(@SubstringLine, CHAR(9), ''', ''') + ''');' + CHAR(10)
		END

	END

	SET @CursorIndex = @EndOfLine + 1

	-- Condition for exiting the loop
	IF (@EndOfLine >= LEN(@StrRestoreList))
	BEGIN
		BREAK;
	END
	
END

--Insert dynamically constructed INSERT statement into ##RestoreList
EXECUTE (@SQL)

DECLARE @BUDirFiles TABLE(Id INT IDENTITY(1,1),
						  SubDirectory NVARCHAR(255),
						  Depth SMALLINT,
						  FileFlag BIT,
						  ParentDirectoryID INT)
						  
--Location where database datafile will be created (MAKE SURE THIS LOCATION EXISTS ON THE DATABASE SERVER)
SELECT TOP 1 @DataFileLoc = REVERSE(SUBSTRING(REVERSE(physical_name), CHARINDEX('\', REVERSE(physical_name)), LEN(physical_name))) 
FROM sys.master_files 
WHERE type_desc = 'ROWS'
AND database_id > 4;

-- Location where database logfile will be created (MAKE SURE THIS LOCATION EXISTS ON THE DATABASE SERVER)
SELECT TOP 1 @LogFileLoc = REVERSE(SUBSTRING(REVERSE(physical_name), CHARINDEX('\', REVERSE(physical_name)), LEN(physical_name))) 
FROM sys.master_files
WHERE type_desc = 'LOG'
AND database_id > 4;

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
WHERE Subdirectory IN (SELECT FileName FROM ##RestoreList WHERE FileName IS NOT NULL)

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

	DELETE FROM ##BackupSetInfo
	
	-- Backup backup set header info in table
	INSERT INTO ##BackupSetInfo
	EXECUTE ('RESTORE HEADERONLY FROM DISK = ''' + @BUFile + '''')

	SET @Counter = 0

	-- If there is no list to restrict databases being restored set @counter to restore all databases
	IF (@DBList IS NULL)
	BEGIN
		SET @Counter = 1;
	END
	ELSE
	BEGIN
		-- Check if the current backup file contains a database in the @DBList list of databases to be restored
		SET @SQL = 'SELECT @Result = COUNT(*) FROM ##BackupSetInfo WHERE DatabaseName IN (' + @DBList + ')'
		EXECUTE sp_executesql @SQL, N'@Result INT OUT', @Counter OUT
	END

	--Set the name that the database will be restored as to the name set by the script user
	SELECT @DBName = RestoredDatabaseName 
	FROM ##RestoreList
	WHERE FileName = @FileName

	/*
		The counter should be non-zero only when the current backup file contains a database in the 
		restore list @DBList or if @DBList is NULL, in which case you should restore all databases in 
		each backup file
	*/
	IF (@Counter <> 0)
	BEGIN 

--############################### RESTORE BASE FULL BACKUP ################################################
	
		-- Set the name that the database will be restored as to the default name in the backup file if no name was entered by script user	
		IF @DBName IS NULL 
		BEGIN
			SELECT @DBName = DatabaseName
			FROM ##BackupSetInfo;
		END

		--Command to get datafile and logfile info for restore (i.e. logical filenames) 
	
		SET @SQL = 'RESTORE FILELISTONLY  
		FROM DISK = ''' + @BUFile + '''' 

		-- Refresh table for storing datafile and logfile info
		DELETE FROM @DataFileInfo

		-- Insert datafile and logfile info into table
		INSERT INTO @DataFileInfo
		EXECUTE sp_executesql @sql


		--Find the latest valid differential backup (Default restore point when none is specified)
		SELECT @LastValidBackup = MAX(BackupStartDate)
		FROM ##BackupSetInfo
		WHERE DatabaseBackupLSN IN (SELECT CheckPointLSN FROM ##BackupSetInfo
									WHERE BackupType = 1)

		--Find the position of the backup that would meet the restore point requirement
		SELECT @BackupPosition = Position 
		FROM ##BackupSetInfo
		WHERE BackupStartDate <= COALESCE(@RestorePoint, @LastValidBackup)
				
		-- Get the postion number of an appropriate full database backup
		SELECT @FullbkpFile = MIN(Position) 
		FROM ##BackupSetInfo 
		WHERE BackupType = 1
		AND CheckPointLSN = (SELECT DatabaseBackupLSN
								FROM ##BackupSetInfo
								WHERE Position = @BackupPosition)

		--Attempt a backup restore ONLY if a full backup exists
		IF @FullbkpFile IS NOT NULL
		BEGIN
			IF (SELECT BackupType FROM ##BackupSetInfo WHERE Position = @BackupPosition) = 1
			BEGIN
				SET @Recovery = 'RECOVERY'
			END
			ELSE
			BEGIN
				SET @Recovery = 'NORECOVERY'
			END
		
			SET @BaseRestore = 'RESTORE DATABASE ' + @DBName + CHAR(10) 
								+ 'FROM DISK = ''' +  @BUFile + '''' + CHAR(10) 
								+ 'WITH REPLACE, ' 
								+ 'FILE = ' + CAST(@FullbkpFile AS NVARCHAR) + ', ' + @Recovery + ', '
  		
			SELECT @Stopper = COUNT(1) FROM @DataFileInfo
			SET @SubCounter = 1

			-- Loop to contruct command for performing the base Full backup restore 
			WHILE @SubCounter <= @Stopper
			BEGIN
				WITH query AS (
				SELECT  ROW_NUMBER() OVER(ORDER BY Id ASC) AS RowNum, LogicalName
				FROM @DataFileInfo
				)
				SELECT @LogicalName = LogicalName 
				FROM query
				WHERE RowNum = @SubCounter;

				WITH query AS (
				SELECT  ROW_NUMBER() OVER(ORDER BY Id ASC) AS RowNum, FileId
				FROM @DataFileInfo
				)
				SELECT @Type = CASE 
								WHEN FileId = 1 THEN '.mdf'','
								WHEN FileId = 2 THEN '_LOG.ldf'''
								ELSE CAST(@SubCounter AS NVARCHAR) + '.ndf'','
								END
				FROM query
				WHERE RowNum = @SubCounter;

				SET @BaseRestore += CHAR(10) + 'MOVE ''' + @LogicalName +''' TO ''' 
									+ @DataFileLoc + @DBName + @Type  
            

				SET @SubCounter += 1
			END -- End of while-loop to construct sql command for base full backup restore

			SET @BaseRestore += ', NOUNLOAD, STATS = 5'

	--------------------------- EXECUTE COMMAND TO RESTORE BASE FULL BACKUP -------------------------------

			BEGIN TRY
				-- Execute the command to restore the base full backup
				select @BaseRestore
				--BREAK
				--EXECUTE (@BaseRestore) 
			END TRY
			BEGIN CATCH	
				-- if the fullbackup restore fails, write to the report table
				PRINT ERROR_MESSAGE()
				INSERT INTO @MissingBackupReport
				SELECT DISTINCT(DatabaseName), 
						Position, 
						BackupTypeDescription,
						@FileName,
						BackupStartDate,
						BackupFinishDate
				FROM ##BackupSetInfo 
				WHERE position = @FullbkpFile 
			END CATCH
		
		--##################################### RESTORE DIFFERENTIAL BACKUPS #################################################
	
			-- If the backup required to fulfill the restore point requirement is a differential backup , execute the following
			IF (SELECT BackupType FROM ##BackupSetInfo WHERE Position = @BackupPosition) = 5
			BEGIN			
				-- Restore the last differential backup with RECOVERY
				BEGIN TRY
					SET @SQL = 'RESTORE DATABASE ' + @DBName + CHAR(10) 
								+ 'FROM DISK = ''' + @BUFile + '''' + CHAR(10) 
								+ 'WITH FILE = ' + CAST(@BackupPosition AS NVARCHAR)+ ', RECOVERY' +  ', NOUNLOAD, STATS = 5' 
					SELECT @SQL
					--EXECUTE (@SQL)
				END TRY
				BEGIN CATCH		
					-- If a differential backup restore fails, write to the report table
					INSERT INTO @MissingBackupReport
					SELECT DISTINCT(DatabaseName), 
							Position, 
							BackupTypeDescription,
							@FileName,
							BackupStartDate,
							BackupFinishDate
					FROM ##BackupSetInfo 
					WHERE position = @BackupPosition 

					-- Recover the database to the last valid backup if last differential backup is not valid
					IF @Counter = @NumOfBackups
					BEGIN
						BEGIN TRY
							-- Restore and recover dummy database with base backup file		
							SET @BaseRestore = REPLACE(@BaseRestore, 'NORECOVERY', 'RECOVERY')
							EXECUTE (@BaseRestore)
						END TRY
						BEGIN CATCH
							PRINT ERROR_MESSAGE()
						END CATCH
					END
                        
				END CATCH
			END -- End of differential backup if-statement		
		END -- End of if-statement for checking if a full backup exists
		ELSE
		BEGIN
		-- If a Full backup is not found. Write to the report table
			INSERT INTO @MissingBackupReport
					SELECT DISTINCT(DatabaseName), 
							Position, 
							BackupTypeDescription,
							@FileName,
							BackupStartDate,
							BackupFinishDate
					FROM ##BackupSetInfo 
					WHERE position = 1 
		END
		END
	FETCH NEXT FROM FileList_Cursor INTO @FileName
END

CLOSE FileList_Cursor
DEALLOCATE FileList_Cursor


--Create a global temporary table to store the results of the report table
IF EXISTS (SELECT 1 FROM tempdb.sys.tables WHERE name = '##MissingBackupReport')
BEGIN
	DROP TABLE ##MissingBackupReport
END

-- Store report results in a global temporary table
SELECT * 
INTO ##MissingBackupReport
FROM @MissingBackupReport


-- Display result of report table

IF (SELECT COUNT(*) FROM ##MissingBackupReport ) > 0
BEGIN
	PRINT CHAR(10) + 'THE FOLLOWING BACKUPS ARE UNUSABLE FOR DATABASE RESTORE' + CHAR(10)
	SELECT * FROM ##MissingBackupReport
	ORDER BY 4, 1, 2
END

