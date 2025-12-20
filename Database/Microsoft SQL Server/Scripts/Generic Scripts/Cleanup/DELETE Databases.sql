/*
This script deletes all databases in the @DBList variable if there are no active sessions connected to them 

BEFORE RUNNING SCRIPT

1) SET the variables indicated below before running the script

*/

USE master

DECLARE @StartIndex INT 
DECLARE @EndIndex INT 
DECLARE @sql NVARCHAR(MAX)
DECLARE @GetDBListAsTable NVARCHAR(MAX)
DECLARE @DBName NVARCHAR(100)

DECLARE @DBList NVARCHAR(MAX)

DECLARE @DBList_Table TABLE (table_name NVARCHAR(100))

--************************************* SET VARIABLE BEFORE RUNNING SCRIPT ***********************************************

SET @DBList = 'ADNOC_IRASv6_LINK_PROD_TEST
'
--***************************************************************************************************************************
SET @DBList = REPLACE(@DBList, ' ', '')
SET @DBList = REPLACE(@DBList, CHAR(10), ' ')
SET @DBList = REPLACE(@DBList, CHAR(13), '')
SET @DBList = REPLACE(@DBList, CHAR(9), '')
SET @DBList = REPLACE(@DBList, ' ', ''', ''')

SET @DBList = '''' + @DBList + ''''

SET @StartIndex = 1
SET @EndIndex = 1

-- Databases in list that are on the server but have no current sessions connected to them
SET @GetDBListAsTable = 'DECLARE @result TABLE (table_name NVARCHAR(100))

INSERT INTO @result
SELECT name FROM sys.databases 
WHERE name IN (' + @DBList + ')
EXCEPT
SELECT name
FROM sys.databases d
LEFT JOIN sysprocesses sp ON d.database_id = sp.dbid
WHERE NAME IN (' + @DBList + ')
AND status IS NOT NULL

SELECT * FROM @result'

INSERT INTO @DBList_Table
EXECUTE (@GetDBListAsTable)

DECLARE DBList_Cursor CURSOR FOR
SELECT table_name FROM @DBList_Table

OPEN DBList_Cursor
FETCH NEXT FROM DBList_Cursor INTO @DBName

PRINT '*****************************************************************************************************************' + CHAR(10)
WHILE @@FETCH_STATUS = 0
BEGIN
	EXECUTE ('DROP DATABASE ' + @DBName)

	FETCH NEXT FROM DBList_Cursor INTO @DBName
END

CLOSE DBList_Cursor
DEALLOCATE DBList_Cursor
PRINT 'The following databases have been deleted' + CHAR(10)

SELECT table_name AS List_Of_Deleted_Databases
FROM @DBList_Table 
PRINT '*****************************************************************************************************************' + CHAR(10)

PRINT 'The following databases could not be deleted because of a connected session'

EXECUTE ('SELECT NAME
 , ''KILL '' + CAST(spid AS NVARCHAR) AS Terminate_Session_Cmd
 ,login_time
 ,STATUS
 ,hostname
 ,program_name
 ,nt_username
 ,loginame
FROM sys.databases d
LEFT JOIN sysprocesses sp ON d.database_id = sp.dbid
WHERE name IN (' + @DBList + ')
AND spid IS NOT NULL')
