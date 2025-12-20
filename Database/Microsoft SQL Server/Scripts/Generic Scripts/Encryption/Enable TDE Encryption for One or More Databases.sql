/*
PREREQUISITES

1) A server master key MUST already be created
2) SET the variables indicated below before running the script

*/
DECLARE @SQL NVARCHAR(MAX)
DECLARE @IsExists INT
DECLARE @DBName NVARCHAR(100)
DECLARE @BackupLoc NVARCHAR(300) 
DECLARE @ServerName NVARCHAR(100) 
DECLARE @DBList NVARCHAR(MAX)
DECLARE @TDECertificateName NVARCHAR(100)
DECLARE @TDEPrivateKeyName NVARCHAR(100)
DECLARE @TDECertificateLoc NVARCHAR(100)
DECLARE @TDEPrivateKeyLoc NVARCHAR(100)

DECLARE @DBList_Table TABLE (name NVARCHAR(100))

DECLARE  @BUDirFiles TABLE  (
		Id INT IDENTITY(1,1),
		SubDirectory NVARCHAR(255),
		Depth SMALLINT,
		FileFlag BIT,
		ParentDirectoryID INT
	   )

--************************************* SET THESE VARIABLES BEFORE RUNNING THE SCRIPT ****************************************** 

SET @ServerName = @@SERVERNAME

-- Location for storing the backup of the certificate and private key
SET @BackupLoc = '\\backups.cgy.dynamicrisk.net\DB_Backups_Nightly\' + @ServerName + '\Archive\'

SET @TDECertificateName = @ServerName + '_TDE_CERTIFICATE'
SET @TDEPrivateKeyName = @TDECertificateName

--******************************************************************************************************************************

-- Get the list of all files in the backup directory
INSERT INTO @BUDirFiles (SubDirectory, Depth, FileFlag)
EXEC master..xp_dirtree @BackupLoc , 10, 1

-- LIST OF DATBASES TO WILL HAVE TDE ENCRYPTION ENABLED
SET @DBList = 'KEY_IRASV5_Upstream'

SET @DBList = REPLACE(@DBList, ' ', '')
SET @DBList = REPLACE(@DBList, CHAR(10), ' ')
SET @DBList = REPLACE(@DBList, CHAR(13), '')
SET @DBList = REPLACE(@DBList, CHAR(9), '')
SET @DBList = REPLACE(@DBList, ' ', ''', ''')
SET @DBList = REPLACE(@DBList, ''''', ', '')

SET @DBList = '''' + @DBList + ''''

SET @SQL = 'DECLARE @Result TABLE (name NVARCHAR(100))

INSERT INTO @Result
SELECT name FROM sys.databases
WHERE name IN (' + @DBList + ')
AND is_read_only = 0
EXCEPT
SELECT    name
FROM      sys.databases D
JOIN      sys.dm_database_encryption_keys DEK
ON        DEK.database_id = D.database_id
WHERE dek.encryption_state = 3
ORDER BY  name

SELECT name FROM @Result'

INSERT INTO @DBList_Table
EXECUTE (@SQL)

DECLARE DBList_Cursor CURSOR FOR
SELECT name FROM @DBList_Table

OPEN DBList_Cursor
FETCH NEXT FROM DBList_Cursor INTO @DBName

WHILE @@FETCH_STATUS = 0
BEGIN

---------------------------------------- CREATE ENCRYPTION CERTIFICATE ----------------------------------------------------

	SET @SQL = 'USE master

				IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = '''+ @TDECertificateName +''')
				BEGIN
					CREATE CERTIFICATE ' + @TDECertificateName + ' WITH SUBJECT = ''' + @ServerName + ' DEK Certificate'';
				END'

	EXECUTE (@SQL)

---------------------------------- CREATE DATABASE PRIVATE ENCRYPTION KEY ------------------------------------------
	
	SET @SQL = 'IF NOT EXISTS (SELECT 1	FROM sys.databases d
								JOIN sys.dm_database_encryption_keys dek
								ON DEK.database_id = d.database_id
								JOIN sys.certificates AS cer
								ON dek.encryptor_thumbprint = cer.thumbprint
								WHERE cer.name = ''' + @TDECertificateName + ''' 
								AND d.name = ''' + @DBName + ''')
				BEGIN
					USE ' +  @DBName + '

					CREATE DATABASE ENCRYPTION KEY
					WITH ALGORITHM = AES_256
					ENCRYPTION BY SERVER CERTIFICATE ' + @TDECertificateName + ';

				END';


	EXECUTE (@SQL)

------------------------------------ TURN ON TDE ENCRYPTION ---------------------------------------------

-- Turns on TDE encryption ONLY for databases with a simple recovery model
	SET @SQL = 'SELECT @Result = 1 FROM sys.databases d
							JOIN sys.dm_database_encryption_keys dek
							ON DEK.database_id = d.database_id
							WHERE d.name = ''' + @DBName + '''
							AND dek.encryption_state = 1
							AND recovery_model_desc = ''SIMPLE'''

	EXECUTE sp_executesql @SQL, N'@Result INT OUT', @IsExists OUT


	IF @IsExists = 1
	BEGIN 
		PRINT CHAR(10) + 'Turning on TDE Encryption for '  + @DBName 
		SET @SQL ='ALTER DATABASE ' +  @DBName + ' SET ENCRYPTION ON'

		EXECUTE (@SQL)
	END

----------------------------------------------------------------------------------------------------------------------------------
	FETCH NEXT FROM DBList_Cursor INTO @DBName
END

CLOSE DBList_Cursor
DEALLOCATE DBList_Cursor

SET @TDECertificateLoc=  @BackupLoc + @TDECertificateName + '.cer'
SET @TDEPrivateKeyLoc =  @BackupLoc + @TDEPrivateKeyName + '.prvk'

------------------------------------------ Backup Encryption Certificate --------------------------------------------------

IF NOT EXISTS (SELECT 1 FROM @BUDirFiles WHERE SubDirectory = @TDECertificateName + '.cer') 
	AND NOT EXISTS (SELECT 1 FROM @BUDirFiles WHERE SubDirectory = @TDEPrivateKeyName + '.prvk')
BEGIN
	SET @SQL = 'USE Master
	
	BACKUP CERTIFICATE ' + @TDECertificateName + '
	TO FILE = ' + '''' + @TDECertificateLoc + '''
	WITH PRIVATE KEY(
	FILE = '+ '''' + @TDEPrivateKeyLoc + ''',
	ENCRYPTION BY PASSWORD = ''Fs9f4fkg93sdjk''
	)';

	EXECUTE (@SQL);

	PRINT CHAR(10) + 'THE ENCRYPTION CERTIFICATE BACKUP WAS CREATED IN ' + @BackupLoc
END
ELSE
BEGIN
	PRINT CHAR(10) + 'ONE OR MORE OF THE ENCRYPTION CERTIFICATE FILES ALREADY EXISTS IN ' + @BackupLoc
	PRINT 'DELETE THE ENCRYPTION CERTIFICATE FILES IN ' + @BackupLoc + ' AND RE-RUN THIS SCRIPT TO CREATE NEW CERTIFICATE BACKUPS'

END

--IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = 'SQLDEVPREPROD_TDE_CERT')
--				BEGIN
--					CREATE CERTIFICATE SQLDEVPREPROD_TDE_CERT WITH SUBJECT = 'SQLDEVPREPROD DEK Certificate';
--				END
