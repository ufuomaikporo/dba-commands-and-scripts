CREATE OR ALTER PROCEDURE sp_BackupRestoreTest @BULocation NVARCHAR(500), @DataFileLoc NVARCHAR(500)
AS
BEGIN
/*

PRERQUISITES

1) Backup file must be named after database name. For example for a databases named 'DRAS_IRASv6_TEST_6_3_2_QA' 
	the backup filename must be 'DRAS_IRASv6_TEST_6_3_2_QA.bak'
2) SET the variables indicated below before running the scipt

FOR TDE encypted Databasess  

 1) A master key MUST already be created on the server this script is being executed on 
 2) the encryption certificate for all TDE encrypted databases must be recreated on the server where this script is being executed


 */

DECLARE @SQL NVARCHAR(MAX)
DECLARE @NumOfBackups INT 
DECLARE @Counter INT 
DECLARE @Recovery NVARCHAR(10)
DECLARE @DBName NVARCHAR(100) 
--DECLARE @BULocation NVARCHAR(500)
DECLARE @BUFile NVARCHAR(500)
DECLARE @BaseRestore NVARCHAR(MAX)
DECLARE @ServerName NVARCHAR(100)
DECLARE @Stopper INT
DECLARE @LogicalName NVARCHAR(100)
DECLARE @Type NVARCHAR(100)
DECLARE @FileName NVARCHAR(100)
DECLARE @DataFileName NVARCHAR(100)
DECLARE @LogFileName NVARCHAR(100)
--DECLARE @DataFileLoc NVARCHAR(100) 
DECLARE @LogFileLoc NVARCHAR(100)
DECLARE @BUFolder NVARCHAR(200)
DECLARE @CertificateName NVARCHAR(100)

---*********************************** SET THE FOLLOWING VARIABLES BEFORE RUNNING THE SCRIPT **************************************

--SET @ServerName = 'SQL2019'
--SET @BUFolder = '\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\'
--SET @BULocation = @BUFolder + @ServerName + '\Nightly\'
--SET @DataFileLoc = 'D:\' --needs to be a valid location on the SQL Server node 

--*********************************************************************************************************************************

-- Dummy encryption certificate name and database name (Will be deleted)
SET @DBName = 'DELETE_ME'
SET @CertificateName = @DBName + '_Cert'

SET @LogFileLoc = @DataFileLoc

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
							 SnapShotUrl NVARCHAR(100))

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

-- Create table variable to store the results of the report
DECLARE @InvalidBackupReport TABLE (DatabaseName NVARCHAR(100),
									FilePosition INT,
									BackupType NVARCHAR(50),
									FileName NVARCHAR(500),
									BackupStartDate DATETIME,
									BackupFinishDate DATETIME)

-- Create table variable to store a list of the backup files
DECLARE  @BUDirFiles TABLE  (
		Id INT IDENTITY(1,1),
		SubDirectory NVARCHAR(255),
		Depth SMALLINT,
		FileFlag BIT,
		ParentDirectoryID INT
	   )

IF EXISTS (SELECT 1 FROM tempdb.sys.tables WHERE name = '##TDEDirFiles')
BEGIN
	EXECUTE ('DROP TABLE ##TDEDirFiles')
END

EXECUTE ('CREATE TABLE  ##TDEDirFiles (
		Id INT IDENTITY(1,1),
		SubDirectory NVARCHAR(255),
		Depth SMALLINT,
		FileFlag BIT,
		ParentDirectoryID INT
		)')

-- Get the list of all files in the backup directory
INSERT INTO @BUDirFiles (SubDirectory, Depth, FileFlag)
EXEC master..xp_dirtree @BULocation , 10, 1

DECLARE DBList_Cursor CURSOR FOR
SELECT SubDirectory FROM @BUDirFiles
WHERE Subdirectory LIKE '%.bak%'	
 --Subdirectory LIKE '%PGE%.bak%'
--OR Subdirectory LIKE '%DRAS_IRASv6_TEST_6_3_2_QA_CONFIG_TEST%'

------------------------------------- DELETE DUMMY DATABASE IF IT ALREADY EXISTS -------------------------------------

-- Delete dummy database if it already exists
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = @DBName)
BEGIN
	-- Put database in single user mode
	SET @SQL = 'USE ' + @DBName + ';

                ALTER DATABASE ' + @DBName + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
                
				USE [tempdb]';

	EXECUTE(@SQL);

	-- Drop Encryption Key on dummy database if it exists
	IF EXISTS (SELECT 1 FROM sys.certificates WHERE name = @CertificateName)
	BEGIN
		IF (SELECT pvt_key_encryption_type_desc FROM sys.certificates WHERE name = @CertificateName ) <> 'NO_PRIVATE_KEY'
		BEGIN
			SET @SQL =  'USE ' + @DBName + '
						DROP DATABASE ENCRYPTION KEY'
			EXECUTE (@SQL)
		END

		-- Drop Encryption Certificate from server
		--IF EXISTS (SELECT 1 FROM sys.certificates WHERE name = @CertificateName)
		--BEGIN
		--	SET @SQL = 'DROP CERTIFICATE ' + @CertificateName
		--	EXECUTE (@SQL)
		--END

	END
END

------------------------------------------------------------------------------------------------------------------------------

OPEN DBList_Cursor
FETCH NEXT FROM DBList_Cursor INTO @Filename

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @BUFile = @BULocation + @FileName
	
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

---------------------------------------- RESTORE BASE FULL BACKUP ----------------------------------------------------

	--Command to get datafile and logfile info for restore (i.e. logical filenames) 
	BEGIN TRY
		SET @SQL = 'RESTORE FILELISTONLY  
		FROM DISK = ''' + @BUFile + ''''
		
		-- Refresh table for storing datafile and logfile info
		DELETE FROM @DataFileInfo

		-- Insert datafile and logfile info into table
		INSERT INTO @DataFileInfo
		EXECUTE sp_executesql @sql

		-- Construct command to perform the first restore using the base full backup 
		SET @BaseRestore = 'RESTORE DATABASE ' + @DBName + '
		FROM DISK = ''' +  @BUFile + '''
		WITH REPLACE, ' + @Recovery + ', '

		SELECT @Stopper = COUNT(1) FROM @DataFileInfo
		SET @Counter = 1

		-- Loop to contruct command to perform first restore with base backup file 
		WHILE @Counter <= @Stopper
		BEGIN
			WITH query AS (
			SELECT  ROW_NUMBER() OVER(ORDER BY Id ASC) AS RowNum, LogicalName
			FROM @DataFileInfo
			)
			SELECT @LogicalName = LogicalName 
			FROM query
			WHERE RowNum = @Counter;

			WITH query AS (
			SELECT  ROW_NUMBER() OVER(ORDER BY ID ASC) AS RowNum, FileId
			FROM @DataFileInfo
			)
			SELECT @Type = CASE 
							WHEN FileId = 1 THEN '.mdf'','
							WHEN FileId = 2 THEN '_LOG.ldf'''
							ELSE CAST(@Counter AS NVARCHAR) + '.ndf'','
							END
			FROM query
			WHERE RowNum = @Counter;

		
			SET @BaseRestore += CHAR(10) + 'MOVE ''' + @LogicalName +''' TO ''' + @DataFileLoc + @DBName + @Type  
	
			SET @Counter += 1
		END

		EXECUTE (@BaseRestore)
	END TRY
	BEGIN CATCH
		INSERT INTO @InvalidBackupReport
		SELECT TOP 1 DatabaseName, 
				Position, 
				BackupTypeDescription,
				@FileName,
				BackupStartDate,
				BackupFinishDate
		FROM @BackupSetInfo 
	END CATCH
	
	
------------------------------------------- RESTORE DIFFERENTIAL BACKUPS -----------------------------------------------
	
	-- Reset counter for each file being processed
	SET @Counter = 2

	-- Use While-Loop to restore Full + Differential backups
	WHILE @Counter <= @NumOfBackups
	BEGIN
		-- Restore the last differential backup with RECOVERY
		IF @Counter = @NumOfBackups
		BEGIN
			SET @Recovery = 'RECOVERY'

			/**************************************************************************************************************
				If it is able to restore the last backup within the backupset, we can ignore invalid differential backups
				in the middle of the backupset
			*****************************************************************************************************************/
			DELETE FROM @InvalidBackupReport
			WHERE FileName = @FileName;
		END

		BEGIN TRY
			SET @SQL = 'RESTORE DATABASE ' + @DBName + '
						FROM DISK = ''' + @BUFile + '''    
						WITH FILE = ' + CAST(@Counter AS NVARCHAR) + ', ' + @Recovery 
			EXECUTE (@SQL)
		END TRY
		BEGIN CATCH
			INSERT INTO @InvalidBackupReport
			SELECT DISTINCT(DatabaseName), 
					Position, 
					CASE 
					WHEN BackupTypeDescription = 'Database Differential' THEN 'Differential'
					WHEN BackupTypeDescription = 'Database' THEN 'Full'
					ELSE BackupTypeDescription
					END AS BackupType,
					@FileName,
					BackupStartDate,
					BackupFinishDate
			FROM @BackupSetInfo 
			WHERE position = @Counter 

            -- Recover the database to the last valid backup if last differential backup is not valid
			IF @Counter = @NumOfBackups
			BEGIN
				BEGIN TRY
					-- Restore and recover dummy database with base backup file		
					SET @BaseRestore = REPLACE(@BaseRestore, 'NORECOVERY', 'RECOVERY')
					--EXECUTE (@BaseRestore)
				END TRY
				BEGIN CATCH
					PRINT ERROR_MESSAGE()
				END CATCH
			END
		END CATCH

		SET @Counter += 1
	END -- End of While-Loop

	FETCH NEXT FROM DBList_Cursor INTO @FileName
END

CLOSE DBList_Cursor
DEALLOCATE DBList_Cursor

--Create a global temporary table to store the results of the report table
IF EXISTS (SELECT 1 FROM tempdb.sys.tables WHERE name = '##InvalidBackupReport')
BEGIN
	DROP TABLE ##InvalidBackupReport
END

-- Store report results in a global temporary table
SELECT * 
INTO ##InvalidBackupReport
FROM @InvalidBackupReport


-- Display result of report table
PRINT CHAR(10) + 'THE FOLLOWING BACKUPS ARE UNUSABLE FOR DATABASE RESTORE' + CHAR(10)

SELECT * FROM ##InvalidBackupReport
ORDER BY 4, 1, 2

------------------------------------------------- CLEANUP ---------------------------------

--Delete dummy database

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = @DBName)
BEGIN
	-- Encryption Key and Certificate on dummy database if it exists
	IF EXISTS (SELECT 1 FROM sys.databases d
								JOIN sys.dm_database_encryption_keys dek
								ON DEK.database_id = d.database_id
								JOIN sys.certificates AS cer
								ON dek.encryptor_thumbprint = cer.thumbprint
								WHERE cer.name = @CertificateName
								AND d.name = @DBName
								AND encryption_state = 1)
	BEGIN
		SET @SQL =  'USE ' + @DBName + '
					DROP DATABASE ENCRYPTION KEY'

		EXECUTE (@SQL)
	END

	IF EXISTS (SELECT 1 FROM sys.certificates WHERE name = @CertificateName)
	BEGIN
		SET @SQL = 'DROP CERTIFICATE ' + @CertificateName
		EXECUTE (@SQL)
	END

	SET @SQL = 'DROP DATABASE ' + @DBName;

	EXECUTE(@SQL);
END
END
GO