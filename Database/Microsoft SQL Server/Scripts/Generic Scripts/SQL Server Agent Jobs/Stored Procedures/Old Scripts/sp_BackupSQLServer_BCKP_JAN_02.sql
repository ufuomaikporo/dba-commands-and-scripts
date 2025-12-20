USE DrasInternal
GO

/*

***REQUIREMENTS

------ 1) The following table must exists in the DrasInternal database on the master server

IF OBJECT_ID('dbo.DatabaseBackupInfo', 'U') IS NOT NULL
BEGIN
	DROP TABLE DrasInternal.dbo.DatabaseBackupInfo;
END
	
CREATE TABLE DrasInternal.dbo.DatabaseBackupInfo (ServerName NVARCHAR(100) NOT NULL,
								  DatabaseName NVARCHAR(100) NOT NULL,
								  FilePosition INT,
								  LastBackupType NVARCHAR(50),
								  FileName NVARCHAR(500),
								  RestoreStatus VARCHAR(8),
								  RestoreTestDate DATETIME,
								  FailedRstrFilePosition INT,
								  DaysSinceLastBackup INT,
								  LastBackupStartDate DATETIME,
								  LastBackupFinishDate DATETIME,
								  LastBackupMessage VARCHAR(4000),
								  CreatedUser NVARCHAR(40) DEFAULT SUSER_SNAME()
								  )

--- Example of stored procedure execution

EXEC sp_BackupSQLServer @MasterServer = 'DRASSQL2022'


*/

IF OBJECT_ID('sp_BackupSQLServer') IS NOT NULL
BEGIN
	DROP PROCEDURE sp_BackupSQLServer
END
GO
CREATE PROCEDURE [dbo].[sp_BackupSQLServer] @MasterServer NVARCHAR(100)
AS
BEGIN
	BEGIN TRY
		DECLARE @DBName NVARCHAR(100) 
		DECLARE @TargetServer NVARCHAR(100)
		DECLARE @BULocation NVARCHAR(500)
		DECLARE @WeeklyBULocation NVARCHAR(500)
		DECLARE @MonthlyBULocation NVARCHAR(500)
		DECLARE @SQL NVARCHAR(4000)
		DECLARE @HasInvalidBackup INT
		DECLARE @BUFile NVARCHAR(500) 
		DECLARE @ArchiveFile NVARCHAR(500)
		DECLARE @BUFilePath NVARCHAR(500)
		DECLARE @ArchiveFilePath NVARCHAR(500)
		DECLARE @WinrarExeFilePath NVARCHAR(500)
		DECLARE @FileExists INT
		DECLARE @FullbkpFile INT
		DECLARE @BackupPosition INT
		DECLARE @LastBackupType NVARCHAR(100)
		DECLARE @DBList NVARCHAR(MAX)
		DECLARE @LastValidBackup INT
		DECLARE @LastBackup INT
		DECLARE @CurrentDate DATETIME
		DECLARE @BackupStartDate DATETIME
		DECLARE @NextMonth DATETIME
		DECLARE @LastDayOfCurrentMonth DATETIME
		DECLARE @LastFridayOfMonth DATETIME
		DECLARE @FolderName NVARCHAR(100)

		SET @TargetServer = @@SERVERNAME
		SET @FolderName = REPLACE(@TargetServer, '\', '_')

		SET @BULocation = '\\dras-dbbkp02\P_DB_Backups_Nightly\' + @FolderName + '\Nightly\'
		SET @WeeklyBULocation = '\\dras-dbbkp02\P_DB_Backups_Weekly\' + @FolderName + '\Weekly\'
		SET @MonthlyBULocation = '\\dras-dbbkp02\P_DB_Backups_Monthly\' + @FolderName + '\Monthly\'
		SET @WinrarExeFilePath = 'C:\Program Files\WinRAR\Rar.exe'

		----------------------------------- Get date of Last Friday of Month ----------------------------------

		SET @CurrentDate = GETDATE()
		SET @NextMonth = FORMAT(DATEADD(MONTH, 1, @CurrentDate), 'yyyy-MM-01')
		SET @LastDayOfCurrentMonth = DATEADD(DAY, DATEDIFF(DAY, @CurrentDate, @NextMonth) - 1, @CurrentDate)

		SELECT @LastFridayOfMonth = CASE WHEN DATEPART(DW, @LastDayOfCurrentMonth) < 6
											THEN FORMAT(DATEADD(DAY, - DATEPART(DW, @LastDayOfCurrentMonth) - 1, @LastDayOfCurrentMonth), 'yyyy-MM-dd')
										ELSE FORMAT(DATEADD(DAY, 6 - DATEPART(DW, @LastDayOfCurrentMonth), @LastDayOfCurrentMonth), 'yyyy-MM-dd')
									END

		------------------------------------------- CREATE Tables ----------------------------------

		DECLARE @tbl TABLE (ErrorMessage NVARCHAR(4000))

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
											 DifferentialBaseLSN NUMERIC(30),
											 DifferentialBaseGUID NVARCHAR(100),
											 BackupTypeDescription NVARCHAR(50),
											 BackupSetGUID NVARCHAR(100),
											 CompressedBackupSize BIGINT,
											 Containment INT,	--SQL2014'

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

		-------------------------------------- Loop throw backup operation ------------

		IF FORMAT(@CurrentDate, 'yyyy-MM-dd') = FORMAT(@LastFridayOfMonth, 'yyyy-MM-dd')
		BEGIN
			DECLARE DBList_Cursor CURSOR FOR
			SELECT name FROM sys.databases
			WHERE database_id > 4 OR name IN ('master', 'msdb') 
			ORDER BY name
		END
		ELSE 
		BEGIN
			DECLARE DBList_Cursor CURSOR FOR
			SELECT name FROM sys.databases
			WHERE database_id > 4  
			AND name LIKE '%IRAS%' 
			ORDER BY name

		END


		OPEN DBList_Cursor
		FETCH NEXT FROM DBList_Cursor INTO @DBName

		WHILE @@FETCH_STATUS = 0
		BEGIN
			-- Set backup file name
			SET @BUFile = @DBName + '.bak'
			SET @BUFilePath = @BULocation + @BUFile

			-- Reset re-used variables
			SET @FileExists = NULL
			SET @HasInvalidBackup = NULL

			-- Check if a backup file already for a database 
			SET @SQL = 'SELECT @Result = 1 FROM ##BUDirFiles
			WHERE BUFileName = ''' + @BUFile + ''''

			EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @FileExists OUTPUT

			-- If a backup file exists for the database, check if the backup file is valid for restores
			IF @FileExists IS NOT NULL
			BEGIN
				TRUNCATE TABLE ##BackupSetInfo

				SET @SQL ='RESTORE HEADERONLY FROM DISK = '''+ @BUFilePath + ''''

				-- Backup backup SET header info in table
				INSERT INTO ##BackupSetInfo
				EXECUTE(@SQL)

				-- SET the name that the database will be restored as to the default name in the backup file if no name was entered by script user	
				SELECT @DBName = DatabaseName
				FROM ##BackupSetInfo;
	
				--Find the latest valid backup 
				SELECT @LastBackup = MAX(Position) 
				FROM ##BackupSetInfo

				-- Find the latest Full backup
				SELECT @FullbkpFile = MAX(Position)
				FROM ##BackupSetInfo
				WHERE BackupType = 1

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
					AND DifferentialBaseLSN = (SELECT DifferentialBaseLSN FROM ##BackupSetInfo WHERE Position = 2)

				END
				ELSE IF (SELECT BackupType FROM ##BackupSetInfo WHERE Position = @LastBackup) = 1
				BEGIN
					SET @LastValidBackup = @LastBackup
				END

				BEGIN TRY
					SET @SQL = 'RESTORE VERIFYONLY FROM DISK = ''' + @BUFilePath + ''''
					EXECUTE (@SQL)
				END TRY
				BEGIN CATCH
					SET @LastValidBackup = NULL
				END CATCH

				-- Return 1 if the last differential backup in th ebackup media is invalid for restores
				IF (@LastValidBackup != @LastBackup) 
				BEGIN
					SELECT @HasInvalidBackup =  1 
				END
				-- Return 2 if the backup media fails the validation test 'VERIFYONLY' 
				ELSE IF (@LastValidBackup IS NULL OR @FullbkpFile IS NULL)
				BEGIN
					SELECT @HasInvalidBackup = 2  
				END
				ELSE
				-- Return 0 if the last backup on the backup media is valid for restores
				BEGIN
					SELECT @HasInvalidBackup = 0  
				END

			END

			------------------ Store info on db backup operation in a report table on the DrasInternal database ----

			-- If there are no entries in the DrasInternal.dbo.DatabaseBackupInfo table for the backup file, add an entry
			IF @MasterServer = @@SERVERNAME
			BEGIN
				SET @SQL = 'IF NOT EXISTS (SELECT * FROM DrasInternal.dbo.DatabaseBackupInfo WHERE ServerName = @@SERVERNAME AND DatabaseName = ''' + @DBName + ''' AND FileName = ''' + @BUFile + ''')
							BEGIN
								INSERT INTO DrasInternal.dbo.DatabaseBackupInfo (ServerName, 
																				DatabaseName, 
																				FileName, 
																				FilePosition,
																				LastBackupType,
																				DaysSinceLastBackup,
																				LastBackupStartDate,
																				LastBackupFinishDate)
								SELECT TOP 1 @@SERVERNAME, 
										''' + @DBName + ''', 
										''' + @BUFile + ''', 
										Position,
										CASE WHEN BackupType = 1 THEN ''Database Full''
											 WHEN BackupType = 5 THEN ''Database Differential''
											 ELSE BackupTypeDescription
										END,
										ABS(DATEDIFF(DAY, BackupStartDate, GETDATE())),
										BackupStartDate,
										BackupFinishDate
								FROM ##BackupSetInfo
								ORDER BY Position DESC
							END
							ELSE
							BEGIN
								UPDATE DrasInternal.dbo.DatabaseBackupInfo
								SET LastBackupStartDate = tab2.BackupStartDate,
									LastBackupFinishDate = tab2.BackupFinishDate,
									LastBackupType = CASE WHEN tab2.BackupType = 1 THEN ''Database Full''
														WHEN tab2.BackupType = 5 THEN ''Database Differential''
														ELSE tab2.BackupTypeDescription
													 END,
									DaysSinceLastBackup = ABS(DATEDIFF(DAY, tab2.BackupStartDate, GETDATE())),
									FilePosition = tab2.Position
								FROM DrasInternal.dbo.DatabaseBackupInfo tab1
								JOIN (SELECT TOP 1 * FROM ##BackupSetInfo ORDER BY Position DESC)  tab2
								ON tab1.DatabaseName = ''' + @DBName + '''
								AND FileName = ''' + @BUFile + '''
								AND tab1.ServerName = ''' + @TargetServer + '''
							END'
			
			END
			ELSE
			BEGIN
				SET @SQL = 'IF NOT EXISTS (SELECT * FROM ' + @MasterServer + '.DrasInternal.dbo.DatabaseBackupInfo WHERE ServerName = @@SERVERNAME AND DatabaseName = ''' + @DBName + ''' AND FileName = ''' + @BUFile + ''')
							BEGIN
								INSERT OPENQUERY([' + @MasterServer + '], ''SELECT ServerName, 
																				   DatabaseName, 
																				   FileName, 
																				   FilePosition,
																				   LastBackupType,
																				   DaysSinceLastBackup,
																			       LastBackupStartDate,
																				   LastBackupFinishDate
																			FROM DrasInternal.dbo.DatabaseBackupInfo'')
								SELECT TOP 1 @@SERVERNAME, 
										''' + @DBName + ''', 
										''' + @BUFile + ''', 
										Position,
										CASE WHEN BackupType = 1 THEN ''Database Full''
											 WHEN BackupType = 5 THEN ''Database Differential''
											 ELSE BackupTypeDescription
										END,
										DATEDIFF(DAY, GETDATE(), BackupStartDate),
										BackupStartDate,
										BackupFinishDate
								FROM ##BackupSetInfo
								ORDER BY Position DESC
							END
							ELSE 
							BEGIN
								UPDATE OPENQUERY ([' + @MasterServer + '], ''SELECT LastBackupStartDate,
																					LastBackupFinishDate,
																					LastBackupType,
																					FilePosition,
																					DaysSinceLastBackup
																			FROM DrasInternal.dbo.DatabaseBackupInfo
																			WHERE DatabaseName = ''''' + @DBName + '''''
																			AND FileName = ''''' + @BUFile + '''''
																			AND ServerName = ''''' + @TargetServer + ''''''') 
									SET LastBackupStartDate = tab2.BackupStartDate,
										LastBackupFinishDate = tab2.BackupFinishDate,
										LastBackupType = (SELECT CASE WHEN tab2.BackupType = 1 THEN ''Database Full''
															WHEN tab2.BackupType = 5 THEN ''Database Differential''
															ELSE tab2.BackupTypeDescription
													END),
										FilePosition = tab2.Position,
										DaysSinceLastBackup = DATEDIFF(DAY, GETDATE(), tab2.BackupStartDate)
									FROM (SELECT * FROM OPENQUERY([' + @MasterServer + '], ''SELECT * FROM DrasInternal.dbo.DatabaseBackupInfo'')) AS tab1
									JOIN (SELECT TOP 1 * FROM ##BackupSetInfo ORDER BY Position DESC)  tab2
									ON tab1.DatabaseName = ''' + @DBName + '''
									AND tab1.FileName = ''' + @BUFile + '''
									AND tab1.ServerName = ''' + @TargetServer + '''
							END'
			END

			EXECUTE (@SQL)

			SET @BackupStartDate = GETDATE()

			-- Perform FULL database backup on a newly formated media if a backup file does not exists or if it'sa sunday night
			IF @FileExists IS NULL OR (DATEPART(DW, @CurrentDate) = 1 AND DATEPART(HOUR, @CurrentDate) >= 21)
			BEGIN
				PRINT 'Performing a FULL database backup of ' + @DBName 

				SET @SQL = 'BACKUP DATABASE ' + QUOTENAME(@DBName) + '   
				TO DISK = ''' + @BUFilePath + '''   
				WITH FORMAT,  
				INIT, 
				SKIP, 
				NAME = ''' + @DBName + ' Backupset'', 
				DESCRIPTION = ''' + @DBName + ' Full Backup'', 
				COMPRESSION,
				CHECKSUM;'

				SET @LastBackupType = 'Database Full'

			END
			-- Append FULL backup to existing backup media if a backup file exists but is invalid for restores
			ELSE IF @HasInvalidBackup <> 0 
			BEGIN
				PRINT 'Appending a FULL database backup of ' + @DBName + ' to an existing backup media'

				SET @SQL = 'BACKUP DATABASE ' + QUOTENAME(@DBName) + '   
				TO DISK = ''' + @BUFilePath + '''   
				WITH NOFORMAT, 
				SKIP, 
				NAME = ''' + @DBName + ' Backupset'', 
				DESCRIPTION = ''' + @DBName + ' Full Backup'', 
				COMPRESSION,
				CHECKSUM;'

				SET @LastBackupType = 'Database Full'
			
			END
			-- Otherwise perform a differential backup
			ELSE
			BEGIN
				PRINT 'Performing a DIFFERENTIAL database backup of ' + @DBName

				SET @SQL = 'BACKUP DATABASE ' + QUOTENAME(@DBName) + '   
				TO DISK = ''' + @BUFilePath + '''
				WITH DIFFERENTIAL, 
				NAME = ''' + @DBName + ' Backupset'', 
				DESCRIPTION = ''' + @DBName + ' Differential Backup'', 
				COMPRESSION,  
				CHECKSUM;'

				SET @LastBackupType = 'Database Differential'

			END

			EXECUTE (@SQL)

			-- Update table in DrasInternal if backup is successful
			IF @MasterServer = @@SERVERNAME
			BEGIN
				IF @FileExists = 1 
				BEGIN
					SET @SQL = 'UPDATE DrasInternal.dbo.DatabaseBackupInfo 
								SET LastBackupStartDate = ''' + CAST(@BackupStartDate AS NVARCHAR) + ''',
									LastBackupFinishDate = GETDATE(),
									FilePosition = tab2.Position + 1,									
									LastBackupType = ''' + @LastBackupType + ''',
									DaysSinceLastBackup = 0,
									LastBackupMessage = ''SUCCESSFUL''
								FROM DrasInternal.dbo.DatabaseBackupInfo tab1
								JOIN (SELECT TOP 1 * FROM ##BackupSetInfo ORDER BY Position DESC)  tab2
								ON tab1.ServerName = ''' + @TargetServer + '''
								AND tab1.DatabaseName = ''' + @DBName + '''
								AND tab1.FileName = ''' + @BUFile + ''''
				END
				ELSE 
				BEGIN
					SET @SQL = 'UPDATE DrasInternal.dbo.DatabaseBackupInfo 
								SET LastBackupStartDate = ''' + CAST(@BackupStartDate AS NVARCHAR) + ''',
									LastBackupFinishDate = GETDATE(),
									FilePosition = 1,								
									LastBackupType = ''' + @LastBackupType + ''',
									DaysSinceLastBackup = 0,
									LastBackupMessage = ''SUCCESSFUL''
								WHERE ServerName = ''' + @TargetServer + '''
								AND DatabaseName = ''' + @DBName + '''
								AND FileName = ''' + @BUFile + ''''

				END
			END
			ELSE
			BEGIN
				IF @FileExists = 1 
				BEGIN
					SET @SQL = 'UPDATE OPENQUERY([' + @MasterServer + '], ''SELECT LastBackupStartDate,
																				 LastBackupFinishDate,
																				 FilePosition,
																				 LastBackupType,
																				 DaysSinceLastBackup,
																				 LastBackupMessage
																			 FROM DrasInternal.dbo.DatabaseBackupInfo
																			 WHERE ServerName = ''''' + @TargetServer + '''''
																				AND DatabaseName = ''''' + @DBName + '''''
																				AND FileName = ''''' + @BUFile + ''''''')
						SET LastBackupStartDate = ''' + CAST(@BackupStartDate AS NVARCHAR) + ''',
							LastBackupFinishDate = GETDATE(),
							FilePosition =  tab2.Position + 1,
							LastBackupType = ''' + @LastBackupType + ''',
							DaysSinceLastBackup = 0,
							LastBackupMessage = ''SUCCESSFUL''
						FROM (SELECT * FROM OPENQUERY([' + @MasterServer + '], ''SELECT * FROM DrasInternal.dbo.DatabaseBackupInfo'')) AS tab1
						JOIN (SELECT TOP 1 * FROM ##BackupSetInfo ORDER BY Position DESC) tab2
						ON tab1.ServerName = ''' + @TargetServer + '''
						AND tab1.DatabaseName = ''' + @DBName + '''
						AND tab1.FileName = ''' + @BUFile + ''''
				END
				ELSE
				BEGIN
					SET @SQL = 'UPDATE OPENQUERY([' + @MasterServer + '], ''SELECT LastBackupStartDate,
																				   LastBackupFinishDate,
																				   FilePosition,
																				   LastBackupType,
																				   DaysSinceLastBackup,
																				   LastBackupMessage
																			FROM DrasInternal.dbo.DatabaseBackupInfo
																			WHERE ServerName = ''''' + @TargetServer + '''''
																				AND DatabaseName = ''''' + @DBName + '''''
																				AND FileName = ''''' + @BUFile + '''''''
												)
								SET LastBackupStartDate = ''' + CAST(@BackupStartDate AS NVARCHAR) + ''',
									LastBackupFinishDate = GETDATE(),
									FilePosition = 1,								
									LastBackupType = ''' + @LastBackupType + ''',
									DaysSinceLastBackup = 0,
									LastBackupMessage = ''SUCCESSFUL''
								FROM (SELECT * FROM OPENQUERY([' + @MasterServer + '], ''SELECT * FROM DrasInternal.dbo.DatabaseBackupInfo'')) AS tab1
								WHERE tab1.ServerName = ''' + @TargetServer + '''
								AND tab1.DatabaseName = ''' + @DBName + '''
								AND tab1.FileName = ''' + @BUFile + ''''
				END
			END

			EXECUTE (@SQL)

			-------------------------------- Move Backups to Weekly Folder on Fridays ----------------------
	
			SET @ArchiveFile = @DBName + '.rar'
			SET @ArchiveFilePath = @WeeklyBULocation + @ArchiveFile

			-- Compress backups into a winrar zip file and move to the weekkly backup location
			IF DATEPART(DW, @CurrentDate) = 6 AND DATEPART(HOUR, @CurrentDate) >= 21 AND @FileExists IS NOT NULL
			BEGIN
				PRINT + CHAR(10) + 'Creating Weekly Archive File for ' + @DBName + ' backups.'

				SET @SQL = '""' + @WinrarExeFilePath + '" u -ep -ibck -df -y "' + @ArchiveFilePath +'" "' + @BUFilePath + '""'
				EXECUTE master.dbo.xp_cmdshell @SQL
			END

			------------------------------- Move backups to the monthly --------------------------------------

			-- Get list of files in the weekly backup folder
			SET @SQL = 'INSERT INTO ##BUDirFiles (BUFileName)
					EXEC master..xp_cmdshell ''dir /b "' + @WeeklyBULocation + '*.rar"''';

			EXECUTE (@SQL)

			SET @FileExists = NULL

			-- Check if the archive file exists in the weekly backup location
			SET @SQL = 'SELECT @Result = 1 FROM ##BUDirFiles
			WHERE BUFileName = ''' + @ArchiveFile + ''''

			EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @FileExists OUTPUT

			-- Move the compressed zip files from the weekly folder to the monthly folder on the last Friday of the month
			IF FORMAT(@CurrentDate, 'yyyy-MM-dd') = FORMAT(@LastFridayOfMonth, 'yyyy-MM-dd') AND DATEPART(HOUR, @CurrentDate) >= 21
				AND @FileExists IS NOT NULL
			BEGIN
				
				PRINT + CHAR(10) + 'Moving weekly archive file for ' + @DBName + ' to the monthly backup location'

				-- Move the Winrar zip file from the weekly backup location to the monthly backup location
				SET @SQL = 'MOVE "' + @ArchiveFilePath + '" "' + @MonthlyBULocation + @ArchiveFile + '"'
				EXECUTE master.dbo.xp_cmdshell @SQL

				-- Delete the Winrar zip file from the weekly backup location
				SET @SQL = 'DEL "' + @ArchiveFilePath + '"'
				EXECUTE master.dbo.xp_cmdshell @SQL

			END


			FETCH NEXT FROM DBList_Cursor INTO @DBName

		END

		CLOSE DBList_Cursor
		DEALLOCATE DBList_Cursor
	END TRY
	BEGIN CATCH
		INSERT INTO @tbl
		EXECUTE ('DBCC OUTPUTBUFFER(@@spid)')
		select * from @tbl
		-- Store error messsage in the report table 
		IF @MasterServer = @@SERVERNAME
		BEGIN
			SET @SQL = 'UPDATE DrasInternal.dbo.DatabaseBackupInfo 
			SET LastBackupMessage = ''Error Message for DB Backup on '' + CAST(GETDATE() AS NVARCHAR) + '': '' + ERROR_MESSAGE()
				--,LastBackupStartDate = tab2.BackupStartDate
			FROM DrasInternal.dbo.DatabaseBackupInfo tab1
			JOIN (SELECT TOP 1 * FROM ##BackupSetInfo ORDER BY Position DESC) tab2
			ON tab1.ServerName = ''' + @TargetServer + '''
			AND tab1.DatabaseName = ''' + @DBName + '''
			AND tab1.FileName = ''' + @BUFile + ''''
		END
		ELSE
		BEGIN
			SET @SQL = 'UPDATE OPENQUERY([' + @MasterServer + '], ''SELECT LastBackupMessage FROM DrasInternal.dbo.DatabaseBackupInfo'')
			SET LastBackupMessage = ''Error Message for DB Backup on '' + CAST(GETDATE() AS NVARCHAR) + '': '' + ERROR_MESSAGE()
				--,LastBackupStartDate = tab2.BackupStartDate
			FROM (SELECT * FROM OPENQUERY([' + @MasterServer + '], ''SELECT * FROM DrasInternal.dbo.DatabaseBackupInfo'')) AS tab1
			JOIN (SELECT TOP 1 * FROM ##BackupSetInfo ORDER BY Position DESC) tab2
			ON tab1.ServerName = ''' + @TargetServer + '''
			AND tab1.DatabaseName = ''' + @DBName + '''
			AND tab1.FileName = ''' + @BUFile + ''''
		END;

		EXECUTE (@SQL);

		THROW
	END CATCH
END
