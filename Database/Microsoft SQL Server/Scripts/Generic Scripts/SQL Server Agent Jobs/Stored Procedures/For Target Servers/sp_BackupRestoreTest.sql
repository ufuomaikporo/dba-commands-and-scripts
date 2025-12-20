USE DrasInternal
GO

/*
This stored procedure tests all the backup files in a specified location to see if they are valid for restores.
Information of the test is sent to the DrasInternal.dbo.DatabaseBackupInfo

*********************************** NOTES FOR RUNNING STORED PROC *************************************

1. MUST Run on the target server
2. A master server should be designated with the DrasInternal.dbo.DatabaseBackupInfo table already created 

*******************************************************************************************************

-- Sample execution 

DECLARE @BUfolder NVARCHAR(100) = '\\dras-dbbkp02\P_DB_Backups_Nightly\' + REPLACE(@@SERVERNAME, '\', '_') + '\Nightly\'
EXEC sp_BackupRestoreTest @BULocation = @BUfolder, @MasterServer = 'DRASSQL2022'

*/



IF OBJECT_ID('sp_BackupRestoreTest') IS NOT NULL
BEGIN
	DROP PROCEDURE sp_BackupRestoreTest
END
GO

CREATE PROCEDURE [dbo].[sp_BackupRestoreTest] @BULocation NVARCHAR(500), @MasterServer NVARCHAR(100)
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
	DECLARE @FailedRstrFilePosition INT
	DECLARE @LastBackup INT
	DECLARE @TargetServer NVARCHAR(100)

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
									 RecoveryForkId NVARCHAR(100),
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
									 DifferentialBaseLSN NUMERIC(30),
									 DifferentialBaseGUID NVARCHAR(100),
									 BackupTypeDescription NVARCHAR(50),
									 BackupSetGUID NVARCHAR(100),
									 CompressedBackupSize BIGINT,
									 Containment INT,	--SQL2012'

		IF CAST(SUBSTRING(@@VERSION, CHARINDEX('20', @@VERSION), 4) AS NUMERIC) >= 2014 AND 
		   CAST(SUBSTRING(@@VERSION, CHARINDEX('20', @@VERSION), 4) AS NUMERIC) <= 2019
		BEGIN
			SET @SQL += CHAR(10) + CHAR(9) + CHAR(9) + CHAR(9) + CHAR(9) +
			'				KeyAlgorithm NVARCHAR(100),
									EncryptorThumbprint NVARCHAR(100),
									EncryptorType NVARCHAR(100)			--SQL2014, SQL2016, SQL2017, SQL2019'

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

	SET @TargetServer = @@SERVERNAME

	---------------------------------- Get the list of files in the BULocation -------------------

	-- Create tables to store a list of the backup files
	IF OBJECT_ID ('tempdb.dbo.##BUDirFiles') IS NOT NULL
	BEGIN
		DROP TABLE dbo.##BUDirFiles
	END

	CREATE TABLE  dbo.##BUDirFiles (BUFileName NVARCHAR(255))


	-- Get the list of all files in the backup directory
	SET @SQL = 'INSERT INTO ##BUDirFiles (BUFileName)
				EXEC master..xp_cmdshell ''dir /b "' + @BULocation + '*.bak"''';

	EXECUTE (@SQL)

	DECLARE FileList_Cursor CURSOR FOR
	SELECT BUFileName FROM ##BUDirFiles

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
			AND DifferentialBaseGUID = (SELECT BackupSetGUID FROM ##BackupSetInfo
										WHERE Position = (SELECT MAX(Position) 
														  FROM ##BackupSetInfo startpt 
														  WHERE BackupType = 1)
										)
		END
		ELSE IF (SELECT BackupType FROM ##BackupSetInfo WHERE Position = @LastBackup) = 1
		BEGIN
			SET @LastValidBackup = @LastBackup
		END

		IF @LastValidBackup IS NULL
		BEGIN
			SET @LastValidBackup = @LastBackup - 1
		END

		BEGIN TRY
			EXECUTE('RESTORE VERIFYONLY FROM DISK = ''' + @BUFile +'''')
		END TRY
		BEGIN CATCH
			SET @LastValidBackup = NULL
		END CATCH

		IF @LastValidBackup <> @LastBackup OR @LastValidBackup IS NULL
		BEGIN
			PRINT 'Error Msg: The ' + @BUFile + ' file is invalid for backup restore' 
		END 

		SET @FailedRstrFilePosition = NULL

		SELECT @FailedRstrFilePosition = CASE WHEN @LastValidBackup IS NULL THEN @LastBackup 
											  WHEN @LastValidBackup <> @LastBackup THEN @LastValidBackup + 1
											  ELSE 0
										 END

		IF @FailedRstrFilePosition <> 0 
		BEGIN
			PRINT CHAR(10) + 'Failed Backupfile Postition: ' + CASE WHEN @FailedRstrFilePosition IS NULL
															THEN 'A valid Full backup could not be found on the backup media ' + @BUFile
															ELSE CAST(@FailedRstrFilePosition AS NVARCHAR) 
														END
			PRINT 'Last Valid Backup: ' + CASE WHEN @LastValidBackup IS NULL THEN 'No Valid backup found on the backup media ' + @BUFile
											ELSE CAST(@LastValidBackup AS NVARCHAR)
										END 
		END

		IF (@MasterServer = @TargetServer)
		BEGIN
			SET @SQL = 'IF NOT EXISTS (SELECT * FROM DrasInternal.dbo.DatabaseBackupInfo WHERE ServerName = ''' + @TargetServer + ''' AND DatabaseName = ''' + @DBName + ''' AND FileName = ''' + @FileName + ''')
						BEGIN
							INSERT INTO DrasInternal.dbo.DatabaseBackupInfo (ServerName,
																			DatabaseName,
																			FilePosition,
																			LastBackupType,
																			FileName,
																			FailedRstrFilePosition,
																			RestoreStatus,
																			RestoreTestDate,
																			LastBackupStartDate,
																			LastBackupFinishDate,
																			DaysSinceLastBackup)
							SELECT TOP 1 ''' + @TargetServer + ''', 
								DatabaseName, 
								Position,
								CASE WHEN tab2.BackupType = 1 THEN ''Database Full''
									 WHEN tab2.BackupType = 5 THEN ''Database Differential''
									 ELSE tab2.BackupTypeDescription
								END,
								''' + @FileName + ''',
								CASE WHEN ' + CAST(@FailedRstrFilePosition AS NVARCHAR) + ' = 0 THEN NULL
									 ELSE  ' + CAST(@FailedRstrFilePosition AS NVARCHAR) + '
								END,								
								CASE WHEN ' + CAST(@FailedRstrFilePosition AS NVARCHAR) + ' = 0 THEN ''VALID''
									 ELSE ''INVALID''
								END,
								GETDATE(),
								BackupStartDate,
								BackupFinishDate,
								ABS(DATEDIFF(DAY, BackupStartDate, GETDATE()))
							FROM ##BackupSetInfo tab2
							ORDER BY position DESC

						END
						ELSE 
						BEGIN
						    
							UPDATE DrasInternal.dbo.DatabaseBackupInfo
							SET FilePosition = tab2.Position,
								LastBackupType = CASE WHEN tab2.BackupType = 1 THEN ''Database Full''
												  WHEN tab2.BackupType = 5 THEN ''Database Differential''
												  ELSE tab2.BackupTypeDescription
											 END,
								FailedRstrFilePosition = CASE WHEN ' + CAST(@FailedRstrFilePosition AS NVARCHAR) + ' = 0 THEN NULL
															  ELSE ' + CAST(@FailedRstrFilePosition AS NVARCHAR) + '
														 END,
								RestoreStatus = CASE WHEN ' + CAST(@FailedRstrFilePosition AS NVARCHAR) + ' = 0 THEN ''VALID''
													 ELSE ''INVALID''
												END,
								RestoreTestDate = GETDATE(),
								LastBackupStartDate = tab2.BackupStartDate,
								LastBackupFinishDate = tab2.BackupFinishDate,
								DaysSinceLastBackup = ABS(DATEDIFF(DAY, tab2.BackupStartDate, GETDATE())),
								LastModByUserId = SUSER_SNAME()
							FROM DrasInternal.dbo.DatabaseBackupInfo tab1
							JOIN (SELECT TOP 1 * FROM ##BackupSetInfo ORDER BY Position DESC)  tab2
							ON tab1.DatabaseName = tab2.DatabaseName
							AND tab1.FileName = ''' + @FileName + '''
							AND tab1.ServerName = ''' + @TargetServer + '''
						END'

		END
		ELSE
		BEGIN
			SET @SQL = 'IF NOT EXISTS (SELECT * FROM ' + @MasterServer + '.DrasInternal.dbo.DatabaseBackupInfo WHERE ServerName = ''' + @TargetServer + ''' AND DatabaseName = ''' + @DBName + ''' AND FileName = ''' + @FileName + ''')
						BEGIN
							-- Store results in centralized location on ' + @MasterServer + ' server 
							INSERT OPENQUERY ([' + @MasterServer + '], ''SELECT ServerName,
																				DatabaseName,
																				FilePosition,
																				LastBackupType,
																				FileName,
																				FailedRstrFilePosition,
																				RestoreStatus,
																				LastBackupStartDate,
																				LastBackupFinishDate, 
																				RestoreTestDate,
																				DaysSinceLastBackup 
																			FROM DrasInternal.dbo.DatabaseBackupInfo'')  
							SELECT TOP 1 ''' + @TargetServer + ''', 
								DatabaseName, 
								Position,
								CASE WHEN tab2.BackupType = 1 THEN ''Database Full''
									 WHEN tab2.BackupType = 5 THEN ''Database Differential''
									 ELSE tab2.BackupTypeDescription
								END,
								''' + @FileName + ''',
								CASE WHEN ' + CAST(@FailedRstrFilePosition AS NVARCHAR) + ' = 0 THEN NULL
									 ELSE  ' + CAST(@FailedRstrFilePosition AS NVARCHAR) + '
								END,
								CASE WHEN ' + CAST(@FailedRstrFilePosition AS NVARCHAR) + ' = 0 THEN ''VALID''
									 ELSE ''INVALID''
								END,
								BackupStartDate,
								BackupFinishDate,
								GETDATE(),
								ABS(DATEDIFF(DAY, BackupStartDate, GETDATE()))
							FROM ##BackupSetInfo tab2
							ORDER BY position DESC
						END
						ELSE
						BEGIN
							UPDATE OPENQUERY ([' + @MasterServer + '], ''SELECT FilePosition,
																				LastBackupType,
																				FailedRstrFilePosition,
																				RestoreStatus,
																				LastBackupStartDate,
																				LastbackupFinishDate,
																				RestoreTestDate,
																				DaysSinceLastBackup,
																				LastModByUserId
																			FROM DrasInternal.dbo.DatabaseBackupInfo
																			WHERE FileName = ''''' + @FileName + ''''' 
																			AND ServerName = ''''' + @TargetServer + '''''
																			'') 
							SET FilePosition = tab2.Position,
								LastBackupType = CASE WHEN tab2.BackupType = 1 THEN ''Database Full''
												  WHEN tab2.BackupType = 5 THEN ''Database Differential''
												  ELSE tab2.BackupTypeDescription
											 END,
								FailedRstrFilePosition = CASE WHEN ' + CAST(@FailedRstrFilePosition AS NVARCHAR) + ' = 0 THEN NULL
															  ELSE ' + CAST(@FailedRstrFilePosition AS NVARCHAR) + '
														 END,
								RestoreStatus = CASE WHEN ' + CAST(@FailedRstrFilePosition AS NVARCHAR) + ' = 0 THEN ''VALID''
													 ELSE ''INVALID''
												END,
								LastBackupStartDate = tab2.BackupStartDate,
								LastBackupFinishDate = tab2.BackupFinishDate,
								RestoreTestDate = GETDATE(),
								DaysSinceLastBackup = ABS(DATEDIFF(DAY, tab2.BackupStartDate, GETDATE())),
								LastModByUserId = SUSER_SNAME()
							FROM (SELECT TOP 1 * FROM ##BackupSetInfo ORDER BY Position DESC) tab2

						END'
		END

		EXECUTE (@SQL)
		
		FETCH NEXT FROM FileList_Cursor INTO @FileName
	END

	CLOSE FileList_Cursor
	DEALLOCATE FileList_Cursor

END