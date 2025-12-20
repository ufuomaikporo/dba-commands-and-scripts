USE master;  
GO  

--EXEC sp_helptext N'dbo.sp_DX6Configv5'; 
--SELECT OBJECT_DEFINITION (OBJECT_ID(N'dbo.sp_DX6Configv5'));  
DECLARE @String NVARCHAR(MAX)
DECLARE @Index INT
DECLARE @SQL NVARCHAR(MAX)
DECLARE @StoreProcName NVARCHAR(100)
DECLARE @StrLength INT
DECLARE @DBName NVARCHAR(100)
DECLARE @ServerName NVARCHAR(100)


IF OBJECT_ID('tempdb..##DBList') IS NOT NULL
BEGIN
	EXECUTE ('DROP TABLE ##DBList')
END

IF OBJECT_ID('tempdb..##DBList') IS NULL
BEGIN
	CREATE TABLE ##DBList (ServerName VARCHAR(100), DBName VARCHAR(100), Command NVARCHAR(MAX));
END;

SET @StoreProcName = 'sp_Dx6ConfigV5'

DECLARE ServerDB_Cur CURSOR FOR
SELECT name FROM sys.databases
WHERE (name LIKE '%Stage%' OR name LIKE '%Prod%')
AND  (name NOT LIKE '%CONFIG%' AND name NOT LIKE '%LINK%' AND name NOT LIKE '%RISK%'  AND name NOT LIKE '%HELY%'
AND name NOT LIKE '%BASEDATA%' AND name NOT LIKE '%deleteme%' AND name NOT LIKE '%interchange%')
AND name LIKE '%IRASV6%'
ORDER BY name 

OPEN ServerDB_Cur
FETCH NEXT FROM ServerDB_Cur INTO @DBName

WHILE @@FETCH_STATUS = 0
BEGIN
	
	SET @SQL = 'USE ' + @DBName + '
				SELECT @Result =  CHARINDEX(''DROP TABLE #temp_Fabrication'', OBJECT_DEFINITION(OBJECT_ID(N''' + @StoreProcName + ''')), 10000)'
	
	EXECUTE sp_executesql @SQL, N'@Result INT OUT', @Index OUT

	SET @SQL = 'USE ' + @DBName + '
				SELECT @Result = LEN(OBJECT_DEFINITION(OBJECT_ID(N''' + @StoreProcName + ''')))'

	EXECUTE sp_executesql @SQL, N'@Result INT OUT', @StrLength OUT

	--INSERT INTO @DefinitionTBL
	--SELECT SUBSTRING(OBJECT_DEFINITION(OBJECT_ID(N'sp_Dx6ConfigV5')), 1, 9999)

	--SELECT @Index, @StrLength

	SET @SQL = 'USE ' + @DBName + ' SELECT @Result = SUBSTRING(OBJECT_DEFINITION(OBJECT_ID( ''' + @StoreProcName + ''')), ' + CAST(@index AS NVARCHAR) + ', ' + CAST(@StrLength AS NVARCHAR) + ')'
	EXECUTE sp_executesql @SQL, N'@Result NVARCHAR(MAX) OUT', @String OUT
	

	IF LEN(@String) > 100 AND (@String LIKE '%UPDATE%' OR @String LIKE '%INSERT%')
	BEGIN
		SET @SQL = 'INSERT INTO ##DBList
		VALUES (@@ServerName , ''' + @DBName + ''', ''USE ' + @DBName + ' EXEC sp_helptext N''''dbo.' + @StoreProcName + ''''''')'

		EXECUTE (@SQL)
	END

	FETCH NEXT FROM ServerDB_Cur INTO @DBName

END

CLOSE ServerDB_Cur
DEALLOCATE ServerDB_Cur

--SELECT @STRING

SELECT * FROM ##DBList
