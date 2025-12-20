/*
This script updates the compatibility level for all databases on the server (except system databases
and databases that have a current session not in 'sleeping' status) to the highest compatibility 
level. 
*/
USE master

DECLARE @MaxLevel INT
DECLARE @DBName NVARCHAR(100)
DECLARE @SQL NVARCHAR(MAX)

SELECT @MaxLevel = MAX(Compatibility_level) FROM sys.databases

DECLARE DBList_Cursor CURSOR FOR
SELECT name
FROM sys.databases d
LEFT JOIN sysprocesses sp ON d.database_id = sp.dbid
WHERE loginame IS NOT NULL 
AND database_id > 4
AND status = 'sleeping'
AND compatibility_level <> @MaxLevel


OPEN DBList_Cursor
FETCH NEXT FROM DBList_Cursor INTO @DBName

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @SQL = 'ALTER DATABASE ' + @DBName +' SET COMPATIBILITY_LEVEL = ' + CAST(@Maxlevel AS NVARCHAR) + ''
	EXECUTE (@SQL)

	FETCH NEXT FROM DBList_Cursor INTO @DBName

END

CLOSE DBList_Cursor
DEALLOCATE DBList_Cursor

