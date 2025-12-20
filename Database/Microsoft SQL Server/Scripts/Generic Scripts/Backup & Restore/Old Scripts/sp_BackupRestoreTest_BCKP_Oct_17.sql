USE DrasInternal
GO

/*
-- Table for central collection of data for a multi server job setup
USE DrasInternal

IF OBJECT_ID('dbo.InvalidBackupReport', 'U') IS NOT NULL
BEGIN
	DROP TABLE InvalidBackupReport;
END
	
CREATE TABLE InvalidBackupReport (ServerName NVARCHAR(100),
								  DatabaseName NVARCHAR(100),
								  FilePosition INT,
								  BackupType NVARCHAR(50),
								  FileName NVARCHAR(500),
								  BackupFileStatus VARCHAR(8),
								  DaysSinceLastBackup INT,
								  BackupStartDate DATETIME,
								  BackupFinishDate DATETIME,
								  CreatedDate DATETIME DEFAULT SYSDATETIME(),
								  CreatedUser NVARCHAR(40) DEFAULT SUSER_SNAME()
								  )

*/

DECLARE @SQL NVARCHAR(MAX)

IF OBJECT_ID('sp_BackupRestoreTest') IS NOT NULL
BEGIN
	DROP PROCEDURE sp_BackupRestoreTest
END
GO

CREATE PROCEDURE [dbo].[sp_BackupRestoreTest] @BULocation NVARCHAR(500)
AS
BEGIN
	/*

	PRERQUISITES

	1) Backup file must be named after database name. For example for a databases named 'DRAS_IRASv6_TEST_6_3_2_QA' 
		the backup filename must be 'DRAS_IRASv6_TEST_6_3_2_QA.bak'
	2) SET the variables indicated below before running the scipt

	FOR TDE encypted Databasess  

	 1) A master key MUST already be created on the server this script is being executed on 
	 2) the encryption certificate for all TDE encrypted databases must be recreated on the server WHERE this script is being executed


	 */

	DECLARE @SQL NVARCHAR(MAX)
	DECLARE @DBName NVARCHAR(100) 
	DECLARE @BUFile NVARCHAR(500)
	DECLARE @FileName NVARCHAR(100)
	DECLARE @FullbkpFile INT
	DECLARE @BackupPosition INT
	DECLARE @DBList NVARCHAR(MAX)
	DECLARE @LastValidBackup INT
	DECLARE @LastBackup INT


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
									 Containment INT,	--SQL2014'

		IF CAST(SUBSTRING(@@VERSION, CHARINDEX('20', @@VERSION), 4) AS NUMERIC) > 2014 AND 
		   CAST(SUBSTRING(@@VERSION, CHARINDEX('20', @@VERSION), 4) AS NUMERIC) <= 2019
		BEGIN
			SET @SQL += CHAR(10) + CHAR(9) + CHAR(9) + CHAR(9) + CHAR(9) +
			'				KeyAlgorithm NVARCHAR(100),
									EncryptorThumbprint NVARCHAR(100),
									EncryptorType NVARCHAR(100)			--SQL2016, SQL2017, SQL2019'

		END
		ELSE IF CAST(SUBSTRING(@@VERSION, CHARINDEX('20', @@VERSION), 4) AS NUMERIC) > 2019
		BEGIN
			SET @SQL += CHAR(10) + CHAR(9) + CHAR(9) + CHAR(9) + CHAR(9) +
			'				KeyAlgorithm NVARCHAR(100),
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

	-- Create table variable to store the results of the report
	IF OBJECT_ID('dbo.BackupReport') IS NOT NULL
	BEGIN
		DROP TABLE BackupReport;
	END

	CREATE TABLE BackupReport (ServerName NVARCHAR(100),
								DatabaseName NVARCHAR(100),
								FilePosition INT,
								BackupType NVARCHAR(50),
								FileName NVARCHAR(500),
								BackupFileStatus VARCHAR(8),
								DaysSinceLastBackup INT,
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

	--Insert dynamically constructed INSERT statement into ##RestoreList
	EXECUTE (@SQL)

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
	WHERE SubDirectory LIKE ''%bak''

	SELECT * FROM @Result';

	INSERT INTO @BUDirFiles
	EXECUTE (@SQL)

	DECLARE FileList_Cursor CURSOR FOR
	SELECT SubDirectory FROM @BUDirFiles
	--WHERE SubDirectory IN ('IRQ_IRASv6_NonPipe_STAGE.bak', 'MOM_IRASV6_STAGE.bak')

	OPEN FileList_Cursor
	FETCH NEXT FROM FileList_Cursor INTO @FileName

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @BUFile = @BULocation + @FileName

		DELETE FROM ##BackupSetInfo

		-- Backup backup SET header info in table
		BEGIN TRY
			INSERT INTO ##BackupSetInfo
			EXECUTE ('RESTORE HEADERONLY FROM DISK = ''' + @BUFile + '''')
		END TRY
		BEGIN CATCH
			SET @SQL = 'INSERT INTO BackupReport (DatabaseName,
									  FilePosition,
									  BackupType,
									  FileName,
									  BackupFileStatus,
									  DaysSinceLastBackup,
									  BackupStartDate,
									  BackupFinishDate)
			SELECT NULL, 
				   NULL, 
				   NULL,
				   ''' + @FileName + ''',
				   0,
				   NULL,
				   NULL,
				   NULL'

			EXECUTE (@SQL);

			PRINT 'RESTORE HEADERONLY Command Failed for backup file: ' + @BUFile + '. ' + ERROR_MESSAGE()
		END CATCH

		-- SET the name that the database will be restored as to the default name in the backup file if no name was entered by script user	
		SET @SQL = 'SELECT @Result = DatabaseName
		FROM ##BackupSetInfo;'

		EXECUTE sp_executesql @SQL, N'@Result NVARCHAR(100) OUTPUT', @DBName OUTPUT
	
		--Find the latest valid backup 
		SET @SQL = 'SELECT @Result = MAX(Position) 
		FROM ##BackupSetInfo'

		EXECUTE sp_executesql @SQL, N'@Result NVARCHAR(100) OUTPUT', @LastBackup OUTPUT

		-- Find the latest Full backup
		SET @SQL = 'SELECT @Result = MAX(Position)
		FROM ##BackupSetInfo
		WHERE BackupType = 1'

		EXECUTE sp_executesql @SQL, N'@Result NVARCHAR(100) OUTPUT', @FullbkpFile OUTPUT
		
		SET @LastValidBackup = NULL

		-- Find the most recent valid backup based on the LSN chain 
		IF (SELECT BackupType FROM ##BackupSetInfo WHERE Position = @LastBackup) = 5 AND @LastBackup <> 1
		BEGIN
			SELECT @LastValidBackup = MAX(Position)
			FROM ##BackupSetInfo
			WHERE BackupType = 5
			AND (DatabaseBackupLSN = ANY (SELECT CheckPointLSN FROM ##BackupSetInfo
										WHERE BackupType = 1)
			OR DatabaseBackupLSN = ALL (SELECT DatabaseBackupLSN FROM ##BackupSetInfo
									WHERE Position >= @FullbkpFile)	
				)
		END
		ELSE IF (SELECT BackupType FROM ##BackupSetInfo WHERE Position = @LastBackup) = 1
		BEGIN
			SET @LastValidBackup = @LastBackup
		END

		BEGIN TRY
			EXECUTE('RESTORE VERIFYONLY FROM DISK = ''' + @BUFile +'''')
		END TRY
		BEGIN CATCH
			SET @LastValidBackup = NULL
		END CATCH

		-- Check if the backup is invalid
		IF (@LastValidBackup != @LastBackup OR @LastValidBackup IS NULL OR @FullbkpFile IS NULL) 
		BEGIN
			SET @SQL = 'INSERT INTO BackupReport (DatabaseName,
									  FilePosition,
									  BackupType,
									  FileName,
									  BackupFileStatus,
									  DaysSinceLastBackup,
									  BackupStartDate,
									  BackupFinishDate)
			SELECT DISTINCT(DatabaseName), 
					(SELECT MAX(Position) FROM ##BackupSetInfo) , 
					BackupTypeDescription,
					''' + @FileName + ''',
					''INVALID'',
					NULL,
					BackupStartDate,
					BackupFinishDate
			FROM ##BackupSetInfo 
			WHERE position = ' + CAST(@LastBackup AS NVARCHAR) + ''
		END
		ELSE 
		BEGIN
			SET @SQL = 'INSERT INTO BackupReport (DatabaseName,
									  FilePosition,
									  BackupType,
									  FileName,
									  BackupFileStatus,
									  DaysSinceLastBackup,
									  BackupStartDate,
									  BackupFinishDate)
			SELECT DISTINCT(DatabaseName), 
				   (SELECT MAX(Position) FROM ##BackupSetInfo), 
				   BackupTypeDescription,
				   ''' + @FileName + ''',
				   ''VALID'',
				   NULL,
				   BackupStartDate,
				   BackupFinishDate
			FROM ##BackupSetInfo 
			WHERE position = ' + CAST(@LastBackup AS NVARCHAR) + ''
		END

		EXECUTE (@SQL) 

		FETCH NEXT FROM FileList_Cursor INTO @FileName
	END

	CLOSE FileList_Cursor
	DEALLOCATE FileList_Cursor

	SET @SQL = 'UPDATE BackupReport
	SET ServerName = @@SERVERNAME,
	    DaysSinceLastBackup = ABS(DATEDIFF(DAY, GETDATE(), BackupStartDate)) '

	EXECUTE (@SQL)
	
	-- Delete data that is a day old or older from centralized location on DRASSQL2022 server
	DELETE OPENQUERY([DRASSQL2022], 'SELECT * FROM DrasInternal.dbo.InvalidBackupReport 
								WHERE ABS(DATEDIFF(DAY, GETDATE(), CreatedDate)) >= 1
								OR ServerName = @@SERVERNAME')

	-- Store results in centralized location on DRASSQL2022 server 
	SET @SQL = 'INSERT OPENQUERY ([DRASSQL2022], ''SELECT ServerName,
															DatabaseName,
															FilePosition,
															BackupType,
															FileName,
															BackupFileStatus,
															DaysSinceLastBackup,
															BackupStartDate,
															BackupFinishDate 
													 FROM DrasInternal.dbo.InvalidBackupReport'')  
	SELECT ServerName, 
		   DatabaseName, 
		   FilePosition,
		   BackupType,
		   FileName,
		   BackupFileStatus,
		   DaysSinceLastBackup,
		   BackupStartDate,
		   BackupFinishDate
	FROM BackupReport br
	WHERE (DaysSinceLastBackup > 1
	OR BackupFileStatus= ''INVALID'')
	AND NOT EXISTS (SELECT * FROM OPENQUERY([DRASSQL2022], ''SELECT * FROM DrasInternal.dbo.InvalidBackupReport'') rmt
	WHERE rmt.ServerName = br.ServerName AND rmt.FileName = br.FileName)'

	EXECUTE (@SQL)
		
END