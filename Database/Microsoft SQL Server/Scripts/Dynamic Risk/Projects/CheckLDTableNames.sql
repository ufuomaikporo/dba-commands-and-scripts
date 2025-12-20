USE DrasInternal
-- Find rows with missing LD table (Should return nothing)
SELECT * FROM ListDomainTableInfo WHERE LDTableName is null --and flag = 0
ORDER BY DomainDescr, columnname

-- Check that each table-column name combination has a unique LD table name (should return nothing)
SELECT  tmp.TableName, tmp.ColumnName, count(*) FROM (
SELECT distinct ldti.TableName, ldti.ColumnName, ldti.LDTableName 
FROM dbo.ListDomainTableInfo ldti WHERE ldti.LDTableName IS NOT null) tmp
WHERE TableName is not null
GROUP BY tmp.TableName, tmp.ColumnName HAVING count(*) > 1

-- Check if there is more than one LD table name for the same DomainDescr (may return some rows)
select DomainDescr, count(LDTableName) from (
select DISTINCT LDTableName, DomainDescr from ListDomainTableInfo where DomainDescr is not null) tmp
group by DomainDescr
having count(LDTableName) > 1
order by 1


select DISTINCT TableName, ColumnName, LDTableName, DomainDescr from ListDomainTableInfo where DomainDescr = 'ILI Facility Type'
select DISTINCT servername, TableName, ColumnName, LDTableName, DomainDescr from ListDomainTableInfo where tablename = 'DCVGSurvey' and columnname = 'DCVGSurveyTypeDomainId'
-- Pressure Type, Land Use Type, ILI Facility Type, ILI Defect Status

RETURN

-- LD tables with more than 1 Domain Descr (See Domain Descr that have been grouped into the same LD tables)
SELECT DISTINCT LDTableName, DomainDescr,
DENSE_RANK() OVER (ORDER BY LDTableName) AS GroupMember
,DENSE_RANK() OVER (PARTITION BY LDTableName ORDER BY LDTableName, DomainDescr) AS GroupMember
from ListDomainTableInfo tab1
where exists (SELECT LDTableName, Count(DISTINCT DomainCatalogId)
from ListDomainTableInfo tab2
WHERE tab1.LDTableName = tab2.LDTableName AND DomainDescr IS NOT NULL 
group by LDTableName
HAVING Count(DISTINCT DomainDescr) > 1)  
and DomainDescr IS NOT NULL AND TableName IS NOT NULL 
order by LDTableName, DomainDescr;

-- Check column groupings using a known DomainDescr (LD tables may have more than 1 distinct column)
SELECT DISTINCT LDTableName, ColumnName, DomainDescr,
DENSE_RANK() OVER (ORDER BY LDTableName) AS GroupMember
,DENSE_RANK() OVER (PARTITION BY LDTableName ORDER BY LDTableName, DomainDescr) AS GroupMember
from ListDomainTableInfo tab1
where exists (SELECT LDTableName, Count(DISTINCT DomainCatalogId)
from ListDomainTableInfo tab2
WHERE tab1.LDTableName = tab2.LDTableName AND DomainDescr IS NOT NULL 
group by LDTableName
HAVING Count(DISTINCT DomainDescr) > 1)  
and DomainDescr IS NOT NULL AND ColumnName IS NOT NULL AND LDTableName IN
(select distinct LDTableName FROM ListDomainTableInfo 
WHERE DomainDescr LIKE '%Grading%')
order by LDTableName, ColumnName, DomainDescr;

----------------------------------- following MUST RUN on target db ------------------------

-- Domaindescr with more than 1 LD table name (may return some values returns nothing if each DomainDescr is assigned to 1 LD table)
SELECT DomainDescr, Count(DISTINCT LDTableName) NUmber_Of_LDTables
from ListDomainTableInfo
WHERE DomainDescr IS NOT NULL and ServerName = @@SERVERNAME
AND DBName = DB_NAME()
group by DomainDescr
HAVING Count(DISTINCT LDTableName) > 1
ORDER BY 1, 2;

-- See similar codes between domain descrs that have been grouped together (for V 6.5.0)
WITH CTE AS 
(SELECT DISTINCT DomainDescr, Code, Descr, LDTableName
FROM Temp_ListDomain
where ldtablename in (SELECT DISTINCT --ServerName, DBName, TableName, ColumnName, 
LDTableName --, DomainDescr
from DRASSQL2019.DrasInternal.dbo.ListDomainTableInfo tab1
where exists (SELECT LDTableName, Count(DISTINCT DomainCatalogId)
from DRASSQL2019.DrasInternal.dbo.ListDomainTableInfo tab2
WHERE tab1.LDTableName = tab2.LDTableName AND
 DomainDescr IS NOT NULL and ServerName = @@SERVERNAME
AND DBName = DB_NAME()
group by LDTableName
HAVING Count(DISTINCT DomainDescr) > 1)  
AND ServerName = @@SERVERNAME
AND DBname = DB_NAME() and DomainDescr IS NOT NULL)
)
SELECT DomainDescr, Code, Descr , LDTableName , 
DENSE_RANK() OVER (ORDER BY LDTableName) AS GroupMember
,DENSE_RANK() OVER (PARTITION BY LDTableName ORDER BY LDTableName, DomainDescr) AS GroupMember
FROM CTE tab1 WHERE EXISTS (
SELECT LDTableName, Code, COUNT(*)
FROM CTE tab2 
WHERE tab1.LDTablename = tab2.LDTableName and tab1.Code = tab2.Code
GROUP BY LDTableName, Code
HAVING COUNT(*) > 1
)
and Code <> 'Unknown' ORDER BY LdTableName, Code, DomainDescr;


-- See similar codes between domain descrs that have been grouped together (for V 6.4.2 and below )
WITH CTE AS 
(SELECT DISTINCT dc.DomainDescr, Code, Descr, LDTableName
FROM ListDomain ld
LEFT JOIN DomainCatalog dc ON ld.DomainCatalogId = dc.Id
LEFT JOIN DRASSQL2019.DrasInternal.dbo.ListDomainTableInfo ldi
ON dc.DomainDescr = ldi.DomainDescr
where ldtablename in (SELECT DISTINCT LDTableName 
from DRASSQL2019.DrasInternal.dbo.ListDomainTableInfo tab1
where exists (SELECT LDTableName, Count(DISTINCT DomainCatalogId)
from DRASSQL2019.DrasInternal.dbo.ListDomainTableInfo tab2
WHERE tab1.LDTableName = tab2.LDTableName AND
 DomainDescr IS NOT NULL and ServerName = @@SERVERNAME
AND DBName = DB_NAME()
group by LDTableName
HAVING Count(DISTINCT DomainDescr) > 1)  
AND ServerName = @@SERVERNAME
AND DBname = DB_NAME() and DomainDescr IS NOT NULL)
)
SELECT DISTINCT LDTableName, DomainDescr, Code, Descr ,
DENSE_RANK() OVER (ORDER BY LDTableName) AS GroupId
,DENSE_RANK() OVER (PARTITION BY LDTableName ORDER BY LDTableName, DomainDescr) AS GroupMember
FROM CTE tab1 WHERE EXISTS (
SELECT DISTINCT LDTableName, Code, COUNT(*)
FROM CTE tab2 
WHERE tab1.LDTablename = tab2.LDTableName and tab1.Code = tab2.Code
GROUP BY LDTableName, Code
HAVING COUNT(*) > 1
)
and Code <> 'Unknown'
ORDER BY GroupId, Code, GroupMember;

-- Check DomainGrouping for a specific database (DRASSQL2017\DRAS_IRASV6_DEMO_DE_STAGE  )
SELECT DISTINCT LDTableName, DomainDescr
from ListDomainTableInfo tab1
where exists (SELECT LDTableName, Count(DISTINCT DomainCatalogId)
from ListDomainTableInfo tab2
WHERE tab1.LDTableName = tab2.LDTableName AND DomainDescr IS NOT NULL 
and ServerName = 'DRASSQL2017'
AND DBName = 'DRAS_IRASV6_DEMO_DE_STAGE'
group by LDTableName
HAVING Count(DISTINCT DomainDescr) > 1)  
AND ServerName = 'DRASSQL2017'
AND DBname = 'DRAS_IRASV6_DEMO_DE_STAGE' 
and DomainDescr IS NOT NULL
ORDER by LDTableName, DomainDescr

-- Check Listdomain grouping on ListDomain table in specific database
SELECT DISTINCT ld.Id, Code, Descr, dc.DomainDescr, LDTableName ,
DENSE_RANK() OVER (ORDER BY LDTableName) AS GroupId
,DENSE_RANK() OVER (PARTITION BY LDTableName ORDER BY LDTableName, dc.DomainDescr) AS GroupMember
FROM ListDomain ld JOIN 
domaincatalog dc ON dc.Id = ld.DomainCatalogId
JOIN DRASSQL2019.DrasInternal.dbo.ListDomainTableInfo ldi
on dc.DomainDescr = ldi.DomainDescr
WHERE LDTableName IN (SELECT LDTableName 
FROM DRASSQL2019.DrasInternal.dbo.ListDomainTableInfo
WHERE DomainDescr LIKE '%Classification Type%') 
ORDER BY LDTableName, dc.DomainDescr
/*
select * from DRASSQL2019.DrasInternal.dbo.Temp_ListDomainTableInfo
where DomainDescr in ('Mechanical Damage Defect Type', 'Mechanical Damage Status')
or domainDescr like '%Defect&%'

se

SELECT * FROM ListDomainTableInfo WHERE LDTableName is null and dbname like 'Dras%' --and flag = 0
ORDER BY DomainDescr, columnname

SELECT  tmp.TableName, tmp.ColumnName, count(*) FROM (
SELECT distinct ldti.TableName, ldti.ColumnName, ldti.LDTableName 
FROM dbo.ListDomainTableInfo ldti WHERE ldti.LDTableName IS NOT null) tmp
WHERE TableName is not null
GROUP BY tmp.TableName, tmp.ColumnName HAVING count(*) > 1

select distinct LDTableName from ListDomainTableInfo where tablename = 'ACVGSurveyAnomaly' and columnname = 'ACVGAnomalyIndicationTypeLD'

select distinct TableName, ColumnName, DomainDescr, LDTableName from ListDomainTableInfo tab1
where exists (
SELECT  tmp.TableName, tmp.ColumnName, count(*) FROM (
SELECT distinct ldti.TableName, ldti.ColumnName, ldti.LDTableName 
FROM dbo.ListDomainTableInfo ldti WHERE ldti.LDTableName IS NOT null) tmp
WHERE TableName is not null and tmp.TableName = tab1.TableName 
and tmp.Columnname = tab1.columnname 
GROUP BY tmp.TableName, tmp.ColumnName HAVING count(*) > 1)
order by tablename, columnname, domaindescr

select count(*) from (
SELECT  tmp.TableName, tmp.ColumnName, count(*) cnt FROM (
SELECT distinct ldti.TableName, ldti.ColumnName, ldti.LDTableName 
FROM dbo.ListDomainTableInfo ldti WHERE ldti.LDTableName IS NOT null) tmp
WHERE TableName is not null
GROUP BY tmp.TableName, tmp.ColumnName HAVING count(*) > 1) tmp

SELECT DISTINCT Servername, dbname, TableName, ColumnName, DomainDescr, LDTableName from ListDomainTableInfo tab1
WHERE exists (
SELECT  tmp.TableName, tmp.ColumnName, count(*) FROM (
SELECT distinct ldti.TableName, ldti.ColumnName, ldti.LDTableName 
FROM dbo.ListDomainTableInfo ldti WHERE ldti.LDTableName IS NOT null) tmp
WHERE TableName is not null and tmp.TableName = tab1.TableName 
and tmp.Columnname = tab1.columnname 
GROUP BY tmp.TableName, tmp.ColumnName HAVING count(*) > 1)
 and domaindescr is not null and tablename is not null --and domaindescr like '%Class%Rating%'
order by tablename, columnname, domaindescr



select distinct servername, dbname, LDTableName from ListDomainTableInfo 
where domaindescr like 'Coordinate System' and LDTableName is not null

select distinct LDTableName FROM ListDomainTableInfo
WHERE LDTableName IS NOT NULL and ServerName = 'DRASSQL2019'
AND DBName = 'DRAS_IRASv6_TEST_6_4_0_QA'

select * from 

----------------- name by domaindescr ---------------

-- Domaindescr with more than 1 LD table name (may return some values)
SELECT DomainDescr, Count(DISTINCT LDTableName) NUmber_Of_LDTables
from ListDomainTableInfo
WHERE DomainDescr IS NOT NULL and ServerName = 'DRASSQL2017'
AND DBName = 'DRAS_IRASV6_DEMO_DE_STAGE'
group by DomainDescr
HAVING Count(DISTINCT LDTableName) > 1
ORDER BY 1, 2

SELECT DISTINCT ServerName, DBName, 
TableName, ColumnName, LDTableName, DomainDescr
from ListDomainTableInfo tab1
where   EXISTS ( SELECT DomainDescr, Count(DISTINCT LDTableName)
from ListDomainTableInfo tab2
WHERE DomainDescr IS NOT NULL  
AND ServerName = 'DRASSQL2017' AND DBName = 'DRAS_IRASV6_DEMO_DE_STAGE'
AND tab1.DomainDescr = tab2.DomainDescr
group by DomainDescr
HAVING Count(DISTINCT LDTableName) > 1)
AND ServerName = 'DRASSQL2017' AND DBname = 'DRAS_IRASV6_DEMO_DE_STAGE'
ORDER BY DomainDescr--, TableName, ColumnName

SELECT  tmp.TableName, tmp.ColumnName, count(*) FROM (
SELECT distinct ldti.TableName, ldti.ColumnName, ldti.LDTableName 
FROM dbo.ListDomainTableInfo ldti WHERE ldti.LDTableName IS NOT null) tmp
WHERE TableName is not null
GROUP BY tmp.TableName, tmp.ColumnName HAVING count(*) > 1

--Coating Type - Line
--Failure Pressure Algorithm
--ILI Call Box Interaction rule
--ILI Defect Status
--ILI Feature Grading 1 - Response Time
--ILI Non Corrosion Defect
--ILI Non Crsn Dfct Status
--ILI Tool

------------------------ name based on domain descr -----------------

-- LD tables with more than 1 domain descr
SELECT LDTableName, Count(DISTINCT DomainCatalogId) Number_of_DomainDescr
from ListDomainTableInfo
WHERE DomainDescr IS NOT NULL and ServerName = 'DRASSQL2017'
AND DBName = 'DRAS_IRASV6_DEMO_DE_STAGE'
group by LDTableName
HAVING Count(DISTINCT DomainDescr) > 1
ORDER BY 1, 2

SELECT DISTINCT LDTableName, DomainDescr
from ListDomainTableInfo tab1
where exists (SELECT LDTableName, Count(DISTINCT DomainCatalogId)
from ListDomainTableInfo tab2
WHERE tab1.LDTableName = tab2.LDTableName AND DomainDescr IS NOT NULL 
--and ServerName = 'DRASSQL2017'
--AND DBName = 'DRAS_IRASV6_DEMO_DE_STAGE'
group by LDTableName
HAVING Count(DISTINCT DomainDescr) > 1)  
--AND ServerName = 'DRASSQL2017'
--AND DBname = 'DRAS_IRASV6_DEMO_DE_STAGE' 
and DomainDescr IS NOT NULL
order by LDTableName, DomainDescr

SELECT tab2.Id, tab2.DomainCatalogId, tab2.Code, tab2.Descr, tab1.DomainDescr
FROM DRASSQL2017.DRAS_IRASV6_DEMO_DE_STAGE.dbo.Temp_DomainCatalog tab1
JOIN DRASSQL2017.DRAS_IRASV6_DEMO_DE_STAGE.dbo.Temp_ListDomain tab2
ON tab1.Id = tab2.DomainCatalogId
WHERE DomainDescr in (SELECT DISTINCT DomainDescr
from ListDomainTableInfo
where LDTableName  = 'LD_CoatingConditionApplicationType' 
AND ServerName = 'DRASSQL2017'
AND DBname = 'DRAS_IRASV6_DEMO_DE_STAGE') order by tab2.Code

SELECT DISTINCT ServerName, DBName, TableName, ColumnName, LDTableName, DomainDescr
from ListDomainTableInfo
where LDTableName IS NULL -- = 'LD_MetalLossType' 
AND ServerName = 'DRASSQL2017'
AND DBname = 'DRAS_IRASV6_DEMO_DE_STAGE'
--select DomainDescr, DBName, count(LDTableName) from (
--select DISTINCT LDTableName, DBName, DomainDescr from ListDomainTableInfo where DomainDescr is not null) tmp
--group by DomainDescr, DBName
--having count(LDTableName) > 1
--order by 1

--SELECT * from ListDomainTableInfo where LDTableName is null

--select DISTINCT TableName, ColumnName, DomainDescr, 
--LDTableName 
--from ListDomainTableInfo 
--where LDTableName like '%ILI%Defect%' 
--ORDER BY LDTableName, ColumnName, TableName

--select DISTINCT TableName, ColumnName, DomainDescr, 
--LDTableName 
--from ListDomainTableInfo 
--where LDTableName like '%Fail%Pres%' 
--ORDER BY LDTableName, ColumnName, TableName

--select DISTINCT TableName, ColumnName, DomainDescr, 
--LDTableName 
--from ListDomainTableInfo 
--where LDTableName like '%Pipe%Mater%' 
--ORDER BY LDTableName, ColumnName, TableName


-- Query I came up with to find the most repeated LD table name for a column-table combo and use that as the 
LD table name

SELECT  tmp.TableName, 
		tmp.ColumnName, 
		(SELECT TOP 1 LDTableName 
		 FROM (SELECT LDTableName, COUNT(*) cnt
				FROM ListDomainTableInfo
				WHERE TableName = tmp.TableName AND Columnname = tmp.ColumnName
				GROUP BY LDTableName
				HAVING COUNT(*) = (SELECT MAX(cnt)
									FROM (SELECT  LDTableName, COUNT(*) cnt
											FROM ListDomainTableInfo 
											WHERE TableName = tmp.TableName AND Columnname = tmp.ColumnName
											GROUP BY LDTableName
										 ) subq
								  )
			) subq2
		) AS LDTableName
		-- COUNT(*) Cnt
--INTO ##MatchTableColumn
FROM (SELECT distinct ldti.TableName, ldti.ColumnName, ldti.LDTableName 
	  FROM dbo.ListDomainTableInfo ldti 
	  WHERE ldti.LDTableName IS NOT null) tmp
WHERE TableName is not null
GROUP BY tmp.TableName, tmp.ColumnName HAVING COUNT(*) > 1


*/