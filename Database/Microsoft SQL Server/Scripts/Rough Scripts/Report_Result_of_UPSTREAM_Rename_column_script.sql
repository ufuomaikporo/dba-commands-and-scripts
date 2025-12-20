USE KEY_IRASV5_Upstream

PRINT 'various names of row tracking columns in tables'
-- Find the different variations of row tracking columns among tables
SELECT DISTINCT(col.name) AS column_name
FROM sys.tables tab 
INNER JOIN sys.columns col
	ON tab.object_id = col.object_id
WHERE (col.name LIKE 'LastMod%' OR 
	col.name LIKE 'Create%')
GO
PRINT 'various names of row tracking columns in tables AND VIEWS'
-- Find the different variations of row tracking columns among tables AND views
SELECT DISTINCT(column_name) FROM INFORMATION_SCHEMA.columns 
WHERE (column_name LIKE 'LastMod%' OR 
	column_name LIKE 'Create%')
GO

--PRINT 'tables without the specified column' -- Not reliable
--SELECT name AS table_name FROM sys.tables
--EXCEPT
--(
--SELECT tab.name AS table_name 
--FROM sys.tables tab
--JOIN sys.columns col
--ON tab.object_id = col.object_id
--WHERE col.name LIKE 'Create%Date%')
PRINT 'tables without the specified column'
SELECT name AS table_name FROM sys.tables
EXCEPT
(
SELECT tab.name AS table_name 
FROM sys.tables tab
JOIN sys.columns col
ON tab.object_id = col.object_id
WHERE col.name LIKE 'Create%Date%'
UNION
SELECT tab.name AS table_name 
FROM sys.tables tab
JOIN sys.columns col
ON tab.object_id = col.object_id
WHERE col.name LIKE 'Create%User%'
UNION
SELECT tab.name AS table_name 
FROM sys.tables tab
JOIN sys.columns col
ON tab.object_id = col.object_id
WHERE col.name LIKE 'LastMod%Date%'
UNION
SELECT tab.name AS table_name 
FROM sys.tables tab
JOIN sys.columns col
ON tab.object_id = col.object_id
WHERE col.name LIKE 'LastMod%User%')
ORDER BY 1
GO

print 'tables AND views without the specified column'
-- tables AND views without the specified column

SELECT ist.table_name, table_type FROM INFORMATION_SCHEMA.TABLES ist
JOIN 
(SELECT table_name AS table_name FROM INFORMATION_SCHEMA.COLUMNS
EXCEPT
(SELECT table_name AS table_name 
FROM INFORMATION_SCHEMA.COLUMNS
WHERE column_name LIKE 'Create%User%' )) subq
ON subq.table_name = ist.table_name
ORDER BY 1


--SELECT ist.table_name, table_type FROM INFORMATION_SCHEMA.TABLES ist
--JOIN 
--(SELECT table_name AS table_name FROM INFORMATION_SCHEMA.COLUMNS
--EXCEPT
--(SELECT table_name AS table_name 
--FROM INFORMATION_SCHEMA.COLUMNS
--WHERE column_name LIKE 'Create%User%' 
--UNION ALL
--SELECT table_name AS table_name 
--FROM INFORMATION_SCHEMA.COLUMNS
--WHERE column_name LIKE 'Create%Date%'
--UNION ALL
--SELECT table_name AS table_name 
--FROM INFORMATION_SCHEMA.COLUMNS
--WHERE column_name LIKE 'LastMod%User%'
--UNION ALL
--SELECT table_name AS table_name 
--FROM INFORMATION_SCHEMA.COLUMNS
--WHERE column_name LIKE 'LastMod%Date%'
--)
--) subq
--ON subq.table_name = ist.table_name
--GO

print 'tables with duplicate columns'
-- number of duplicate columns for the specified search string regEx 
SELECT tab.name AS table_name, count(*)
FROM sys.tables tab
JOIN sys.columns col
ON tab.object_id = col.object_id
Where col.name LIKE 'Create%Date%' 
GROUP BY tab.name
HAVING COUNT(*) > 1
UNION
SELECT tab.name AS table_name, count(*)
FROM sys.tables tab
JOIN sys.columns col
ON tab.object_id = col.object_id
Where col.name LIKE 'Create%Date%' 
GROUP BY tab.name
HAVING COUNT(*) > 1
UNION
SELECT tab.name AS table_name, count(*)
FROM sys.tables tab
JOIN sys.columns col
ON tab.object_id = col.object_id
Where col.name LIKE 'LastMod%User%' 
GROUP BY tab.name
HAVING COUNT(*) > 1
UNION
SELECT tab.name AS table_name, count(*)
FROM sys.tables tab
JOIN sys.columns col
ON tab.object_id = col.object_id
Where col.name LIKE 'LastMod%Date%' 
GROUP BY tab.name
HAVING COUNT(*) > 1

print 'Tables and views with duplicate columns'
SELECT table_name AS table_name, count(*)
FROM INFORMATION_SCHEMA.COLUMNS
Where column_name LIKE 'Create%User%' 
GROUP BY table_name
HAVING COUNT(*) > 1
UNION ALL
SELECT table_name AS table_name, count(*)
FROM INFORMATION_SCHEMA.COLUMNS
Where column_name LIKE 'Create%Date%' 
GROUP BY table_name
HAVING COUNT(*) > 1
UNION ALL
SELECT table_name AS table_name, count(*)
FROM INFORMATION_SCHEMA.COLUMNS
Where column_name LIKE 'LastMod%User%' 
GROUP BY table_name
HAVING COUNT(*) > 1
UNION ALL
SELECT table_name AS table_name, count(*)
FROM INFORMATION_SCHEMA.COLUMNS
Where column_name LIKE 'Create%User%' 
GROUP BY table_name
HAVING COUNT(*) > 1
ORDER BY 1

PRINT 'LIST OF TRIGGERS' -- UNRELIABLE QUERY
SELECT COUNT(DISTINCT(trig.object_id)) -- AS trigger_id, name AS trigger_name, subq.table_name
FROM sys.triggers trig
JOIN 
(SELECT trig.object_id AS trig_id,
	   trig.name AS trigger_name,
	   isc.table_name, 
	   isc.column_name
FROM INFORMATION_SCHEMA.COLUMNS isc
INNER JOIN sys.triggers trig
	ON OBJECT_ID(isc.table_name) = trig.parent_id
WHERE (column_name LIKE 'LastMod%' OR
      column_name LIKE 'Create%')
	  ) subq
ON subq.trig_id = trig.object_id
GO

PRINT 'ALL TRIGGERS ON TABLES WITH THE SPECIFIED COLUMNS'
SELECT DISTINCT(trig.object_id) AS trigger_id, name AS trigger_name, subq.table_name
FROM sys.triggers trig
JOIN 
(SELECT trig.object_id AS trig_id,
	   trig.name AS trigger_name,
	   isc.table_name, 
	   isc.column_name
FROM INFORMATION_SCHEMA.COLUMNS isc
INNER JOIN sys.triggers trig
	ON OBJECT_ID(isc.table_name) = trig.parent_id
WHERE column_name LIKE 'Create%'
	OR column_name LIKE 'LastMod%'
	  ) subq
ON subq.trig_id = trig.object_id
--WHERE trig.name LIKE '%version%'
GO

--PRINT 'ALL TRIGGERS WITHIN DATABASE'
--SELECT DISTINCT(trig.object_id) AS trigger_id, trig.name, subq.table_name
--FROM sys.triggers trig
--JOIN
--(SELECT trig.object_id AS trig_id, trig.name, isc.table_name, isc.column_name
--FROM sys.triggers trig
--JOIN INFORMATION_SCHEMA.COLUMNS isc
--ON OBJECT_ID(isc.table_name) = trig.parent_id) subq
--ON subq.trig_id = trig.object_id


PRINT 'TRIGGER COLUMNS'
SELECT DISTINCT(subq.column_name)
FROM sys.triggers trig
JOIN 
(SELECT trig.object_id AS trig_id,
	   trig.name AS trigger_name,
	   isc.table_name, 
	   isc.column_name
FROM INFORMATION_SCHEMA.COLUMNS isc
INNER JOIN sys.triggers trig
	ON OBJECT_ID(isc.table_name) = trig.parent_id
WHERE (column_name LIKE 'LastMod%' OR
      column_name LIKE 'Create%')
	  ) subq
ON subq.trig_id = trig.object_id
--WHERE trigger_name = 'td_rectifier'
GO

-- Get tables and columns in each table or view that need to be modified
SELECT table_name, column_name
FROM INFORMATION_SCHEMA.COLUMNS
WHERE (column_name LIKE 'LastMod%'
		OR column_name LIKE 'Create%')
	AND table_name = 'INCIDENT' 

