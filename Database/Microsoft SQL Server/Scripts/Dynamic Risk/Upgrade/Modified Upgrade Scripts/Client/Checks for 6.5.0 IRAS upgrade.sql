--############################################# VIRTUAL TABLES ######################################
DECLARE @flag INT
DECLARE @SQL NVARCHAR(MAX)

SELECT DBVersion, DBVersionCheckPoint from versionInfo

SELECT * FROM sys.foreign_keys where OBJECT_NAME(referenced_object_id) like 'LD[_]%'


select * from TempListdomainTable where LDTableNamee like '%Crack%'
select * from Temp_Listdomain where ldtablename like '%Crack%'

/*
Check that the LDTableName, DomainCatalogId, and New LD Ids are conistent in
Temp_VirtualTableDataListDomain, Temp_ListDomain, TempListDomainTable, and new LD table
*/

SELECT @flag = COUNT(*)
FROM Temp_VirtualTableDataListDomain vtld
JOIN Temp_ListDomain ld
ON ld.Old_Id = vtld.Old_DataFieldValueDomainId
JOIN TempListDomainTable tmp
ON vtld.VirtualTableName = tmp.TableName
AND vtld.VirtualColumnName = tmp.ColumnName
WHERE New_Id <> vtld.New_DataFieldValueDomainId 
	OR vtld.LDTableName <> ld.LDTableName OR vtld.LDTableName <> tmp.LDTableNamee
	OR ld.LDTableName <> tmp.LDTableNamee 
	or vtld.DomainDescr <> ld.DomainDescr or vtld.DomainDescr <> tmp.DomainDescr
	or ld.DomainDescr <> tmp.DomainDescr

IF @Flag <> 0
BEGIN
	SET @SQL = 'SELECT  vtld.Old_DataFieldValueDomainId
			,ld.Old_Id
			,vtld.New_DataFieldValueDomainId
			,ld.New_Id
			,vtld.LDTableName VirtualTableDataListDomain_TableName
			,ld.LDTableName ListDomain_LDTableName
			,tmp.LDTableNamee TempListDomainTable_TableName
			,vtld.DomainDescr VirtualTableDataListDomain_DomainDescr
			,ld.DomainDescr ListDomain_DomainDescr
			,tmp.DomainDescr TempListDomainTable_DomainDescr
	FROM Temp_VirtualTableDataListDomain vtld
	JOIN Temp_ListDomain ld
	ON ld.Old_Id = vtld.Old_DataFieldValueDomainId
	JOIN TempListDomainTable tmp
	ON vtld.VirtualTableName = tmp.TableName
	AND vtld.VirtualColumnName = tmp.ColumnName
	WHERE 
	New_Id <> vtld.New_DataFieldValueDomainId 
		OR vtld.LDTableName <> ld.LDTableName OR vtld.LDTableName <> tmp.LDTableNamee
		OR ld.LDTableName <> tmp.LDTableNamee 
		or vtld.DomainDescr <> ld.DomainDescr or vtld.DomainDescr <> tmp.DomainDescr
		or ld.DomainDescr <> tmp.DomainDescr
	ORDER BY ld.LDTableName, new_id;
	
	THROW 51001, N''The New LD table name, DomainCatalogId, and New ListDomain Ids are inconistent in the following tables: '+CHAR(10)
	+ 'Temp_VirtualTableDataListDomain, Temp_ListDomain, TempListDomainTable'+CHAR(10) + CHAR(10)
	+ 'These columns must match across these tables. ' + CHAR(10)+ CHAR(10) +'The inconsistent rows are in the Results tab'', 1'

	EXECUTE (@SQL)
END



----------------------- Check that all LD tables in the TempListDomainTable are created ------------------------

SELECT @flag = COUNT(*) 
FROM TempListDomainTable
WHERE LDTableNamee NOT IN (SELECT name FROM sys.tables)

IF @flag <> 0 
BEGIN
	SET @SQL = 'SELECT LDTableNamee FROM  TempListDomainTable
				WHERE LDTableNamee NOT IN (SELECT name FROM sys.tables);
	
	THROW 51001, N''Some LD tables listed in the Results tab are listed in the TempListDomainTable table but were not created'', 1;'

	EXECUTE (@SQL)

END

---------------------------- Check LD tables created for virtual table columns ------------------------

--Check that an LD table is created for all virtual table columns with an 'L' datatype indicator

SELECT @flag = COUNT(*) from virtualcolumn vc
JOIN VirtualTable vt
ON vc.VirtualTableId = vt.Id
LEFT JOIN TempListDomainTable tmp
ON vc.VirtualColumnName = tmp.ColumnName
AND vt.VirtualTableName = tmp.TableName
where virtualcolumndatatypeind = 'L'
AND tmp.LDTableNamee IS NULL

IF @flag != 0
BEGIN
	SET @SQL = 'SELECT vc.Id AS VirtualColumnId, 
						vc.VirtualColumnName,
						vc.VirtualTableId, 
						vt.VirtualTableName
				FROM virtualcolumn vc
				JOIN VirtualTable vt
				ON vc.VirtualTableId = vt.Id
				LEFT JOIN TempListDomainTable tmp
				ON vc.VirtualColumnName = tmp.ColumnName
				AND vt.VirtualTableName = tmp.TableName
				where virtualcolumndatatypeind = ''L''
				AND tmp.LDTableNamee IS NULL
			
				THROW 51001, N''An LD table was not created for the virtual tables listed in the results tab'', 1'

	EXECUTE (@SQL)
END


----------- Check that all LD tables in VirtualTableDataListDomain table have data in them ---------------

SET @flag = NULL

SELECT @SQL = 'SELECT @Result = 1
WHERE ' + STRING_AGG(' EXISTS (SELECT * FROM ' + LDTableName + ')', CHAR(10) + ' AND ')
FROM Temp_VirtualTableDataListDomain

EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @Result = @flag OUTPUT;


IF @flag <> 1
BEGIN
	THROW 51001, N'Some of the LD tables are missing data. No table from the VirtualTableDataListDomain table should be empty', 1;
END

--------------- Check if the data in the ListDomain table matches data in LD table ----------------

IF OBJECT_ID('tempdb..##TempListDomainTable') IS NOT NULL
BEGIN
	DROP TABLE ##TempListDomainTable
END


/*
USE DRAS_IRASv6_DEMO_QA_Ufuoma_Test
use DRAS_IRASV6_DATAEXCHANGE_LINK_Ufuoma_Test

SELECT * FROM versioninfo

select distinct ldtableName from Temp_ListDomain where ldtablename not in (
select distinct ldtablename from TempListDomainTable)

-- Foreign key count (varies from db to db)
select COUNT(*) from sys.foreign_keys where OBJECT_NAME(REFERENCED_object_id) like 'LD[_]%'
select COUNT(*) from sys.foreign_keys where OBJECT_NAME(REFERENCED_object_id) like 'Listdomain'  -- ~378

--------------------------- check count for ActionItemPropDCXRef, RememberedListDomainValues,  CategoryDataListDomainXRef
-- THIS should return ZEROES

SELECT 1 
WHERE 0 <> ((SELECT COUNT(*) from ActionItemPropDCXRef) - (SELECT COUNT(*) FROM Temp_ActionItemPropDCXRef))
OR  0 <> ((SELECT count(*) from RememberedListDomainValues) - (select count(*) from Temp_RememberedListDomainValues))
OR 0 <> (SELECT (SELECT COUNT(*) from  CategoryDataListDomainXRef) - (select count(*) from  Temp_CategoryDataListDomainXRef))

--- ---------------------- make sure Temp_Listdomain table has null LD tables only for DELETED domaindescr
-- THIS SHOULD RETURN -1
select distinct domaincatalogId from Temp_ListDomain where LdTableName is null

SELECT * FROM Temp_ListDomain

---------------  Check Issues that were brought up by Calvin -----
-- check that the following tables exist
select * from LD_PMMType
SELECT * FROM LD_TPDMarkers

SELECT distinct code, descr from  temp_virtualtabledatalistdomain where domaindescr = 'TPD Buried  Markers'
select * from TempListDomainTable where domaindescr = 'TPD Buried  Markers'
select * from LD_TPDBuriedMarkers
select * from Temp_ListDomain where ldtablename = 'LD_TPDBuriedMarkers'
or domaincatalogId = '100'

select * from Temp_ListDomain where ldtablename = 'LD_PMMType'
select * from virtualColumn

-- The same LD table should be used for the tables below
select distinct LDTableNamee, ColumnName, DomainDescr  from  TempListdomaintable 
where TableName like 'InlineInspection%' 
and ColumnName in ('ILITypeDomainId', 'ILIRToolDomainId')

--- Should share ld table
SELECT distinct LDTableNamee, ColumnName, DomainDescr FROM TempListdomaintable
WHERE Domaindescr in
('Coating Condition - Weld Type'
,'Coating Type - Internal'
,'Internal Coating Type'
,'Coating Condition - Line Type'
,'Coating Type - Line'
,'Coating Type - Weld'
,'Joint Coating Type')

-- Should share LD table
select distinct LDTableNamee, ColumnName, DomainDescr 
from TempListdomaintable 
where Domaindescr in ('Coating Condition'
,'Coating Condition - Line Found'
,'Coating Condition - Weld Found'
,'Coating Condition Line Found'
,'Coating Condition Weld Found')

*/