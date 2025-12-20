/* 

NOTE** You must close and reopen the script (Or delete/drop the ##CompletedRestores table) to redo successful restores

@ForceConnectionsClosed

	Set to 'Y' if you want to force any connections to the database being restored to be closed before 
	the restore

---------------------------------------------------------------------------------------------------------------

@FileDirectory

	Set the folder location for the ".bak" files being used for the restore. You can

1. Set the @FileDirectory variable to NULL if you wish to specify the full file paths for all backup files
   using the @FileRestoreList variable
2. Set @FileDirectory to a folder path THEN set BOTH the @FileRestoreList and @DBRestoreList variables
	to NULL to restore all ".bak" files	from the specifed @FileDirectory folder 
3. Set @FileDirectory to a folder path then limit the restore to specific files and/or databases by setting the 
	@FileRestoreList and/or @DBRestoreList variables

Example:

SET @FileDirectory = '\\dras-dbbkp02\P_DB_Backups_Nightly\Temporary Backups\'

---------------------------------------------------------------------------------------------------------------

@FileRestoreList

List the backup files and the database names you would like to be used for the restore. The file and database 
names should be SEPERATED BY A 'TAB' SPACE or a comma (,). Each new file (or file and database name) within the list
should be SEPERATED USING A 'RETURN' KEY SPACE or a semi-colon (;). You can specify the full file path or just the 
file name. For any files listed without a full file path, the folder path specified in @FileDirectory is 
assumed to be the parent folder. If no database name is listed next to the file name (or file path), the 
database will be restored using the default database name in the ".bak" file.
	
Example 1:
	
SET @FileRestoreList = 'C:\Folder1\File1.bak	NewDatabaseName1
C:\Folder2\File2.bak
File3.bak	NewDatabase2
File4.bak'

Example 2:

SET @FileRestoreList = 'C:\Folder1\File1.bak,	NewDatabaseName1;
C:\Folder2\File2.bak;
File3.bak,	NewDatabase2;
File4.bak'

---------------------------------------------------------------------------------------------------------------

List the databases you would like to be restored seperated by a 'ENTER' key space. the script checks for 
the specified databases in the folder path specified with the @FileDirectory variable and restores it if found

Example:

SET @DBRestoreList = 'DBname1
DBname2
DBname3'

-------------------------------------------------------------------------------------------------------------

@RestorePoint

SET the Date and time using format 'YYYY-MM-DD HH24:Min:Sec.millisec' to restore to the closest backup
BEFORE the time specified. SET to 'NULL' to restore to the latest valid backup

-----------------------------------------------------------------------------------------------------------

@DataFileLoc 

Restore location for Data files. Set to empty string or NULL to use default location from 
the target server

--------------------------------------------------------------------------------------------------------------

@LogFileLoc

Restore location log files. Set to empty string or NULL to use default location from 
the target server

*/
USE master

DECLARE @SQL NVARCHAR(MAX)
DECLARE @Counter INT 
DECLARE @Recovery NVARCHAR(10)
DECLARE @DBName NVARCHAR(100) 
DECLARE @FileDirectory NVARCHAR(500)
DECLARE @FileName NVARCHAR(1000)
DECLARE @Stopper INT
DECLARE @LogicalName NVARCHAR(100)
DECLARE @Type NVARCHAR(100)
DECLARE @DataFileName NVARCHAR(100)
DECLARE @LogFileName NVARCHAR(100)
DECLARE @DataFileLoc NVARCHAR(100) 
DECLARE @LogFileLoc NVARCHAR(100)
DECLARE @FileRestoreList NVARCHAR(MAX)
DECLARE @CursorIndex INT = 1
DECLARE @EndOfLine INT
DECLARE @StartOfLine INT
DECLARE @SubstringLine NVARCHAR(MAX)
DECLARE @RestorePoint NVARCHAR(100)
DECLARE @FullBckpPosition INT
DECLARE @DiffBckpPosition INT
DECLARE @LastBckpPosition INT
DECLARE @SubCounter INT
DECLARE @TargetBckpPosition INT
DECLARE @DBRestoreList NVARCHAR(MAX)
DECLARE @ForceConnectionsClosed NVARCHAR(1)
DECLARE @ErrMsg NVARCHAR(MAX)

--***********************************************************************************************************
/*
DROP TABLE ##CompletedRestores
*/
-- Force connected sessions to be before restore 
SET @ForceConnectionsClosed = 'N'

-- Set folder location for backup (".bak") files
SET @FileDirectory =  NULL

-- List of BACKUP FILES to be restored
SET @FileRestoreList = NULL

-- List of DATABASES to be restored
SET @DBRestoreList = NULL

-- Restore point
SET @RestorePoint = NULL

-- Location where database DATA FILES will be created
SET @DataFileLoc = NULL

-- Location where database LOG FILES will be created
SET @LogFileLoc = NULL

--*******************************************************************************************************

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

----------------------  Create and start an Extended Events Session


SET @FileDirectory = REPLACE(REPLACE(REPLACE(@FileDirectory, CHAR(10), ''), CHAR(9), ''), CHAR(13), '') 
SET @LogFileLoc = REPLACE(REPLACE(REPLACE(@LogFileLoc, CHAR(10), ''), CHAR(13), ''), CHAR(9), '')
SET @DataFileLoc = REPLACE(REPLACE(REPLACE(@DataFileLoc, CHAR(10), ''), CHAR(13), ''), CHAR(9), '')

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

IF OBJECT_ID('tempdb..##BackupSetInfo_' + CAST(@@SPID AS NVARCHAR)) IS NOT NULL
BEGIN
	SET @SQL = 'DROP TABLE ##BackupSetInfo_' + CAST(@@SPID AS NVARCHAR)
	EXECUTE (@SQL);
END;

IF OBJECT_ID('tempdb..##BackupSetInfo_' + CAST(@@SPID AS NVARCHAR)) IS NULL
BEGIN
	-- Table to store info on a single backupset
	SET @SQL = 'CREATE TABLE ##BackupSetInfo_' + CAST(@@SPID AS NVARCHAR) + ' (Name NVARCHAR(100),
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

SET @DBRestoreList = REPLACE(@DBRestoreList, CHAR(32), '')
SET @DBRestoreList = REPLACE(@DBRestoreList, CHAR(13), ',')
SET @DBRestoreList = REPLACE(@DBRestoreList, CHAR(9), CHAR(32))

SET @FileRestoreList = REPLACE(@FileRestoreList, CHAR(9), CHAR(32))
SET @FileRestoreList = REPLACE(@FileRestoreList, CHAR(13), CHAR(32))
SET @FileRestoreList = REPLACE(@FileRestoreList, CHAR(10), ';')

IF CHARINDEX(@FileDirectory, '\', LEN(@FileDirectory)) = 0
BEGIN
	SET @FileDirectory = @FileDirectory + '\'
END

IF OBJECT_ID('tempdb..##RestoreList') IS NOT NULL
BEGIN
	DROP TABLE ##RestoreList
END

CREATE TABLE ##RestoreList (FileName NVARCHAR(500), TargetDB NVARCHAR(100))

IF OBJECT_ID('tempdb..##CompletedRestores') IS NULL
BEGIN
	CREATE TABLE ##CompletedRestores (FileName NVARCHAR(1000), OriginalDBName VARCHAR(100), RestoredDBName VARCHAR(100))
END

-- Create table variable to store the results of the report
IF OBJECT_ID('tempdb..##RestoreReportTable') IS NULL
BEGIN
	CREATE TABLE ##RestoreReportTable (OriginalDBName VARCHAR(100),
								RestoredDBName VARCHAR(100),
								RestoreStatus VARCHAR(100),
								FilePosition INT,
								BackupType VARCHAR(50),
								FileName VARCHAR(500),
								BackupStartDate DATETIME,
								BackupFinishDate DATETIME,
								Details NVARCHAR(MAX),
								RestoreCompletionTime DATETIME DEFAULT GETDATE()
								)
END

-- Create tables to store a list of the backup files
IF OBJECT_ID ('tempdb.dbo.##BUDirFiles_' + CAST(@@SPID AS NVARCHAR)) IS NOT NULL
BEGIN
	SET @SQL = 'DROP TABLE dbo.##BUDirFiles_' + CAST(@@SPID AS NVARCHAR)
	EXECUTE (@SQL);
END

IF OBJECT_ID ('tempdb.dbo.##BUDirFiles_' + CAST(@@SPID AS NVARCHAR)) IS NULL
BEGIN
	SET @SQL = 'CREATE TABLE  dbo.##BUDirFiles_' + CAST(@@SPID AS NVARCHAR) + '  (FileName NVARCHAR(255))';
	EXECUTE (@SQL);
END

-- Must initialize the string variable to be dynamically modifed in loop
SET @SQL = ''

SET @CursorIndex = 1

-- Loop to dynamically construct INSERT command
WHILE 1=1 AND @FileRestoreList IS NOT NULL
BEGIN

	SET @StartOfLine = @CursorIndex 
	SET @EndofLine = CHARINDEX(';', @FileRestoreList, @CursorIndex + 1) 
	SET @FileName = NULL
	SET @DBName = NULL

	IF(@EndOfLine <> 0)
	BEGIN
		SET @SubstringLine = RTRIM(LTRIM(SUBSTRING(@FileRestoreList, @StartOfLine, @EndOfLine - @StartOfLine)))
	END
	ELSE
	BEGIN
		SET @EndOfLine = LEN(@FileRestoreList) + 1
		SET @SubstringLine = RTRIM(LTRIM(SUBSTRING(@FileRestoreList, @StartOfLine, @EndOfLine - @StartOfLine)))
	END

	IF CHARINDEX(CHAR(32), @SubstringLine, CHARINDEX('.bak', @SubstringLine) + 1) BETWEEN 1 AND @EndOfLine - 1 OR CHARINDEX(',', @SubstringLine) <> 0
	BEGIN		
		SET @FileName = SUBSTRING(@SubstringLine, 0, CHARINDEX(CHAR(32), @SubstringLine, CHARINDEX('.bak', @SubstringLine)))
		SET @DBName = SUBSTRING(@SubstringLine, CHARINDEX(CHAR(32), @SubstringLine, CHARINDEX('.bak', @SubstringLine) + 1), LEN(@SubstringLine) + 1)
	END
	ELSE
	BEGIN
		SET @FileName = @SubstringLine
	END

	SET @FileName = REPLACE(REPLACE(REPLACE(@FileName, '"', ''), ',', ''), ';', '')

	IF (@FileName <> '' AND @DBName IS NOT NULL)
	BEGIN
		SET @SQL += 'INSERT INTO ##RestoreList VALUES (''' + @FileName + ''', ''' + RTRIM(LTRIM(@DBName)) + ''');' + CHAR(10)
	END
	ELSE IF (@FileName <> '')
	BEGIN
		SET @SQL += 'INSERT INTO ##RestoreList VALUES (''' + @FileName + ''', NULL);' + CHAR(10)
	END

	SET @CursorIndex = @EndOfLine + 1

	-- Condition for exiting the loop
	IF (@EndOfLine >= LEN(@FileRestoreList)) OR @FileRestoreList IS NULL 
		OR RTRIM(LTRIM(REPLACE(REPLACE(REPLACE(@FileRestoreList, CHAR(13), ''), CHAR(10), ''), CHAR(9), ''))) = '' 
	BEGIN
		BREAK;
	END


	
END

--Insert dynamically constructed INSERT statement into ##RestoreList
EXECUTE (@SQL)

SET @SQL = ''
SET @CursorIndex = 1

WHILE 1=1 AND @DBRestoreList IS NOT NULL
BEGIN
	SET @StartOfLine = @CursorIndex 
	SET @EndofLine = CHARINDEX(',', @DBRestoreList, @CursorIndex) 

	IF(@EndOfLine <> 0)
	BEGIN
		SET @SubstringLine = REPLACE(SUBSTRING(@DBRestoreList, @StartOfLine, @EndOfLine - @StartOfLine), CHAR(10), '')
	END
	ELSE
	BEGIN
		SET @EndOfLine = LEN(@DBRestoreList)
		SET @SubstringLine = REPLACE(SUBSTRING(@DBRestoreList, @StartOfLine, @EndOfLine - @StartOfLine), CHAR(10), '')
	END

	SET @DBName = REPLACE(@SubstringLine, ';', '')

	IF (@SubstringLine != '')
	BEGIN
		SET @SQL += 'INSERT INTO ##RestoreList VALUES (NULL, ''' + @DBName + ''');' + CHAR(10)
	END

	SET @CursorIndex = @EndOfLine + 1

	-- Condition for exiting the loop
	IF (@EndOfLine >= LEN(@DBRestoreList)) OR @DBRestoreList IS NULL 
		OR RTRIM(LTRIM(REPLACE(REPLACE(REPLACE(@DBRestoreList, CHAR(13), ''), CHAR(10), ''), CHAR(9), ''))) = '' 
	BEGIN
		BREAK;
	END
	
END

--Insert dynamically constructed INSERT statement into ##RestoreList
EXECUTE (@SQL)

-- Finds the datafile location on the server where the script is being executed	
IF @DataFileLoc IS NULL 
BEGIN
	--Location WHERE database datafile will be created (MAKE SURE THIS LOCATION EXISTS ON THE DATABASE SERVER)
	SET @DataFileLoc = CONVERT(NVARCHAR,SERVERPROPERTY('InstanceDefaultDataPath'))
END

-- Finds the logfile location on the server where the script is being executed	
IF @LogFileLoc IS NULL 
BEGIN
	-- Location WHERE database logfile will be created (MAKE SURE THIS LOCATION EXISTS ON THE DATABASE SERVER)
	SET @LogFileLoc = CONVERT(NVARCHAR,SERVERPROPERTY('InstanceDefaultLogPath'))
END;

IF (@DataFileLoc IS NULL)
BEGIN

	PRINT ERROR_MESSAGE() + CHAR(10);
	THROW 51001, N'Specify a directory for the datafile and Logfile', 1;

END
ELSE IF (@DataFileLoc IS NOT NULL AND @LogFileLoc IS NULL)
BEGIN
	SET @LogFileLoc = @DataFileLoc
END

-- Get the list of all files in the backup directory
IF @FileDirectory IS NOT NULL
BEGIN
	SET @SQL = 'INSERT INTO ##BUDirFiles_' + CAST(@@SPID AS NVARCHAR) + ' (FileName)
				EXEC master..xp_cmdshell ''dir /b "' + @FileDirectory + '*.bak"''';
END

EXECUTE (@SQL)


UPDATE ##RestoreList
SET FileName = CASE WHEN CHARINDEX('\', FileName) = 0 
						THEN COALESCE(@FileDirectory, '') + REPLACE(FileName, '"', '')
					ELSE REPLACE(FileName, '"', '')
				END

SET @SQL = 'UPDATE ##BUDirFiles_' + CAST(@@SPID AS NVARCHAR) + '
SET FileName = CASE WHEN CHARINDEX(''\'', FileName) = 0 
						THEN ''' + COALESCE(@FileDirectory, '') + ''' + REPLACE(FileName, ''"'', '''')
					ELSE REPLACE(FileName, ''"'', '''')
				END'

EXECUTE (@SQL)

IF OBJECT_ID('tempdb..##PotentialRestoreList') IS NOT NULL
BEGIN
	DROP TABLE ##PotentialRestoreList
END 

SET @SQL = 'SELECT FileName, RTRIM(LTRIM(TargetDB)) DBName
INTO ##PotentialRestoreList
FROM ##RestoreList rl
WHERE NOT EXISTS (SELECT * FROM ##CompletedRestores cr WHERE cr.FileName = rl.FileName
					AND cr.RestoredDBName = rl.TargetDB)

INSERT INTO ##PotentialRestoreList
SELECT FileName, NULL 
FROM ##BUDirFiles_' + CAST(@@SPID AS NVARCHAR) + ' bf
WHERE FileName IS NOT NULL
--AND FileName NOT IN (SELECT * FROM ##CompletedRestores cr WHERE cr.FileName = bf.FileName)'

EXECUTE  (@SQL)

DECLARE FileList_Cursor CURSOR FOR
SELECT DISTINCT * FROM ##PotentialRestoreList

OPEN FileList_Cursor
FETCH NEXT FROM FileList_Cursor INTO @FileName, @DBName


WHILE @@FETCH_STATUS = 0
BEGIN
	BEGIN TRY

		-- Create and start an Extended Events Session
		SET @SQL = 'IF NOT EXISTS (SELECT * FROM sys.server_event_sessions WHERE name =  ''Error Handling Session(' + CAST(@@SPID AS NVARCHAR) + ')'')
		BEGIN
			CREATE EVENT SESSION [Error Handling Session(' + CAST(@@SPID AS NVARCHAR) + ')]
			ON SERVER 
			ADD EVENT sqlserver.error_reported
			(
				ACTION(
					sqlserver.session_id,
					sqlserver.sql_text
				)
				WHERE [package0].[not_equal_unicode_string]([message],N'''''''''''') 
				AND [severity]>(10) 
				AND [sqlserver].[session_id]=' + CAST(@@SPID AS NVARCHAR) + '
			) 
			ADD TARGET package0.ring_buffer
			WITH (
				EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,

				MAX_MEMORY=4096 KB,
				MAX_DISPATCH_LATENCY=1 SECONDS,
				MAX_EVENT_SIZE=0 KB,
				MEMORY_PARTITION_MODE=NONE,
				TRACK_CAUSALITY=ON,
				STARTUP_STATE=OFF
			)
			ALTER EVENT SESSION [Error Handling Session(' + CAST(@@SPID AS NVARCHAR) + ')] ON SERVER STATE=START;
		END'

		EXECUTE (@SQL)

		-- Set and clear variables
		DECLARE @Result TABLE (FileExists INT)
		SET @SQL = 'DELETE FROM ##BackupSetInfo_' + CAST(@@SPID AS NVARCHAR)
		EXECUTE (@SQL)
		DELETE FROM @Result

		-- Check That the backup file exists
		SET @SQL = 'EXEC master..xp_cmdshell ''IF EXIST  "' + @FileName + '" (ECHO 1) ELSE (ECHO 0)'''

		INSERT INTO @Result
		EXECUTE (@SQL)

		DELETE FROM @Result WHERE FileExists IS NULL

		-- If the backup file does not exist write to the error reporting table
		IF EXISTS (SELECT * FROM @Result WHERE FileExists <> 1) 
		BEGIN	
			INSERT INTO ##RestoreReportTable (OriginalDBName,RestoredDBName, RestoreStatus, FileName, Details)
			SELECT NULL, TargetDB, 'FAILED', @FileName, 'Backup file NOT FOUND'
			FROM ##RestoreList bsi
			WHERE NOT EXISTS (SELECT * FROM ##RestoreReportTable tmp WHERE tmp.FileName = @FileName)
			AND FileName = @FileName;	

			SET @FileName = NULL
		END
	
		-- Get backup info from the backup file
		SET @SQL = 'DECLARE @SQL NVARCHAR(4000) = ''RESTORE HEADERONLY FROM DISK = ''''' + @FileName + '''''''
		INSERT INTO ##BackupSetInfo_' + CAST(@@SPID AS NVARCHAR) + '
		EXECUTE (@SQL)'

		EXECUTE (@SQL)
			
		-- Set the database name for the restore to the DB name from the backup file if db name is not set
		SET @SQL = 'UPDATE ##RestoreList 
		SET TargetDB = DatabaseName
		FROM ##BackupSetInfo_' + CAST(@@SPID AS NVARCHAR) + '
		WHERE FileName = ''' + @FileName + '''
		AND (TargetDB IS NULL OR RTRIM(LTRIM(TargetDB))= '''')'

		EXECUTE (@SQL)

		-- If the database name is not set by the script user restore as db name in backup file
		IF @DBName IS NULL 
		BEGIN
			SET @SQL = 'SELECT @DBName = DatabaseName
			FROM ##BackupSetInfo_' + CAST(@@SPID AS NVARCHAR)
		END

		EXECUTE sp_executesql @SQL, N'@DBName NVARCHAR(100) OUTPUT', @DBName OUTPUT

		-- Filter out files that are not in the restore list if a restore list is set
		IF @FileName IS NOT NULL AND NOT EXISTS (SELECT * FROM ##RestoreList WHERE FileName = @FileName OR
			TargetDB = @DBName) AND EXISTS (SELECT * FROM ##RestoreList) 
		BEGIN
			SET @FileName = NULL
		END

		SET @SQL = 'IF EXISTS (SELECT * FROM ##BUDirFiles_' + CAST(@@SPID AS NVARCHAR) + ' bf
							   WHERE FileName = ''' + @FileName + ''' 
							   AND ''' + @DBName + ''' IN (SELECT TargetDB FROM ##RestoreList rl WHERE FileName IS NOT NULL
															AND rl.FileName <> bf.FileName))
					BEGIN
						SET @Result = NULL
					END'

		EXECUTE sp_executesql @SQL, N'@Result NVARCHAR(500) OUTPUT', @FileName OUTPUT
		
		-- Exit script and show connected sessions if there are current sessions connected to the database
		IF EXISTS (SELECT * FROM sys.databases d LEFT JOIN sysprocesses sp ON d.database_id = sp.dbid
				   WHERE name = @DBName 	AND loginame IS NOT NULL AND loginame NOT LIKE 'NT SERVICE\%')
					AND @FileName IS NOT NULL
				   AND @ForceConnectionsClosed = 'N'
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
				WHERE name = @DBName 
				AND loginame IS NOT NULL AND loginame NOT LIKE 'NT SERVICE\%'  
					ORDER BY 2 

			SET @ErrMsg ='There are current sessions connected to the ' + @DBName+ ' database.'
						+ CHAR(10) + 'The connected sessions are listed in the Result tab. You must disconnect these sessions before restoring the database';
			
			THROW 51001, @ErrMsg, 1

		END
	
		IF @ForceConnectionsClosed = 'Y' AND EXISTS (SELECT * FROM ##RestoreList WHERE TargetDB = @DBName)
			AND EXISTS (SELECT * FROM ##RestoreList) 
			AND NOT EXISTS (SELECT * FROM ##CompletedRestores WHERE FileName = @FileName)
		BEGIN

			SET @SQL = NULL

			SELECT @SQL = COALESCE(@SQL, '') + 'ALTER DATABASE ' + name + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE' + CHAR(10)
				+ 'ALTER DATABASE ' + name + ' SET MULTI_USER' + CHAR(10)
			FROM sys.databases WHERE name = @DBName
		
			EXECUTE (@SQL)		
		END
		
	----------------------------------------- RESTORE BASE FULL BACKUP ------------------------------------------
	
		--Command to get datafile and logfile info for restore (i.e. logical filenames) 	
		SET @SQL = 'RESTORE FILELISTONLY  
		FROM DISK = ''' + @FileName + '''' 

		-- Refresh table for storing datafile and logfile info
		DELETE FROM ##DataFileInfo

		-- Insert datafile and logfile info into table
		INSERT INTO ##DataFileInfo
		EXECUTE sp_executesql @sql

		--Find the position of the backup that would meet the restore point requirement	if one exists
		SET @SQL = 'SELECT @TargetBckpPosition = MAX(Position)
		FROM ##BackupSetInfo_' + CAST(@@SPID AS NVARCHAR) + '
		WHERE BackupStartDate <= ''' + @RestorePoint + ''''

		EXECUTE sp_executesql @SQL, N'@TargetBckpPosition INT OUTPUT', @TargetBckpPosition OUTPUT

		-- Get the postion number of the latest full backup before restore point or lastest full backup if no restore point is set
		IF @RestorePoint IS NOT NULL
		BEGIN
			SET @SQL = 'SELECT @FullBckpPosition = MAX(Position)
			FROM ##BackupSetInfo_' + CAST(@@SPID AS NVARCHAR) + '
			WHERE BackupType = 1 AND Position <= ' + CAST(@TargetBckpPosition AS NVARCHAR)
		END
		ELSE
		BEGIN
			SET @SQL = 'SELECT @FullBckpPosition = MAX(Position) 
			FROM ##BackupSetInfo_' + CAST(@@SPID AS NVARCHAR) + '
			WHERE BackupType = 1'
		END

		EXECUTE sp_executesql @SQL, N'@FullBckpPosition INT OUTPUT', @FullBckpPosition OUTPUT

		SET @SQL = 'SELECT @LastBckpPosition = MAX(Position)
		FROM ##BackupSetInfo_' + CAST(@@SPID AS NVARCHAR)

		EXECUTE sp_executesql @SQL, N'@LastBckpPosition INT OUTPUT', @LastBckpPosition OUTPUT

		--Find the closest valid differential backup to the restore point objective
		IF @FullBckpPosition <> COALESCE(@TargetBckpPosition, @LastBckpPosition)
		BEGIN
			SET @SQL = 'SELECT @DiffBckpPosition = MAX(Position)
			FROM ##BackupSetInfo_' + CAST(@@SPID AS NVARCHAR) + '
			WHERE Position <= ' + CAST(COALESCE(@TargetBckpPosition, @LastBckpPosition) AS NVARCHAR) + '
			AND BackupType = 5
			AND DifferentialBaseGUID = (SELECT BackupSetGUID FROM ##BackupSetInfo_' + CAST(@@SPID AS NVARCHAR) + '
										WHERE Position = ' + CAST(@FullBckpPosition AS NVARCHAR) + '
										)'

			EXECUTE sp_executesql @SQL, N'@DiffBckpPosition INT OUTPUT', @DiffBckpPosition OUTPUT
		END
		ELSE 
		BEGIN
			SET @DiffBckpPosition = NULL
		END


		--Attempt a backup restore ONLY if a full backup exists
		IF @FullBckpPosition IS NOT NULL
		BEGIN
			IF @DiffBckpPosition IS NOT NULL
			BEGIN
				SET @Recovery = 'NORECOVERY'
			END
			ELSE
			BEGIN
				SET @Recovery = 'RECOVERY'
			END
		
			SET @SQL = 'RESTORE DATABASE ' + @DBName + CHAR(10) 
								+ 'FROM DISK = ''' +  @FileName + '''' + CHAR(10) 
								+ 'WITH REPLACE, ' 
								+ 'FILE = ' + CAST(@FullBckpPosition AS NVARCHAR) + ', ' + @Recovery + ', '

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

				SET @SQL +=CHAR(10) + 'MOVE ''' + @LogicalName +''' TO ''' 
									+ CASE WHEN @Type IN ('.mdf'',', '.ndf'',')
											THEN @DataFileLoc
											ELSE @LogFileLoc
									END
											+ @DBName + @Type  
         
				SET @SubCounter += 1
			END -- End of while-loop to construct sql command for base full backup restore

			SET @SQL += ', NOUNLOAD, STATS = 5'

			--------------------------- EXECUTE COMMAND TO RESTORE BASE FULL BACKUP -------------------------------

			-- Execute the command to restore the base full backup
			IF (@FileName IS NOT NULL OR EXISTS (SELECT * FROM ##RestoreList WHERE TargetDB = @DBName OR FileName = @FileName))
			AND NOT EXISTS (SELECT * FROM ##CompletedRestores WHERE FileName = @FileName)
			BEGIN
					
				EXECUTE (@SQL)
											
				SET @SQL = 'MERGE ##RestoreReportTable tgt
				USING (SELECT DatabaseName, Position, BackupTypeDescription, BackupStartDate, BackupFinishDate 
						FROM ##BackupSetInfo_' + CAST(@@SPID AS NVARCHAR) + ' WHERE Position = ' + CAST(@FullBckpPosition AS NVARCHAR) + '
					) 
					AS src (DatabaseName, Position, BackupTypeDescription, BackupStartDate, BackupFinishDate)
				ON (tgt.FileName = ''' + @FileName + ''' AND tgt.RestoredDBName = ''' + @DBName + ''')
				WHEN MATCHED THEN
					UPDATE 
					SET OriginalDBName = DatabaseName,
						RestoreStatus = ''SUCCESS'',
						FilePosition = Position, 
						FileName = ''' + @FileName + ''',
						BackupType = ''Full Backup'',
						BackupStartDate = src.BackupStartDate,
						BackupFinishDate = src.BackupFinishDate,
						Details = NULL
				WHEN NOT MATCHED THEN
					INSERT (OriginalDBName, RestoredDBName, RestoreStatus, 
							FilePosition, BackupType, FileName, BackupStartDate, BackupFinishDate)
					VALUES (DatabaseName, ''' + @DBName + ''', ''SUCCESS'', Position, ''Full Backup'', 
						''' + @FileName + ''', BackupStartDate, BackupFinishDate);'

				EXECUTE (@SQL);
			
			END
		
			---------------------------------------- RESTORE DIFFERENTIAL BACKUPS ----------------------------------------
	
			-- If the backup required to fulfill the restore point requirement is a differential backup , execute the following
			IF @DiffBckpPosition IS NOT NULL AND (@FileName IS NOT NULL OR EXISTS (SELECT * FROM ##RestoreList WHERE TargetDB = @DBName)
			AND EXISTS (SELECT * FROM ##RestoreList))
			AND NOT EXISTS (SELECT * FROM ##CompletedRestores WHERE FileName = @FileName)
			BEGIN

				-- Restore the last differential backup with RECOVERY
				SET @SQL = 'RESTORE DATABASE ' + @DBName + CHAR(10) 
							+ 'FROM DISK = ''' + @FileName + '''' + CHAR(10) 
							+ 'WITH FILE = ' + CAST(@DiffBckpPosition AS NVARCHAR)+ ', RECOVERY' +  ', NOUNLOAD, STATS = 5' 
				
				EXECUTE (@SQL)
			
				SET @SQL = 'MERGE ##RestoreReportTable tgt
				USING (SELECT DatabaseName, Position, BackupTypeDescription, BackupStartDate, BackupFinishDate 
						FROM ##BackupSetInfo_' + CAST(@@SPID AS NVARCHAR) + ' WHERE Position = ' + CAST(@DiffBckpPosition AS NVARCHAR) + '
					) 
					AS src (DatabaseName, Position, BackupTypeDescription, BackupStartDate, BackupFinishDate)
				ON (tgt.FileName = ''' + @FileName + ''' AND tgt.RestoredDBName = ''' + @DBName + ''')
				WHEN MATCHED THEN
					UPDATE 
					SET OriginalDBName = DatabaseName,
						RestoreStatus = ''SUCCESS'',
						FilePosition = Position, 
						FileName = ''' + @FileName + ''',
						BackupType = ''Full + Differential Backup'',
						BackupStartDate = src.BackupStartDate,
						BackupFinishDate = src.BackupFinishDate,
						Details = NULL
				WHEN NOT MATCHED THEN
					INSERT (OriginalDBName, RestoredDBName, RestoreStatus, 
							FilePosition, BackupType, FileName, BackupStartDate, BackupFinishDate)
					VALUES (DatabaseName, ''' + @DBName + ''', ''SUCCESS'', Position, ''Full + Differential Backup'', 
						''' + @FileName + ''', BackupStartDate, BackupFinishDate);'
						
				EXECUTE (@SQL);

			END -- End of differential backup if-statement

			-- Recover the database if no differential backup is needed or found to satisfy the restore point
			IF EXISTS (SELECT * FROM sys.databases WHERE name = @DBName AND state_desc = 'RESTORING')
			BEGIN
				SET @SQL = 'RESTORE DATABASE ' + @DBName + ' WITH RECOVERY'
				EXECUTE(@SQL)
			END

		END -- End of if-statement for checking if a full backup exists
		
		
		IF @FullBckpPosition IS NULL
		BEGIN
			-- If a Full backup is not found. Write to the report table
			SET @SQL = 'INSERT INTO ##RestoreReportTable (OriginalDBName, RestoredDBName, RestoreStatus, FilePosition, BackupType, FileName, BackStartDate, BackupFinishDate, Details)
					SELECT DISTINCT DatabaseName,
							''' + @DBName + ''',
							''FAILED'',
							Position, 
							BackupTypeDescription,
							''' + @FileName + ''',
							BackupStartDate,
							BackupFinishDate,
							''A Valid Full Backup could not be found from the backup file. Backupfile is Invalid for restore''
					FROM ##BackupSetInfo_' + CAST(@@SPID AS NVARCHAR) + '
					WHERE position = 1'

			EXECUTE (@SQL)
		END

		-- Keep track of successful restores
		IF EXISTS (SELECT * FROM ##RestoreReportTable WHERE FileName = @FileName AND RestoreStatus = 'SUCCESS')
		BEGIN
			SET @SQL = 'INSERT INTO ##CompletedRestores
			SELECT ''' + @FileName + ''', DatabaseName, ''' + @DBName + '''
			FROM ##BackupSetInfo_' + CAST(@@SPID AS NVARCHAR) + ' bi
			WHERE NOT EXISTS (SELECT * FROM ##CompletedRestores cr WHERE cr.FileName = ''' + @FileName + '''
							AND RestoredDBName = ''' + @DBName + ''')'

			EXECUTE(@SQL)
		END
	END TRY
	BEGIN CATCH
		DECLARE @FailingSQL NVARCHAR(MAX)

		SET @FailingSQL = @SQL

		SET @SQL = 'DECLARE @XEData XML

		SELECT @XEData = CAST(xet.target_data AS XML)
		FROM sys.dm_xe_session_targets AS xet
		JOIN sys.dm_xe_sessions AS xe
			ON (xe.address = xet.event_session_address)
		WHERE xe.name = ''Error Handling Session(' + CAST(@@SPID AS NVARCHAR) + ')'';

		/*
		Check value of "totalEventsProcessed" to ensure events have been 
		dispatched to event session target (ring_buffer).
		If no events have been processed, delay for a period of MAX_DISPATCH_LATENCY +1 (in seconds).
		*/
		IF @XEData.value(''(/RingBufferTarget/@totalEventsProcessed)[1]'', ''INT'') = 0
		BEGIN
			WAITFOR DELAY ''00:00:02'';

			SELECT @XEData = CAST(xet.target_data AS XML)
			FROM sys.dm_xe_session_targets AS xet
			JOIN sys.dm_xe_sessions AS xe
				ON (xe.address = xet.event_session_address)
			WHERE xe.name = ''Error Handling Session(' + CAST(@@SPID AS NVARCHAR) + ')'';
		END

		SET @ErrorMsg = NULL

		-- Store the error in s variable 
		SELECT @ErrorMsg =  COALESCE(@ErrorMsg + CHAR(10), '''') + x.c.value(N''(data[@name="message"]/value)[1]'', N''NVARCHAR(MAX)'')   
		FROM @XEData.nodes(''//RingBufferTarget/event'') AS x(c)
		WHERE x.c.value(N''(data[@name="destination"]/text)[1]'', N''NVARCHAR(MAX)'') = ''USER'''

		EXECUTE sp_executesql @SQL, N'@ErrorMsg NVARCHAR(MAX) OUTPUT', @ErrMsg OUTPUT

		PRINT 'Failing SQL: ' + CHAR(10) + @FailingSQL + CHAR(10) + CHAR(10) + 'Error Message: ' + @ErrMsg

		---- if the fullbackup restore fails, write to the report table
		SET @SQL = 'MERGE ##RestoreReportTable tgt
		USING (SELECT DatabaseName, Position, BackupTypeDescription, BackupStartDate, BackupFinishDate 
				FROM ##BackupSetInfo_' + CAST(@@SPID AS NVARCHAR) + ' WHERE Position = ' + CAST(@FullBckpPosition AS NVARCHAR) + '
			) 
			AS src (DatabaseName, Position, BackupTypeDescription, BackupStartDate, BackupFinishDate)
		ON (tgt.FileName = ''' + @FileName + ''' AND tgt.RestoredDBName = ''' + @DBName + ''')
		WHEN MATCHED THEN
			UPDATE 
			SET OriginalDBName = DatabaseName,
				RestoreStatus = ''FAILED'',
				FilePosition = Position, 
				BackupType = CASE WHEN ' + CAST(COALESCE(@DiffBckpPosition, -1) AS NVARCHAR) + ' = -1 THEN ''Full Backup''
							ELSE ''Full + Differential Backup''
							END,
				FileName =	''' + @FileName + ''',
				BackupStartDate = src.BackupStartDate,
				BackupFinishDate = src.BackupFinishDate,
				Details = ''' + @ErrMsg + '''
		WHEN NOT MATCHED THEN
			INSERT (OriginalDBName, RestoredDBName, RestoreStatus, 
					FilePosition, FileName, BackupType, BackupStartDate, BackupFinishDate, Details)
			VALUES (DatabaseName, ''' + @DBName + ''', ''FAILED'', Position, ''' + @FileName + ''',
			''Full Backup'', BackupStartDate, BackupFinishDate, ''' + @ErrMsg + ''');'

		EXECUTE (@SQL)
	
		-- STOP and DROP extended events session
		SET @SQL = 'ALTER EVENT SESSION [Error Handling Session(' + CAST(@@SPID AS NVARCHAR) + ')] ON SERVER STATE=STOP;
					DROP EVENT SESSION [Error Handling Session(' + CAST(@@SPID AS NVARCHAR) + ')] ON SERVER;'

		EXECUTE(@SQL);
					
	END CATCH

	FETCH NEXT FROM FileList_Cursor INTO @FileName, @DBName
END

CLOSE FileList_Cursor
DEALLOCATE FileList_Cursor

IF (@ErrMsg NOT LIKE '%sessions%connected%' OR @ErrMsg IS NULL)
BEGIN
	SELECT * FROM ##RestoreReportTable
	WHERE FileName IN (SELECT FileName FROM ##RestoreList) ORDER BY RestoreCompletionTime DESC
END



