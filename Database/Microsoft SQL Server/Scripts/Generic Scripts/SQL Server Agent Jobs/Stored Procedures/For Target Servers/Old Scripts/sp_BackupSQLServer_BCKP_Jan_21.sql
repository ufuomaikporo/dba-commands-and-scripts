USE DrasInternal
GO

/*

***REQUIREMENTS

------ 1) The following tables must exists in the DrasInternal database on the master server

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
								  LastModByUserId NVARCHAR(40) DEFAULT SUSER_SNAME()
								  )

--- Example of stored procedure execution

EXECUTE dbo.sp_BackupSQLServer @MasterServer = DRASSQL2022,  @BULocation = NULL, 
@WeeklyBULocation = NULL, @MonthlyBULocation = NULL

*/

IF OBJECT_ID('sp_BackupSQLServer') IS NOT NULL
BEGIN
	DROP PROCEDURE sp_BackupSQLServer
END
GO

CREATE PROCEDURE [dbo].[sp_BackupSQLServer] @MasterServer NVARCHAR(100), @BULocation NVARCHAR(500), 
										@WeeklyBULocation NVARCHAR(500), @MonthlyBULocation NVARCHAR(500)
AS
BEGIN
	BEGIN TRY
		DECLARE @DBName NVARCHAR(100) 
		DECLARE @TargetServer NVARCHAR(100)
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
		DECLARE @BackupStartTime DATETIME
		DECLARE @NextMonth DATETIME
		DECLARE @LastDayOfCurrentMonth DATETIME
		DECLARE @LastFridayOfMonth DATETIME
		DECLARE @FolderName NVARCHAR(100)
		DECLARE @BackupCmd NVARCHAR(MAX)
		DECLARE @ScriptStartTime DATETIME
		DECLARE @ErrMsg NVARCHAR(MAX)
		DECLARE @BackupExpiry DATETIME

		SET @TargetServer = @@SERVERNAME
		SET @FolderName = REPLACE(@TargetServer, '\', '_')
		SET @ScriptStartTime = GETDATE()

		IF (SELECT DEFAULT_DOMAIN()[DomainName]) IN ('EDDYFINDT', 'DRASCITRIX')
		BEGIN
			SET @BULocation = '\\dras-dbbkp02\P_DB_Backups_Nightly\' + @FolderName + '\Nightly\'
			SET @WeeklyBULocation = '\\dras-dbbkp02\P_DB_Backups_Weekly\' + @FolderName + '\Weekly\'
			SET @MonthlyBULocation = '\\dras-dbbkp02\P_DB_Backups_Monthly\' + @FolderName + '\Monthly\'
		END

		SET @WinrarExeFilePath = 'C:\Program Files\WinRAR\Rar.exe'

		
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

		----------------------------------- Get date of Last Friday of Month ----------------------------------

		SET @CurrentDate = GETDATE()
		SET @BackupExpiry = DATEADD(MONTH, -2, GETDATE())	/* Backups older than this date will be deleted */
		SET @NextMonth = FORMAT(DATEADD(MONTH, 1, @CurrentDate), 'yyyy-MM-01')
		SET @LastDayOfCurrentMonth = DATEADD(DAY, DATEDIFF(DAY, @CurrentDate, @NextMonth) - 1, @CurrentDate)

		SELECT @LastFridayOfMonth = CASE WHEN DATEPART(DW, @LastDayOfCurrentMonth) < 6
											THEN FORMAT(DATEADD(DAY, - DATEPART(DW, @LastDayOfCurrentMonth) - 1, @LastDayOfCurrentMonth), 'yyyy-MM-dd')
										ELSE FORMAT(DATEADD(DAY, 6 - DATEPART(DW, @LastDayOfCurrentMonth), @LastDayOfCurrentMonth), 'yyyy-MM-dd')
									END

		------------------------------------------- CREATE Tables ----------------------------------

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

		DECLARE @CheckTable TABLE (Value INT)

		---------------------------------- Create Backup folders -------------------

		DECLARE @Void TABLE (Output NVARCHAR(MAX))
		
		-- Create the backup directories if it does not exists
		SET @SQL = 'EXEC master..xp_cmdshell ''IF NOT EXIST "' + @BULocation + '" mkdir  "' + @BULocation + '"'''
		
		INSERT INTO @Void
		EXECUTE (@SQL)

		SET @SQL = 'EXEC master..xp_cmdshell ''IF NOT EXIST "' + @WeeklyBULocation + '" mkdir  "' + @WeeklyBULocation + '"'''

		INSERT INTO @Void
		EXECUTE (@SQL)

		SET @SQL = 'EXEC master..xp_cmdshell ''IF NOT EXIST "' + @MonthlyBULocation + '" mkdir  "' + @MonthlyBULocation + '"'''

		INSERT INTO @Void
		EXECUTE (@SQL)

		-------------------------------------- Loop throw backup operation ------------

		IF FORMAT(@CurrentDate, 'yyyy-MM-dd') = FORMAT(@LastFridayOfMonth, 'yyyy-MM-dd')
			AND DATEPART(HOUR, @CurrentDate) >= 21
		BEGIN
			DECLARE DBList_Cursor CURSOR FOR
			SELECT name FROM sys.databases
			WHERE state_desc = 'ONLINE'
			AND name <> 'tempdb'
			ORDER BY name
		END
		ELSE 
		BEGIN
			DECLARE DBList_Cursor CURSOR FOR
			SELECT name FROM sys.databases
			WHERE database_id > 4  
			AND state_desc = 'ONLINE'
			AND name LIKE '%IRAS%'
			ORDER BY name
		END

		OPEN DBList_Cursor
		FETCH NEXT FROM DBList_Cursor INTO @DBName

		WHILE @@FETCH_STATUS = 0
		BEGIN
				
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

			EXECUTE(@SQL)


			-- Set backup file name
			SET @BUFile = @DBName + '.bak'
			SET @BUFilePath = @BULocation + @BUFile

			-- Reset re-used variables
			SET @FileExists = NULL
			SET @HasInvalidBackup = NULL
			TRUNCATE TABLE ##BackupSetInfo

			---------------------------- Check the backup file already exists -------------------

			DELETE FROM @CheckTable
			SET @FileExists = NULL

			SET @BUFilePath = @BULocation + @BUFile

			SET @SQL = 'EXECUTE master..xp_cmdshell ''IF EXIST "' + @BUFilePath + '" ECHO 1'''

			INSERT INTO @CheckTable
			EXECUTE (@SQL)

			SELECT @FileExists = Value FROM @CheckTable WHERE Value IS NOT NULL

			-- If a backup file exists for the database, check if the backup file is valid for restores
			IF @FileExists IS NOT NULL
			BEGIN

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
					SET @SQL = 'SELECT @LastValidBackup = MAX(Position)
								FROM ##BackupSetInfo
								WHERE BackupType = 5
								AND DifferentialBaseGUID = (SELECT BackupSetGUID FROM ##BackupSetInfo
															WHERE Position = (SELECT MAX(Position) 
																			  FROM ##BackupSetInfo startpt 
																			  WHERE BackupType = 1)
															)'

					EXECUTE sp_executesql @SQL, N'@LastValidBackup INT OUTPUT', @LastValidBackup OUTPUT
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
				-- Return 2 if the backup media fails the validation 'VERIFYONLY' check or if no Differential backup GUID match the Base full backup GUID
				ELSE IF (@LastValidBackup IS NULL)
				BEGIN
					SELECT @HasInvalidBackup = 2  
				END
				ELSE
				-- Return 0 if the last backup on the backup media is valid for restores
				BEGIN
					SELECT @HasInvalidBackup = 0  
				END

			END

			IF @LastBackup IS NULL
			BEGIN
				SET @LastBackup = 0
			END

			------------------ Store info on db backup operation in a report table on the DrasInternal database ----

			-- If there are no entries in the DrasInternal.dbo.DatabaseBackupInfo table for the backup file, add an entry
			IF @MasterServer = @@SERVERNAME 
			BEGIN
				SET @SQL = 'IF NOT EXISTS (SELECT * FROM DrasInternal.dbo.DatabaseBackupInfo WHERE ServerName = ''' + @TargetServer + ''' AND DatabaseName = ''' + @DBName + ''')
							BEGIN
								INSERT INTO DrasInternal.dbo.DatabaseBackupInfo (ServerName, 
																				DatabaseName, 
																				FileName, 
																				FilePosition,
																				LastBackupType,
																				DaysSinceLastBackup,
																				LastBackupStartDate,
																				LastBackupFinishDate)
								SELECT TOP 1 ''' + @TargetServer + ''', 
										''' + @DBName + ''', 
										''' + @BUFile + ''', 
										CASE WHEN tab2.Position IS NULL THEN 1
											 ELSE tab2.Position + 1									
										END,
										CASE WHEN BackupType = 1 OR BackupType IS NULL THEN ''Database Full''
											 WHEN BackupType = 5 THEN ''Database Differential''
											 ELSE BackupTypeDescription
										END,
										DATEDIFF(DAY, BackupStartDate, GETDATE()),
										CASE WHEN BackupStartDate IS NULL THEN GETDATE()
											 ELSE BackupStartDate
										END,
										BackupFinishDate
								FROM sys.databases tab1
								LEFT JOIN (SELECT TOP 1 * FROM ##BackupSetInfo ORDER BY Position DESC)  tab2
								ON tab1.name = tab2.DatabaseName
								AND tab2.ServerName = ''' + @TargetServer + '''
							END
							ELSE
							BEGIN
								UPDATE DrasInternal.dbo.DatabaseBackupInfo
								SET LastBackupStartDate = CASE WHEN tab2.BackupStartDate IS NULL THEN GETDATE()
															   ELSE tab2.BackupStartDate
														  END,
									LastBackupFinishDate = tab2.BackupFinishDate,
									LastBackupType = CASE WHEN tab2.BackupType = 1 OR tab2.BackupType IS NULL THEN ''Database Full''
														WHEN tab2.BackupType = 5 THEN ''Database Differential''
														ELSE tab2.BackupTypeDescription
													 END,
									DaysSinceLastBackup = DATEDIFF(DAY, tab2.BackupStartDate, GETDATE()),
									FilePosition = CASE WHEN tab2.Position IS NULL THEN 1
														ELSE tab2.Position
													END,
									LastBackupMessage = NULL
								FROM DrasInternal.dbo.DatabaseBackupInfo tab1
								LEFT JOIN (SELECT TOP 1 * FROM ##BackupSetInfo ORDER BY Position DESC)  tab2
									ON tab1.DatabaseName = tab2.DatabaseName
									AND tab1.ServerName = tab2.ServerName
								WHERE tab1.DatabaseName = ''' + @DBName + '''
								AND tab1.ServerName = ''' + @TargetServer + '''
							END'
			
			END
			ELSE 
			BEGIN
				SET @SQL = 'IF NOT EXISTS (SELECT * FROM ' + @MasterServer + '.DrasInternal.dbo.DatabaseBackupInfo WHERE ServerName = ''' + @TargetServer + ''' AND DatabaseName = ''' + @DBName + ''')
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
											CASE WHEN tab2.Position IS NULL THEN 1
											 ELSE tab2.Position + 1
										END,
										CASE WHEN BackupType = 1 OR BackupType IS NULL THEN ''Database Full''
											 WHEN BackupType = 5 THEN ''Database Differential''
											 ELSE BackupTypeDescription
										END,
										DATEDIFF(DAY, BackupStartDate, GETDATE()),
										CASE WHEN BackupStartDate IS NULL THEN GETDATE()
											 ELSE BackupStartDate
										END,
										BackupFinishDate
								FROM sys.databases tab1
								LEFT JOIN (SELECT TOP 1 * FROM ##BackupSetInfo ORDER BY Position DESC)  tab2
								ON tab1.name = tab2.DatabaseName
								AND tab2.ServerName = ''' + @TargetServer + '''
							END
							ELSE 
							BEGIN
								UPDATE OPENQUERY ([' + @MasterServer + '], ''SELECT LastBackupStartDate,
																					LastBackupFinishDate,
																					LastBackupType,
																					FilePosition,
																					DaysSinceLastBackup,
																					LastBackupMessage
																			FROM DrasInternal.dbo.DatabaseBackupInfo
																			WHERE DatabaseName = ''''' + @DBName + '''''
																			AND ServerName = ''''' + @TargetServer + ''''''') 
									SET LastBackupStartDate = CASE WHEN tab2.BackupStartDate IS NULL THEN GETDATE()
																	ELSE tab2.BackupStartDate
																END,
										LastBackupFinishDate = tab2.BackupFinishDate,
										LastBackupType = CASE WHEN tab2.BackupType = 1 OR tab2.BackupType IS NULL THEN ''Database Full''
															WHEN tab2.BackupType = 5 THEN ''Database Differential''
															ELSE tab2.BackupTypeDescription
														 END,
										FilePosition = CASE WHEN tab2.Position IS NULL THEN 1
															ELSE tab2.Position
														END,
										DaysSinceLastBackup = DATEDIFF(DAY, tab2.BackupStartDate, GETDATE()),
										LastBackupMessage = NULL
									FROM sys.databases AS tab1
									LEFT JOIN (SELECT TOP 1 * FROM ##BackupSetInfo ORDER BY Position DESC)  tab2
										ON tab1.name = tab2.DatabaseName
							END'
			END

			EXECUTE (@SQL)

			SET @BackupStartTime = GETDATE()

			---------------------------------- PERFORM BACKUPS ----------------------------------

			-- Perform FULL database backup on a newly formated media if a backup file does not exists or if it's a sunday night
			IF @FileExists IS NULL OR (DATEPART(DW, @CurrentDate) = 1 AND DATEPART(HOUR, @CurrentDate) >= 21)
				OR @DBName NOT LIKE '%IRAS%'
			BEGIN
				--PRINT 'Performing a FULL database backup of ' + @DBName 

				SET @BackupCmd = 'BACKUP DATABASE ' + QUOTENAME(@DBName) + '   
				TO DISK = ''' + @BUFilePath + '''   
				WITH FORMAT,  
				INIT, 
				SKIP, 
				NAME = ''' + @DBName + ' Backupset'', 
				DESCRIPTION = ''' + @DBName + ' Full Backup'', 
				COMPRESSION,
				CHECKSUM;'

				SET @LastBackupType = 'Full Backup 1'

			END
			-- Append FULL backup to existing backup media if a backup file exists but is invalid for restores
			ELSE IF @HasInvalidBackup <> 0 
			BEGIN
				--PRINT 'Appending a FULL database backup of ' + @DBName + ' to an existing backup media'

				SET @BackupCmd = 'BACKUP DATABASE ' + QUOTENAME(@DBName) + '   
				TO DISK = ''' + @BUFilePath + '''   
				WITH NOFORMAT, 
				SKIP, 
				NAME = ''' + @DBName + ' Backupset'', 
				DESCRIPTION = ''' + @DBName + ' Full Backup'', 
				COMPRESSION,
				CHECKSUM;'

				SET @LastBackupType = 'Full Backup 2'
			
			END
			-- Otherwise perform a differential backup
			ELSE
			BEGIN
				--PRINT 'Performing a DIFFERENTIAL database backup of ' + @DBName

				SET @BackupCmd = 'BACKUP DATABASE ' + QUOTENAME(@DBName) + '   
				TO DISK = ''' + @BUFilePath + '''
				WITH DIFFERENTIAL, 
				NAME = ''' + @DBName + ' Backupset'', 
				DESCRIPTION = ''' + @DBName + ' Differential Backup'', 
				COMPRESSION,  
				CHECKSUM;'

				SET @LastBackupType = 'Differential Backup'

			END

			-- Execute backup command
			BEGIN TRY

				EXECUTE (@BackupCmd)

				-- Update table in DrasInternal if backup is successful
				IF @MasterServer = @@SERVERNAME 
				BEGIN

					SET @SQL = 'UPDATE DrasInternal.dbo.DatabaseBackupInfo 
								SET LastBackupStartDate = ''' + CAST(@BackupStartTime AS NVARCHAR) + ''',
									LastBackupFinishDate = GETDATE(),
									FilePosition =  CASE WHEN ''' + @LastBackupType + ''' LIKE ''%Full%1%'' THEN 1
														 ELSE tab2.Position + 1
													END,									
									LastBackupType = ''' + CASE WHEN @LastBackupType LIKE '%FULL%' THEN 'Full Backup'
															ELSE @LastBackupType
															END + ''',
									DaysSinceLastBackup = 0,
									LastBackupMessage = ''Successful Backup'',
									RestoreStatus = NULL,
									RestoreTestDate = NULL
								FROM DrasInternal.dbo.DatabaseBackupInfo  tab1
								LEFT JOIN (SELECT TOP 1 * FROM ##BackupSetInfo ORDER BY Position DESC)  tab2
									ON tab1.ServerName = tab2.ServerName
									AND tab1.DatabaseName = tab2.DatabaseName
								WHERE tab1.ServerName = ''' + @TargetServer + '''
								AND tab1.DatabaseName = ''' + @DBName + ''''

				END
				ELSE 
				BEGIN
				
					SET @SQL = 'UPDATE OPENQUERY([' + @MasterServer + '], ''SELECT LastBackupStartDate,
																					LastBackupFinishDate,
																					FilePosition,
																					LastBackupType,
																					DaysSinceLastBackup,
																					LastBackupMessage,
																					RestoreStatus,
																					RestoreTestDate
																				FROM DrasInternal.dbo.DatabaseBackupInfo
																				WHERE ServerName = ''''' + @TargetServer + '''''
																				AND DatabaseName = ''''' + @DBName + '''''
																				'')
						SET LastBackupStartDate = ''' + CAST(@BackupStartTime AS NVARCHAR) + ''',
							LastBackupFinishDate = GETDATE(),
							FilePosition =  CASE WHEN ''' + @LastBackupType + ''' LIKE ''%Full%1%'' THEN 1
														 ELSE tab2.Position + 1
													END,									
									LastBackupType = ''' + CASE WHEN @LastBackupType LIKE '%FULL%' THEN 'Full Backup'
															ELSE @LastBackupType
															END + ''',
							DaysSinceLastBackup = 0,
							LastBackupMessage = ''Successful Backup'',
							RestoreStatus = NULL,
							RestoreTestDate = NULL
						FROM sys.databases tab1
						LEFT JOIN (SELECT TOP 1 * FROM ##BackupSetInfo ORDER BY Position DESC) tab2
						ON tab1.name = tab2.DatabaseName'
				END

				EXECUTE (@SQL)
			END TRY
			BEGIN CATCH
		
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

				-- Store error messsage in the report table 
				IF @MasterServer = @@SERVERNAME
				BEGIN
					SET @SQL = 'UPDATE DrasInternal.dbo.DatabaseBackupInfo 
					SET LastBackupMessage = ''Error Performing Backup ('' + CAST(GETDATE() AS NVARCHAR) + ''): ' + REPLACE(@ErrMsg, '''', '''''') + '''
					WHERE ServerName = ''' + @TargetServer + '''
					AND DatabaseName = ''' + @DBName + ''''
				END
				ELSE
				BEGIN
					SET @SQL = 'UPDATE OPENQUERY([' + @MasterServer + '], ''SELECT LastBackupMessage,
																				   LastModByUserId
																			FROM DrasInternal.dbo.DatabaseBackupInfo
																			WHERE ServerName = ''''' + @TargetServer + '''''
																			AND DatabaseName = ''''' + @DBName + '''''																	
																			'')
					SET LastBackupMessage = ''Error Performing Backup ('' + CAST(GETDATE() AS NVARCHAR) + ''): ' + REPLACE(@ErrMsg, '''', '''''') + ''''
				END;

				EXECUTE (@SQL);

				PRINT CHAR(10) + 'Error Performing ' + @LastBackupType +' backup for ' + @DBName + CHAR(10)
				PRINT @BackupCmd + CHAR(10)
				PRINT 'Msg: ' + @ErrMsg;

				SET @SQL = 'ALTER EVENT SESSION [Error Handling Session(' + CAST(@@SPID AS NVARCHAR) + ')] ON SERVER STATE=STOP;
							DROP EVENT SESSION [Error Handling Session(' + CAST(@@SPID AS NVARCHAR) + ')] ON SERVER;'

				EXECUTE(@SQL)

			END CATCH

			FETCH NEXT FROM DBList_Cursor INTO @DBName

		END

		CLOSE DBList_Cursor
		DEALLOCATE DBList_Cursor

	END TRY
	BEGIN CATCH
		PRINT @SQL;
		THROW;
	END CATCH

	------------------------------------- WEEKLY AND MONTHLY BACKUPS --------------------------------

	IF OBJECT_ID ('tempdb..##BUDirFiles') IS NOT NULL
	BEGIN
		DROP TABLE ##BUDirFiles
	END

	-- Store the list of files in the weekly and monthly backup folders
	SET @SQL = 'DECLARE @FileInfo AS TABLE (Input VARCHAR(500))

				INSERT INTO @FileInfo
				EXEC master..xp_cmdshell ''dir /n "' + @BULocation + '*.bak"''
					
				SELECT CAST(SUBSTRING(Input, 0, PATINDEX(''%[AM|PM]%'', Input) + 2) AS DATETIME) AS LastWriteTime
				,RTRIM(LTRIM(SUBSTRING(Input, PATINDEX(''%[AM|PM]%'', Input) + 3, PATINDEX(''%[a-z]%'', Input) - 1))) AS SizeInBytes
				, ''' + @BULocation + ''' AS ParentFolder
				, SUBSTRING(SUBSTRING(Input, PATINDEX(''%[AM|PM]%'', Input) + 3, LEN(Input)), PATINDEX(''%[a-z]%'', Input), LEN(Input)) BUFileName
				INTO ##BUDirFiles
				FROM @FileInfo
				WHERE (Input LIKE ''%AM%'' OR Input LIKE ''%PM%'') AND Input NOT LIKE ''%<DIR>%''

				DELETE FROM @FileInfo

				INSERT INTO @FileInfo
				EXEC master..xp_cmdshell ''dir /n "' + @WeeklyBULocation + '*.rar"''
			
				INSERT INTO ##BUDirFiles
				SELECT CAST(SUBSTRING(Input, 0, PATINDEX(''%[AM|PM]%'', Input) + 2) AS DATETIME) AS LastWriteTime
				,RTRIM(LTRIM(SUBSTRING(Input, PATINDEX(''%[AM|PM]%'', Input) + 3, PATINDEX(''%[a-z]%'', Input) - 1))) AS SizeInBytes
				,''' + @WeeklyBULocation + ''' AS ParentFolder
				, SUBSTRING(SUBSTRING(Input, PATINDEX(''%[AM|PM]%'', Input) + 3, LEN(Input)), PATINDEX(''%[a-z]%'', Input), LEN(Input)) BUFileName
				FROM @FileInfo 
				WHERE (Input LIKE ''%AM%'' OR Input LIKE ''%PM%'') AND Input NOT LIKE ''%<DIR>%''

				DELETE FROM @FileInfo

				INSERT INTO @FileInfo
				EXEC master..xp_cmdshell ''dir /n "' + @MonthlyBULocation + '*.rar"''
			
				INSERT INTO ##BUDirFiles
				SELECT CAST(SUBSTRING(Input, 0, PATINDEX(''%[AM|PM]%'', Input) + 2) AS DATETIME) AS LastWriteTime
				,RTRIM(LTRIM(SUBSTRING(Input, PATINDEX(''%[AM|PM]%'', Input) + 3, PATINDEX(''%[a-z]%'', Input) - 1))) AS SizeInBytes
				,''' + @MonthlyBULocation + ''' AS ParentFolder
				, SUBSTRING(SUBSTRING(Input, PATINDEX(''%[AM|PM]%'', Input) + 3, LEN(Input)), PATINDEX(''%[a-z]%'', Input), LEN(Input)) BUFileName
				FROM @FileInfo
				WHERE (Input LIKE ''%AM%'' OR Input LIKE ''%PM%'') AND Input NOT LIKE ''%<DIR>%''';


	EXECUTE (@SQL)
	
	SET @SQL = 'DECLARE FileListCursor CURSOR FOR
	SELECT DISTINCT BUFileName 
	FROM ##BUDirFiles
	WHERE ParentFolder = ''' + @BULocation + '''
	ORDER BY BUFileName'

	EXECUTE (@SQL)

	OPEN FileListCursor
	FETCH NEXT FROM FileListCursor INTO @BUFile

	WHILE @@FETCH_STATUS = 0
	BEGIN
		----------------------------------- Check if file exists --------------------------------------

		DELETE FROM @CheckTable
		SET @FileExists = NULL

		SET @BUFilePath = @BULocation + @BUFile

		SET @SQL = 'EXECUTE master..xp_cmdshell ''IF EXIST "' + @BUFilePath + '" ECHO 1'''

		INSERT INTO @CheckTable
		EXECUTE (@SQL)

		SELECT @FileExists = Value FROM @CheckTable WHERE Value IS NOT NULL

		-------------------------------- Move Backups to Weekly Folder every Friday ----------------------

		SET @ArchiveFile = REPLACE(@BUFile, '.bak', '.rar') 

		-- Compress backups into a winrar zip file and move to the weekly backup location on Fridays except for last Friday of the month
		IF DATEPART(DW, @CurrentDate) = 6 AND DATEPART(HOUR, @CurrentDate) >= 21 AND @FileExists IS NOT NULL
			AND FORMAT(@CurrentDate, 'yyyy-MM-dd') <> FORMAT(@LastFridayOfMonth, 'yyyy-MM-dd')
		BEGIN

			SET @ArchiveFilePath = @WeeklyBULocation + @ArchiveFile

			SET @SQL = 'IF EXIST "' + @ArchiveFilePath + '" DEL "' + @ArchiveFilePath + '"'
			EXECUTE master.dbo.xp_cmdshell @SQL

			SET @SQL = '""' + @WinrarExeFilePath + '" u -ep -ibck -y "' + @ArchiveFilePath +'" "' + @BUFilePath + '""'
			EXECUTE master.dbo.xp_cmdshell @SQL

		END
		
		------------------- Move backups to the Monthly folder on Last Friday of the Month ------------------
			
		-- Move the compressed zip files from the weekly folder to the monthly folder on the last Friday of the month
		IF FORMAT(@CurrentDate, 'yyyy-MM-dd') = FORMAT(@LastFridayOfMonth, 'yyyy-MM-dd') AND DATEPART(HOUR, @CurrentDate) >= 21
			AND @FileExists IS NOT NULL
		BEGIN
				
			SET @ArchiveFilePath = @MonthlyBULocation + @ArchiveFile

			SET @SQL = 'IF EXIST "' + @ArchiveFilePath + '" DEL "' + @ArchiveFilePath + '"'
			EXECUTE master.dbo.xp_cmdshell @SQL

			-- Compress backups into a winrar zip file and move to the monthly backup location
			SET @SQL = '""' + @WinrarExeFilePath + '" a -ep -ibck -df -y "' + @ArchiveFilePath +'" "' + @BUFilePath + '""'
			EXECUTE master.dbo.xp_cmdshell @SQL

		END

		FETCH NEXT FROM FileListCursor INTO @BUFile
	END

	CLOSE FileListCursor
	DEALLOCATE FileListCursor

	------------------------------------------- DELETE Old backup files ----------------------------------------------

	DECLARE DeleteOldBckp_Cursor CURSOR FOR
	SELECT 'EXEC master..xp_cmdshell ''DEL "' + ParentFolder + BUFileName + '"''' 
	FROM ##BUDirFiles
	WHERE LastWriteTime < @BackupExpiry
	AND ParentFolder LIKE '%Monthly%'

	OPEN DeleteOldBckp_Cursor
	FETCH NEXT FROM DeleteOldBckp_Cursor INTO @SQL

	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXECUTE (@SQL)
		FETCH NEXT FROM DeleteOldBckp_Cursor INTO @SQL
	END

	CLOSE DeleteOldBckp_Cursor
	DEALLOCATE DeleteOldBckp_Cursor

END

/*

EXECUTE dbo.sp_BackupSQLServer @MasterServer = DRASSQL2022,  @BULocation = NULL, 
@WeeklyBULocation = NULL, @MonthlyBULocation = NULL

*/
