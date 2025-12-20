--############################################# VIRTUAL TABLES ######################################

SELECT * from versionInfo
select * from TempListDomainTable


-- Foreign key count (varies from db to db)
select COUNT(*) from sys.foreign_keys where OBJECT_NAME(REFERENCED_object_id) like 'LD[_]%'
select COUNT(*) from sys.foreign_keys where OBJECT_NAME(REFERENCED_object_id) like 'Listdomain'  --378

/*check that LDTableName, DomainCatalogId, and New LD id are conistent 
Temp_VirtualTableDataListDomain, Temp_ListDomain, TempListDomainTable, and new LD table
*/
SELECT DISTINCT vtld.LDTableName FROM Temp_VirtualTableDataListDomain vtld
JOIN VirtualColumn vc
ON VTLD.VirtualColumnId = vc.Id
JOIN VirtualTable vt
ON vtld.VirtualTableId =vt.Id
WHERE VirtualColumnDataTypeInd = 'L'

-- chec that tables names are consistent
select * from Temp_ListDomain 
where Old_id in (select Old_DataFieldValueDomainId from Temp_VirtualTableDataListDomain)

-- List of virtal tables taken from VirtualTableDataListDomain	(none should be empty)		
select * from TempListDomainTable
WHERE TableType = 'Virtual'


-- Check that LD table for virtual tables includes Codes, descr for similar domaincatalogid in ListDomain table
SELECT ld.* FROM LD_TPDMarkers tab
left join Temp_ListDomain ld
ON tab.Code = ld.Code
AND tab.Descr = ld.Descr
WHERE LDTableName = 'LD_TPDMarkers'
or ld.domaincatalogId = 100

	select vtld.*
	FROM Temp_VirtualTableDataListDomain vtld
				RIGHT JOIN Temp_ListDomain ld
				ON ld.Old_Id = vtld.Old_DataFieldValueDomainId
				 WHERE --ld.LDTableName = 'LD_TPDMarkers'
				 ld.DomainCatalogId = 100

	select vtld.*
	FROM Temp_ListDomain vtld
				RIGHT JOIN LD_TPDMarkers ld
				ON ld.Id = vtld.New_ID
				 WHERE --ld.LDTableName = 'LD_TPDMarkers'
				 vtld.DomainCatalogId = 100
				 select * from LD_TPDMarkers

select * from Temp_Listdomain where Old_Id = '701107'

--############################################# NON-VIRTUAL TABLES ######################################

--------------------------- check count for ActionItemPropDCXRef, RememberedListDomainValues,  CategoryDataListDomainXRef
-- THIS should return ZEROES
SELECT (select COUNT(*) from ActionItemPropDCXRef) - (SELECT COUNT(*) FROM Temp_ActionItemPropDCXRef)
SELECT (select count(*) from RememberedListDomainValues) - (select count(*) from Temp_RememberedListDomainValues)
SELECT (select count(*) from  CategoryDataListDomainXRef) - (select count(*) from  Temp_CategoryDataListDomainXRef)


--- ---------------------- make sure Temp_Listdomain table has null LD tables only for DELETED domaindescr
-- THIS SHOULD RETURN -1
select distinct domaincatalogId from Temp_ListDomain where LdTableName is null

------------------------------------- spot check data in ActionItemPropDCXRef, RememberedListDomainValues,  CategoryDataListDomainXRef

select top 50  ld.Old_Id, LDTableName, ld.DomaincatalogId, dc.Id as DC_domaincatalogi, ld.DomainDescr, dc.Domaindescr AS DC_domaindescr, code,descr
from Temp_ListDomain ld
join Temp_DomainCatalog dc on dc.Id = ld.DomaincatalogId

select tab1.ListDomainTableName, ld.DomaincatalogId, ld.DomainDescr 
from ActionItemPropDCXRef tab1
join (SELECT DISTINCT LdTableName, domaincatalogId, domaindescr from  Temp_ListDomain) ld
on tab1.ListDomainTableName = ld.LDTableName

select top 60 tab1.ListDomainTableName, ld.DomaincatalogId, ld.DomainDescr 
from RememberedListDomainValues tab1
join (SELECT DISTINCT LdTableName, domaincatalogId, domaindescr from  Temp_ListDomain) ld
on tab1.ListDomainTableName = ld.LDTableName

select top 60 tab1.ListDomainTableName, ld.DomaincatalogId, ld.DomainDescr 
from CategoryDataListDomainXRef tab1
join (SELECT DISTINCT LdTableName, domaincatalogId, domaindescr from  Temp_ListDomain) ld
on tab1.ListDomainTableName = ld.LDTableName

---------------  Check Issues that were brought up by Calvin -----
-- check that the following tables exist
select * from LD_PMMType
SELECT * FROM LD_TPDMarkers


-- The same LD table should be used for the tables below
select distinct ListDomainTableName, ReferencedColumnName, DomainDescr  from  TempListdomaintable 
where ReferencedTableName like 'InlineInspection%' 
and Referencedcolumnname in ('ILITypeDomainId', 'ILIRToolDomainId')

--- should share ld table
SELECT distinct ListDomainTableName, ReferencedColumnName, DomainDescr FROM TempListdomaintable
WHERE Domaindescr in
('Coating Condition - Weld Type'
,'Coating Type - Internal'
,'Internal Coating Type'
,'Coating Condition - Line Type'
,'Coating Type - Line'
,'Coating Type - Weld'
,'Joint Coating Type')

-- should share ld table
select distinct ListDomainTableName, ReferencedColumnName, DomainDescr 
from TempListdomaintable 
where Domaindescr in ('Coating Condition'
,'Coating Condition - Line Found'
,'Coating Condition - Weld Found'
,'Coating Condition Line Found'
,'Coating Condition Weld Found')

/*
select * from TempListDomainTable

select * from Temp_VirtualTableDataListDomain where VirtualTableName = 'MDPressureCycle'
select * from Temp_ListDomain where LDTableName = 'LD_MDPressureCycle'
or domaincatalogId = 260

select New_DataFieldValueDomainId, s.Id, * from Temp_VirtualTableDataListDomain t
join LD_MDPressureCycle s ON t.New_DataFieldValueDomainId = s.Id
where LDTableName = 'LD_MDPressureCycle'

select New_DataFieldValueDomainId,* from Temp_VirtualTableDataListDomain where LDTableName = 'LD_MDPressureCycle' order by 1
select * from LD_MDPressureCycle order by 1

select Old_Id, New_Id, Id, nt.Code, ld.Code, nt.Descr, ld.Descr 
FROM Temp_ListDomain ld
JOIN LD_MDPressureCycle nt
ON ld.Code = nt.Code
AND ld.Descr = nt.Descr
WHERE ld.LDTableName = 'LD_MDPressureCycle'

SELECT distinct LDTableName FROM DRASSQL2019.DrasInternal.dbo.ListDomainTableInfo
WHERE Domaindescr in ('Coating Condition'
,'Coating Condition - Line Found'
,'Coating Condition - Weld Found'
,'Coating Condition Line Found'
,'Coating Condition Weld Found'
)

select distinct code, descr, LDTablename from Temp_Listdomain 
where domaindescr in('Coating Condition'
,'Coating Condition - Line Found'
,'Coating Condition - Weld Found'
,'Coating Condition Line Found'
,'Coating Condition Weld Found'
)order by code
and code not in (select code from LD_CoatingLine)

select distinct domaindescr from Temp_Listdomain where
LDTableName in ('LD_CoatingCondition'
,'LD_CoatingConditionLineFound'
,'LD_CoatingConditionWeldFound')

select * from LD_CoatingLine where code = 'SPC 2888'

select distinct ListDomainTableName, domaindescr 
from TempListdomaintable  where domaindescr like '%Coating%Type%'


SELECT * FROM LD_CoatingCondition
select * from LD_CoatingConditionLineFound
select * from LD_CoatingConditionWeldFound
----------------

select * from LD_CoatingLine  where Code in (select code from LD_CoatingCondition)
select * from LD_CoatingCondition
select * from LD_CoatingConditionApplication
select * from LD_CoatingConditionLineFound
select * from LD_CoatingConditionWeldFound
select * from LD_CoatingInternal
select * from LD_CoatingTypeWeld
SELECT (select COUNT(*) from ActionItemPropDCXRef) - (SELECT COUNT(*) FROM Temp_ActionItemPropDCXRef)

select * from ActionItemPropDCXRef
select * from Temp_ActionItemPropDCXRef
ProductComponent	ProductTypeDomainId

SELECT distinct LDTableName FROM DRASSQL2019.DrasInternal.dbo.ListDomainTableInfo
WHERE Domaindescr in
('Coating Condition - Weld Type'
,'Coating Type - Internal'
,'Internal Coating Type'
,'Coating Condition - Line Type'
,'Coating Type - Line'
,'Coating Type - Weld'
,'Joint Coating Type')

SELECT * FROM DRASSQL2019.DrasInternal.dbo.ListDomainTableInfo
WHERE tablename in (select virtualtablename from Temp_VirtualTableDataListDomain)
*/

