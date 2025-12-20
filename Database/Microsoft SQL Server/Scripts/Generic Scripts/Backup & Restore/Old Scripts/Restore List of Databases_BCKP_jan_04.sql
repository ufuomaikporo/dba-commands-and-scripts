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
DECLARE @LastValidBackup DATETIME
DECLARE @LastBackup INT
DECLARE @ForceConnectionsClosed NVARCHAR(1)

--***********************************************************************************************************

SET @ForceConnectionsClosed = 'N'

-- Folder location of backup files being used for restore
SET @BULocation = '\\dras-dbbkp02\P_DB_Backups_Nightly\DRASSQL2017\Nightly\'

/*
	List the backup file name and database name (to be restored as) seperated by a tab space. If no database name is listed
	then the default database name in the restore file is used.
	
	NOTE***: If @StrRestoreList is an empty string and @DBList is null, all backup files in the backup location 
		will be restored. it is best to either us @StrRestoreList only, or use @StrRestoreList with @DBList
*/
SET @StrRestoreList = 
'Xcel_Irasv6_Config.bak	Xcel_Irasv6_Config
'

-- You can use this to specify the databases you want restored (SET to 'NULL' if you want all listed backupfiles to be restored)
SET @DBList = NULL

/* 
SET the Date and time using format 'YYYY-MM-DD HH24:Min:Sec.millisec' to restore to the closest backup
BEFORE the time specified. SET to 'NULL' to restore to the latest valid backup)
*/
SET @RestorePoint = '2025-02-03 23:54:00'

/* 
Restore location for Data file and log file. Set to empty string or NULL to use default location from 
the target server
*/
SET @DataFileLoc = NULL
SET @LogFileLoc = NULL

--*******************************************************************************************************

IF OBJECT_ID('tempdb..##DataFileInfo') IS NOT NULL
BEGIN
	DROP TABLE ##DataFileInfo;
END;

SET @SQL = 'CREATE TABLE ##DataFileInfo (Id INT IDENTITY(1,1),
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
							 TDEThumbprint NVARCHAR(100)' -- Stops here for SQL Server 2014 and lower

IF CAST(SUBSTRING(@@VERSION, CHARINDEX('20', @@VERSION), 4) AS NUMERIC)  > 2014
BEGIN
	SET @SQL += CHAR(10) + CHAR(9) + CHAR(9) + CHAR(9) + CHAR(9) +
	'			,SnapShotUrl NVARCHAR(100)		--SQL2016, SQL2017
							);'

END
ELSE
BEGIN
	SET @SQL += ');'
END

EXECUTE (@SQL)	

IF OBJECT_ID('tempdb..##BackupSetInfo') IS NOT NULL
BEGIN
	DROP TABLE ##BackupSetInfo;
END;

IF OBJECT_ID('tempdb..##BackupSetInfo') IS NULL
BEGIN
	-- Table to store info on a single backupset
	SET @SQL = 'CREATE TABLE ##BackupSetInfo (Name NVARCHAR(100),
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
								 Containment INT' -- Stops here for SQL Server 2014 and lower

	IF CAST(SUBSTRING(@@VERSION, CHARINDEX('20', @@VERSION), 4) AS NUMERIC) > 2014 AND 
	   CAST(SUBSTRING(@@VERSION, CHARINDEX('20', @@VERSION), 4) AS NUMERIC) <= 2019
	BEGIN
		SET @SQL += CHAR(10) + CHAR(9) + CHAR(9) + CHAR(9) + CHAR(9) +
		'				,KeyAlgorithm NVARCHAR(100),
								EncryptorThumbprint NVARCHAR(100),
								EncryptorType NVARCHAR(100)' -- Stops here for SQL2016, SQL2017, SQL2019

	END
	ELSE IF CAST(SUBSTRING(@@VERSION, CHARINDEX('20', @@VERSION), 4) AS NUMERIC) > 2019
	BEGIN
		SET @SQL += CHAR(10) + CHAR(9) + CHAR(9) + CHAR(9) + CHAR(9) +
		'				,KeyAlgorithm NVARCHAR(100),
								EncryptorThumbprint NVARCHAR(100),
								EncryptorType NVARCHAR(100),		--SQL2016, SQL2017, SQL2019
								LastValidRestoreTime DATETIME,
								TimeZone INT,
								CompressionAlgorithm NVARCHAR(100)'
	END

	SET @SQL += CHAR(10) + '								);'

	EXECUTE (@SQL)		

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

IF OBJECT_ID('tempdb..##RestoreList') IS NULL
BEGIN
	CREATE TABLE ##RestoreList (FileName NVARCHAR(500), TargetDB NVARCHAR(100))
END


-- Table to store list of databases that will be restored
DECLARE @DBListTable TABLE (DBName NVARCHAR(100))

SET @SQL = 'SELECT name FROM sys.databases
WHERE name IN (' + @DBList + ')'

INSERT INTO @DBListTable
EXECUTE (@SQL)

-- Create table variable to store the results of the report
DECLARE @MissingBackupReport TABLE (DatabaseName NVARCHAR(100),
									FilePosition INT,
									BackupType NVARCHAR(50),
									FileName NVARCHAR(500),
									BackupStartDate DATETIME,
									BackupFinishDate DATETIME)

-- Create tables to store a list of the backup files
IF OBJECT_ID ('tempdb.dbo.##BUDirFiles_2') IS NOT NULL
BEGIN
	EXECUTE ('DROP TABLE dbo.##BUDirFiles_2');
END

IF OBJECT_ID ('tempdb.dbo.##BUDirFiles_2') IS NULL
BEGIN
	SET @SQL = 'CREATE TABLE  dbo.##BUDirFiles_2  (SubDirectory NVARCHAR(255))';
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


-- Finds the datafile location on the server where the script is being executed	
IF @DataFileLoc IS NULL OR REPLACE(REPLACE(REPLACE(@DataFileLoc, CHAR(10), ''), CHAR(13), ''), CHAR(9), '') = ''
BEGIN
	--Location WHERE database datafile will be created (MAKE SURE THIS LOCATION EXISTS ON THE DATABASE SERVER)
	SELECT TOP 1 @DataFileLoc = REVERSE(SUBSTRING(REVERSE(physical_name), CHARINDEX('\', REVERSE(physical_name)), LEN(physical_name))) 
	FROM sys.master_files 
	WHERE type_desc = 'ROWS'
	AND database_id > 4
END

-- Finds the logfile location on the server where the script is being executed	
IF @LogFileLoc IS NULL OR REPLACE(REPLACE(REPLACE(@LogFileLoc, CHAR(10), ''), CHAR(13), ''), CHAR(9), '') = ''
BEGIN
	-- Location WHERE database logfile will be created (MAKE SURE THIS LOCATION EXISTS ON THE DATABASE SERVER)
	SELECT TOP 1 @LogFileLoc = REVERSE(SUBSTRING(REVERSE(physical_name), CHARINDEX('\', REVERSE(physical_name)), LEN(physical_name))) 
	FROM sys.master_files
	WHERE type_desc = 'LOG'
	AND database_id > 4;
END;

IF (@DataFileLoc IS NULL AND @LogFileLoc IS NULL)
BEGIN
	THROW 51001, N'Specify a directory for the datafile and Logfile', 1
END
ELSE IF (@DataFileLoc IS NOT NULL AND @LogFileLoc IS NULL)
BEGIN
	SET @LogFileLoc = @DataFileLoc
END

-- Get the list of all files in the backup directory
SET @SQL = 'INSERT INTO ##BUDirFiles_2 (SubDirectory)
			EXEC master..xp_cmdshell ''dir /b "' + @BULocation + '*.bak"''';

EXECUTE (@SQL)


-- Filter the list of backup files for the ones listed in the Restore list
IF EXISTS (SELECT 1 FROM ##RestoreList) 
BEGIN
	SET @SQL = 'DELETE FROM ##BUDirFiles_2 
	WHERE SubDirectory NOT IN (SELECT FileName FROM ##RestoreList WHERE FileName IS NOT NULL)';

	EXECUTE (@SQL)

END


IF @StrRestoreList IS NOT NULL AND NOT EXISTS (SELECT * FROM ##BUDirFiles_2 WHERE SubDirectory IS NOT NULL)
BEGIN
	RAISERROR('The backup file(s) could not be found in the specified directory', 11, 0)
END

DECLARE FileList_Cursor CURSOR FOR
SELECT SubDirectory FROM ##BUDirFiles_2
WHERE SubDirectory IS NOT NULL

OPEN FileList_Cursor
FETCH NEXT FROM FileList_Cursor INTO @FileName

WHILE @@FETCH_STATUS = 0
BEGIN

	SET @BUFile = @BULocation + @FileName

	DELETE FROM ##BackupSetInfo
	
	-- Backup backup SET header info in table
	INSERT INTO ##BackupSetInfo
	EXECUTE ('RESTORE HEADERONLY FROM DISK = ''' + @BUFile + '''')

	SET @Counter = 0
	SET @DBName = NULL

	-- If there is no list to restrict databases being restored SET @counter to restore all databases
	IF (@DBList IS NULL)
	BEGIN
		SET @Counter = 1;
	END
	ELSE
	BEGIN
		-- Check if the current backup file contains a database in the @DBList list of databases to be restored
		SELECT @Counter = COUNT(*) FROM @DBListTable
			WHERE DBName = (SELECT DatabaseName FROM ##BackupSetInfo)
				
	END

	-- Set the database name for the restore to the DB name from the backup file if db name is not set
	UPDATE ##RestoreList 
	SET TargetDB = DatabaseName
	FROM ##BackupSetInfo
	WHERE FileName = @FileName
	AND (TargetDB IS NULL OR RTRIM(LTRIM(TargetDB))= '')

	--SET the name that the database will be restored as to the name SET by the script user
	SELECT @DBName = TargetDB 
	FROM ##RestoreList
	WHERE FileName = @FileName

	-- Exit script and show connected sessions if there are current sessions connected to the database
	IF EXISTS (SELECT * FROM sys.databases d JOIN sysprocesses sp ON d.database_id = sp.dbid
				WHERE loginame IS NOT NULL AND d.name IN (SELECT TargetDB FROM ##RestoreList)) AND @ForceConnectionsClosed = 'N'
	BEGIN
		SELECT @@ServerName AS SERVER
				,NAME
				,'Kill ' + CAST(spid AS NVARCHAR) AS Terminate_Sessions
				,loginame
				,login_time
				,STATUS
				,hostname
				,program_name
				,nt_username
			FROM sys.databases d
			LEFT JOIN sysprocesses sp ON d.database_id = sp.dbid
			WHERE  name IN (SELECT TargetDB FROM ##RestoreList) 
			AND loginame IS NOT NULL AND loginame NOT LIKE 'NT SERVICE\%'  
				ORDER BY 2 

		SET @SQL = 'THROW 51001, N'''+ CHAR(10) +'There are current sessions connected to the ' + @DBName+ ' database.'
					+ CHAR(10) + 'The connected sessions are listed in the Result tab. You must disconnect these sessions before restoring the database'', 1;'
		EXECUTE (@SQL)

	END
	
	IF @ForceConnectionsClosed = 'Y'
	BEGIN
		SELECT @SQL = STUFF(
				(SELECT '  ' + 'KILL ' + CAST(spId AS NVARCHAR) +  CHAR(10)
				FROM sys.databases d
				LEFT JOIN sysprocesses sp ON d.database_id = sp.dbid
				WHERE  name IN (SELECT TargetDB FROM ##RestoreList) 
					AND loginame IS NOT NULL 
				FOR XML PATH(N''), TYPE
				).value(N'.[1]', N'nvarchar(max)'), 1, 2, N''
			)
		
		EXECUTE (@SQL)
		
	END

	
	/*
		The counter should be non-zero only when the current backup file contains a database in the 
		restore list @DBList or if @DBList is NULL, in which case you should restore all databases in 
		each backup file
	*/
	IF (@Counter <> 0)
	BEGIN 

--############################### RESTORE BASE FULL BACKUP ################################################
	
		-- Remove the db from the list of dbs to restore	
		DELETE FROM @DBListTable
		WHERE DBName = @DBName

		--Command to get datafile and logfile info for restore (i.e. logical filenames) 	
		SET @SQL = 'RESTORE FILELISTONLY  
		FROM DISK = ''' + @BUFile + '''' 

		-- Refresh table for storing datafile and logfile info
		DELETE FROM ##DataFileInfo

		-- Insert datafile and logfile info into table
		INSERT INTO ##DataFileInfo
		EXECUTE sp_executesql @sql

		--Find the latest valid backup 
		SELECT @LastBackup = MAX(Position) 
		FROM ##BackupSetInfo

		-- Get the postion number of an appropriate full database backup
		SELECT @FullbkpFile = MAX(Position) 
		FROM ##BackupSetInfo 
		WHERE BackupType = 1

		SET @LastValidBackup = NULL

		--Find the latest valid differential backup (Default restore point when none is specified)
		SELECT @LastValidBackup = MAX(BackupStartDate)
		FROM ##BackupSetInfo
		WHERE BackupType = 5
		AND (DatabaseBackupLSN >= ANY (SELECT CheckPointLSN FROM ##BackupSetInfo
									WHERE BackupType = 1)
		OR DatabaseBackupLSN = (SELECT DatabaseBackupLSN FROM ##BackupSetInfo
								WHERE Position = @FullbkpFile)	
			)

		--Find the position of the backup that would meet the restore point requirement		
		SELECT @BackupPosition = MAX(Position)
		FROM ##BackupSetInfo
		WHERE BackupStartDate <=  COALESCE(@RestorePoint, @LastValidBackup)
		
		--Attempt a backup restore ONLY if a full backup exists
		IF @FullbkpFile IS NOT NULL
		BEGIN
			IF (SELECT COUNT(*) FROM ##BackupSetInfo) = 1
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

			SELECT @Stopper = COUNT(1) FROM ##DataFileInfo
			SET @SubCounter = 1

			-- Loop to contruct command for performing the base Full backup restore 
			WHILE @SubCounter <= @Stopper
			BEGIN
				WITH query AS (
				SELECT  ROW_NUMBER() OVER(ORDER BY Id ASC) AS RowNum, LogicalName
				FROM ##DataFileInfo
				)
				SELECT @LogicalName = LogicalName 
				FROM query
				WHERE RowNum = @SubCounter;

				WITH query AS (
				SELECT  ROW_NUMBER() OVER(ORDER BY Id ASC) AS RowNum, FileId
				FROM ##DataFileInfo
				)
				SELECT @Type = CASE 
								WHEN FileId = 1 THEN '.mdf'','
								WHEN FileId = 2 THEN '_LOG.ldf'''
								ELSE CAST(@SubCounter AS NVARCHAR) + '.ndf'','
								END
				FROM query
				WHERE RowNum = @SubCounter;

				SET @BaseRestore +=CHAR(10) + 'MOVE ''' + @LogicalName +''' TO ''' 
									+ CASE WHEN @Type IN ('.mdf'',', '.ndf'',')
											THEN @DataFileLoc
											ELSE @LogFileLoc
									END
											+ @DBName + @Type  
         
				SET @SubCounter += 1
			END -- End of while-loop to construct sql command for base full backup restore

			SET @BaseRestore += ', NOUNLOAD, STATS = 5'

	--------------------------- EXECUTE COMMAND TO RESTORE BASE FULL BACKUP -------------------------------

			BEGIN TRY
				-- Execute the command to restore the base full backup
				EXECUTE (@BaseRestore) 
			END TRY
			BEGIN CATCH	
				-- if the fullbackup restore fails, write to the report table
				INSERT INTO @MissingBackupReport
				SELECT DISTINCT(DatabaseName), 
						Position, 
						BackupTypeDescription,
						@FileName,
						BackupStartDate,
						BackupFinishDate
				FROM ##BackupSetInfo 
				WHERE position = @FullbkpFile ;

				PRINT 'ERROR Restoring ' + @FileName;
				PRINT @BaseRestore;

				THROW
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
					EXECUTE (@SQL)

					print @sql
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
							-- Restore and recover database with base full backup file		
							SET @BaseRestore = REPLACE(@BaseRestore, 'NORECOVERY', 'RECOVERY')
							EXECUTE (@BaseRestore)
						END TRY
						BEGIN CATCH
							PRINT 'ERROR: Executing the following ' + CHAR(10) + CHAR(10) + @BaseRestore;
							THROW
                        END CATCH
					END

					PRINT 'ERROR: Restoring ' + @FileName;
					THROW

				END CATCH
			END -- End of differential backup if-statement

			-- Recover the database if no differential backup is needed or found to satisfy the restore point
			IF EXISTS (SELECT * FROM sys.databases WHERE name = @DBName AND state_desc = 'RESTORING')
			BEGIN
				SET @SQL = 'RESTORE DATABASE ' + @DBName + ' WITH RECOVERY'
				EXECUTE(@SQL)
			END

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

