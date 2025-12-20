DECLARE @DBName NVARCHAR(100)
DECLARE @SQL NVARCHAR(MAX)
DECLARE @CertificateName NVARCHAR(100)
DECLARE @EncryptionState NVARCHAR(1)
DECLARE @PrivateKeyType NVARCHAR(100)
DECLARE @Status NUMERIC
DECLARE @Counter INT = 1
DECLARE @Count INT
DECLARE @Stopper INT
DECLARE @DBList NVARCHAR(MAX)

-- LIST OF DATBASES THAT WILL HAVE TDE ENCRYPTION DISABLED
SET @DBList = 'PGE_IRASv6_CONFIG
PGE_IRASv6_CONFIG_TDE
PGE_IRASv6_LINK
PGE_IRASv6_STAGE
'

SET @DBList = REPLACE(@DBList, ' ', '')
SET @DBList = REPLACE(@DBList, CHAR(10), ' ')
SET @DBList = REPLACE(@DBList, CHAR(13), '')
SET @DBList = REPLACE(@DBList, CHAR(9), '')
SET @DBList = REPLACE(@DBList, ' ', ''', ''')
SET @DBList = REPLACE(@DBList, ''''', ', '')

SET @DBList = '''' + @DBList + ''''

DECLARE @DBList_Table TABLE (Id INT IDENTITY(1,1),
							DatabaseName NVARCHAR(100),
						   CertificateName NVARCHAR(100)
						   )

SET @Counter = 1

WHILE @Counter <= 240
BEGIN

	SET @SQL = 'DECLARE @Result Table (DatabaseName NVARCHAR(100),
				CertificateName NVARCHAR(100)
				)

				INSERT INTO @Result
				SELECT  d.name AS DatabaseName,
						cer.name AS CertificateName
				FROM sys.databases d
				JOIN sys.dm_database_encryption_keys dek
				ON DEK.database_id = d.database_id
				JOIN sys.certificates cer
				ON dek.encryptor_thumbprint = cer.thumbprint
				WHERE d.name IN (' + @DBList + ')
			
				SELECT * FROM @Result'

	--Clear Table for each outer loop iteration
	DELETE FROM @DBList_Table

	-- Tables that need to have TDE encryption disabled
	INSERT INTO @DBList_Table
	EXECUTE (@SQL)

	DECLARE DBList_Cursor CURSOR FOR
	SELECT DatabaseName, CertificateName 
	FROM @DBList_Table

	OPEN DBList_Cursor 
	FETCH NEXT FROM DBList_Cursor INTO @DBName, @CertificateName

	WHILE @@FETCH_STATUS = 0
	BEGIN		
--------------------------------------- TURN OFF DATBASE ENCRYPTION ----------------------------------------------------
		SET @SQL = 'USE master;
					IF EXISTS (SELECT 1	FROM sys.databases d
								JOIN sys.dm_database_encryption_keys dek
								ON DEK.database_id = d.database_id
								JOIN sys.certificates AS cer
								ON dek.encryptor_thumbprint = cer.thumbprint
								WHERE cer.name = ''' + @CertificateName + '''
								AND d.name = ''' + @DBName + '''
								AND dek.encryption_state = 3)
					BEGIN
						ALTER DATABASE ' + @DBName + ' SET ENCRYPTION OFF
					END;'

		EXECUTE (@SQL)

-------------------------------------- DELETES ENCRYPTION KEY ------------------------------------------------------
		
		SET @SQL = 'IF EXISTS (SELECT 1	FROM sys.databases d
								JOIN sys.dm_database_encryption_keys dek
								ON DEK.database_id = d.database_id
								JOIN sys.certificates AS cer
								ON dek.encryptor_thumbprint = cer.thumbprint
								WHERE cer.name = ''' + @CertificateName + '''
								AND d.name = ''' + @DBName + '''
								AND encryption_state = 1)
					BEGIN
						USE ' + @DBName + '
						DROP DATABASE ENCRYPTION KEY;
					END'

		EXECUTE (@SQL)

		FETCH NEXT FROM DBList_Cursor INTO @DBName, @CertificateName	
	END

	CLOSE DBList_Cursor
	DEALLOCATE DBList_Cursor

	-- Get a count of databases in list that still need TDE encryption to be disabled
	SET @SQL = 'SELECT @Result =  COUNT(*)
				FROM sys.databases d
				JOIN sys.dm_database_encryption_keys dek
				ON DEK.database_id = d.database_id
				JOIN sys.certificates cer
				ON dek.encryptor_thumbprint = cer.thumbprint
				WHERE d.name IN (' + @DBList + ')'

	EXECUTE sp_executesql @SQL, N'@Result INT OUT', @Count OUT

-------------------------------------- DELETES TDE ENCRYPTION CERTIFICATE -----------------------------------------
	IF @Count = 0
	BEGIN
		IF EXISTS (SELECT 1 FROM sys.certificates WHERE name =  @CertificateName) 
		BEGIN
			EXECUTE ('DROP CERTIFICATE ' +  @CertificateName) ;			
		END

		BREAK
	END
--------------------------------------------------------------------------------------------------------------------

	WAITFOR DELAY '00:00:30'

	SET @Counter += 1

END -- Outer While-Loop
