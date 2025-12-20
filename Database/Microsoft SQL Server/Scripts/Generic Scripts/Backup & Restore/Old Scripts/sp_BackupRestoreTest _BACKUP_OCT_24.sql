USE DrasInternal
GO

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
	DECLARE @SubCounter INT
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
	DECLARE @FullbkpFile INT
	DECLARE @DistinctRecoveryForkIds INT
	DECLARE @CountDiffBackups INT
	DECLARE @BackupPosition INT


---*********************************** SET THE FOLLOWING VARIABLES BEFORE RUNNING THE SCRIPT **************************************

--SET @ServerName = 'SQL2019'
--SET @BUFolder = '\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\'
--SET @BULocation = @BUFolder + @ServerName + '\Nightly\'
--SET @DataFileLoc = 'D:\' --needs to be a valid location on the SQL Server node 

--*********************************************************************************************************************************

	-- Dummy encryption certificate name and database name (Will be deleted)
	SET @DBName = 'DELETE_ME'
	SET @CertificateName = @DBName + '_Cert'

	--SET @BULocation = @BUFolder + @ServerName + '\Nightly\'
	SET @LogFileLoc = @DataFileLoc

	DECLARE @DataFileInfo TABLE (Id INT IDENTITY(1,1),
								 LogicalName NVARCHAR(500),
								 PhysicalName NVARCHAR(500),
								 BackupType CHAR(1),
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
	DECLARE @MissingBackupReport TABLE (DatabaseName NVARCHAR(100),
										FilePosition INT,
										BackupType NVARCHAR(50),
										FileName NVARCHAR(500),
										BackupStartDate DATETIME,
										BackupFinishDate DATETIME)

	-- Create table variable to store a list of the backup files
	DECLARE @BUDirFiles TABLE  (
			Id INT IDENTITY(1,1),
			SubDirectory NVARCHAR(255),
			Depth SMALLINT,
			FileFlag BIT,
			ParentDirectoryID INT
		   )

	-- Table to group backups by RecoveryForkId
	DECLARE @RecoveryForkIdList TABLE (Id INT,
								 RecoveryForkId NVARCHAR(100),
								 ForkIdCount INT);

	-- Stores list of backups in each RecoveryForkId group
	DECLARE @BUForRecoveryForkId TABLE (Id INT,
								  FilePosition INT,
								  RecoveryForkId NVARCHAR(100))

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
	--AND Subdirectory LIKE '%WPLCO_PODS.bak%'

	------------------------------------- DELETE DUMMY DATABASE IF IT ALREADY EXISTS -------------------------------------

	-- Delete dummy database if it already exists
	IF EXISTS (SELECT 1 FROM sys.databases WHERE name = @DBName)
	BEGIN
		-- Put database in single user mode
		SET @SQL = 'USE master;
					DROP DATABASE '+ @DBName + ';'

		EXECUTE(@SQL);

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

	--############################### RESTORE BASE FULL BACKUP ################################################

		--Command to get datafile and logfile info for restore (i.e. logical filenames) 
	
		SET @SQL = 'RESTORE FILELISTONLY  
		FROM DISK = ''' + @BUFile + '''' 

		-- Refresh table for storing datafile and logfile info
		DELETE FROM @DataFileInfo

		-- Insert datafile and logfile info into table
		INSERT INTO @DataFileInfo
		EXECUTE sp_executesql @sql

		-- Get the postion number of the full database backup
		SELECT @FullbkpFile = MIN(Position) FROM @BackupSetInfo WHERE BackupType = 1
		
		SET @Counter = 1

		IF @FullbkpFile IS NOT NULL
		BEGIN
            -- Construct command to perform the first restore using the base full backup 
            SET @BaseRestore = 'RESTORE DATABASE ' + @DBName + CHAR(10) 
								+ 'FROM DISK = ''' +  @BUFile + '''' + CHAR(10) 
								+ 'WITH REPLACE, ' 
								+ 'FILE = ' + CAST(@FullbkpFile AS NVARCHAR) + ', NORECOVERY, '

            SELECT @Stopper = COUNT(1) FROM @DataFileInfo
            SET @SubCounter = 1

            -- Loop to contruct command to perform the base Full backup restore 
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
                SELECT  ROW_NUMBER() OVER(ORDER BY ID ASC) AS RowNum, FileId
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

            -- Create a list that groups differential backups by their RecoveryForkId
            DELETE FROM @RecoveryForkIdList;

            INSERT INTO @RecoveryForkIdList
            SELECT ROW_NUMBER() OVER(ORDER BY RecoveryForkId ASC) AS RowNum,
                    RecoveryForkId, 
                    COUNT(RecoveryForkId)
            FROM @BackupSetInfo
			WHERE BackupType <> 1
            GROUP BY RecoveryForkId

			-- Get the number of distinct RecoveryForkId
            SELECT @DistinctRecoveryForkIds = COUNT(*) FROM @RecoveryForkIdList

            SET @Counter = 1

            -- Loop through each group of recoveryForIds
            WHILE @Counter <= @DistinctRecoveryForkIds
            BEGIN
--------------------------- EXECUTE COMMAND TO RESTORE BASE FULL BACKUP -------------------------------

                BEGIN TRY
                    -- Execute the command to restore the base full backup
					--select @BaseRestore
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
                    FROM @BackupSetInfo 
                    WHERE position = @FullbkpFile 
                END CATCH

		--##################################### RESTORE DIFFERENTIAL BACKUPS #################################################
				
                -- Create a list of all differential backups with the same RecoveryForkId and store it in a table variable
                DELETE FROM @BUForRecoveryForkId;

                INSERT INTO @BUForRecoveryForkId
                SELECT ROW_NUMBER() OVER(ORDER BY Position ASC) AS RowNum, Position, RecoveryForkId
                FROM @BackupSetInfo
                WHERE RecoveryForkId = (SELECT RecoveryForkId FROM @RecoveryForkIdList
                                        WHERE Id = @Counter)
                AND BackupType <> 1

				-- Number of backups in a specific RecoveryForkId group
                SELECT @CountDiffBackups = COUNT(*) FROM @BUForRecoveryForkId

                SET @SubCounter = 1
                				
                -- Loop through and restoe the differential backups with the same RecoveryForkId
                WHILE @SubCounter <= @CountDiffBackups
                BEGIN

                    SELECT @BackupPosition = FilePosition FROM @BUForRecoveryForkId
                    WHERE Id = @SubCounter;

					IF @SubCounter = @CountDiffBackups 
					BEGIN
						SET @Recovery = 'RECOVERY'
					END
					ELSE
					BEGIN
						SET @Recovery = 'NORECOVERY'
					END

                    -- Restore the last differential backup with RECOVERY
                    BEGIN TRY
						SET @SQL = 'RESTORE DATABASE ' + @DBName + CHAR(10) 
									+ 'FROM DISK = ''' + @BUFile + '''' + CHAR(10) 
									+ 'WITH FILE = ' + CAST(@BackupPosition AS NVARCHAR)+ ', ' + @Recovery + ', NOUNLOAD, STATS = 5' 
                         --select @sql
						EXECUTE (@SQL)
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
                        FROM @BackupSetInfo 
                        WHERE position = @BackupPosition 
    
                    END CATCH
            
                    SET @SubCounter += 1
				END -- End of While-loop to restore differential backups for each RecoveryForkId group
								
				SET @Counter += 1
			END -- End of While-Loop to loop through each grouping of RecoveryForkId
		
		END
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
					FROM @BackupSetInfo 
					WHERE position = 1 
		END
		FETCH NEXT FROM DBList_Cursor INTO @FileName
	END

	CLOSE DBList_Cursor
	DEALLOCATE DBList_Cursor

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
	PRINT CHAR(10) + 'THE FOLLOWING BACKUPS ARE UNUSABLE FOR DATABASE RESTORE' + CHAR(10)

	SELECT * FROM ##MissingBackupReport
	ORDER BY 4, 1, 2

	------------------------------------------------- CLEANUP ---------------------------------

	--Delete dummy database
	IF EXISTS (SELECT 1 FROM sys.databases WHERE name = @DBName)
	BEGIN

		SET @SQL = 'DROP DATABASE ' + @DBName;

		EXECUTE(@SQL);
	END
END
GO