DECLARE @TableList NVARCHAR(MAX)
DECLARE @SQL NVARCHAR(MAX)
DECLARE @SourceDB NVARCHAR(100) = 'DRAS_IRASv6_DEMO_QA'
DECLARE @TargetDB NVARCHAR(100) = 'DrasInternal'
DECLARE @TargetTable NVARCHAR(100) = 'Transmission.Lookup_Tables'

SET @TableList = 'DomainCatalog
DomainCatalogColXRef
ListDomain'

DROP TABLE IF EXISTS ##TableList

CREATE TABLE ##TableList (Name NVARCHAR(100))

SET @SQL = REPLACE(@TableList, ' ', '')
SET @SQL = REPLACE(@SQL, CHAR(10), ' ')
SET @SQL = REPLACE(@SQL, CHAR(13), '')
SET @SQL = REPLACE(@SQL, CHAR(9), '')
SET @SQL = REPLACE(@SQL, ' ', ''')' + CHAR(10) + 'INSERT INTO ##TableList VALUES(''')
SET @SQL = 'INSERT INTO ##TableList VALUES(''' + @SQL + ''')'

EXECUTE (@SQL)

SET @SQL = '
USE '+ @SourceDB + '
INSERT INTO ' + @TargetDB + '.' + @TargetTable 
+ ' SELECT name FROM ' + @SourceDB + '.sys.tables
WHERE name IN (SELECT * FROM ##TableList)'

EXECUTE (@SQL)

--Centerline_Tables
--Compliance_Auditor_Tables
--Configuraton_Tables
--DataExchange_Tables
--DataManager_Tables
--Event_Tables
--ILI_Tables
--IRAS_Custom_Tables
--Lookup_Tables
--Outside_Force_Tables
--POE_Tables
--Risk_Tables
--Staging_Tables
--TableChecker_Tables
--Virtual_Tables
