SELECT * FROM ListDomain WHERE Id IN (SELECT DISTINCT ILICBFailPressAlgthmDomainId FROM InlineInspectionCrsnCallBox)
--SELECT * FROM ListDomain WHERE Id IN (SELECT DISTINCT ListDomainID FROM RememberedListDomainValues)
SELECT * FROM ListDomain WHERE Id IN (SELECT DISTINCT CoatingLineDomainId FROM POECoatingProperty)
group by code
having COUNT(code) > 1
SELECT * FROM ListDomain WHERE Id IN (SELECT DISTINCT ILINCDStatusDomainId FROM InlineInspectionNonCrsnDfct)
SELECT * FROM ListDomain WHERE Id IN (SELECT DISTINCT StructureTypeDomainId FROM StructureAreaFill)
SELECT * FROM ListDomain WHERE Id IN (SELECT DISTINCT ILICBStatusDomainId FROM InlineInspectionCrsnCallBox)

--Real	InCrsnCallBoxILICBStatusLD	InlineInspectionCrsnCallBox	ILICBStatusDomainId	29	ILI Defect Status
--StructAreaFillStructureTypeLD	StructureTypeDomainId	StructureAreaFill
--SELECT * FROM ListDomain	WHERE Id IN (SELECT DISTINCT DataFieldValueDomainId FROM VirtualTableDataListDomain)
select * from ##LDTables where fktablename = 'InlineInspectionNonCrsnDfct'
and fkcolumnname = 'CFRGrading2DomainID'
--488	FK_ILINCDCFRGrading2DomainID	InlineInspectionNonCrsnDfct	CFRGrading2DomainID	NULL	NULL	NULL
SELECT * FROM DomainCatalogColXRef
where tablename = 'CFRGrading2DomainID'
and ColumnName = 'CFRGrading2DomainID'

select distinct CFRGrading2DomainID from InlineInspectionNonCrsnDfct

--ILINCDStatusDomainId	InlineInspectionNonCrsnDfct
SELECT * FROM TMC_IRASv6_CONFIG..TempListDomainTable
WHERE tableType = 'Real'
SELECT * FROM RememberedListDomainValues

select * from InNonCrsnDfctILINCDStatusLD 

SELECT * FROM ListDomain WHERE DomainCatalogId IN (29,27)
SELECT * FROM DomainCatalog WHERE Id = 14 --IN (27,29)

SELECT * FROM DomainCatalogColXRef
where DomainCatalogId = 14 --in (27,29, )

SELECT * FROM ##ListDomainInfo
where DomainCatalogId <> 27

SELECT * FROM SoilClassificationVTLD
SELECT * FROM TPDPublicAwarenessVTLD
SELECT * FROM TPDPatrolFrequencyVTLD
SELECT * FROM TPDMarkersVTLD
SELECT * FROM ParkVTLD

UPDATE InlineInspectionCrsnCallBox
SET ILICBFailPressAlgthmDomainId = NULL
WHERE ILICBFailPressAlgthmDomainId IN (29, 83, 10150)



SELECT * FROM InlineInspectionCrsnCallBox
WHERE ILICBFailPressAlgthmDomainId IN (29, 83, 10150)

SELECT * FROM domaincatalog where id in (27,29)

SELECT * INTO tmp_ListDomain FROM ListDomain

InNonCrsnDfctILINCDStatusLD	ILINCDStatusDomainId	InlineInspectionNonCrsnDfct	FK_ILINCDStatusDomainId


ALTER TABLE InlineInspectionNonCrsnDfct DROP CONSTRAINT FK_ILINCDStatusDomainId
ALTER TABLE InlineInspectionNonCrsnDfct ADD CONSTRAINT FK_ILINCDStatusDomainId FOREIGN KEY (ILINCDStatusDomainId) 
						REFERENCES InNonCrsnDfctILINCDStatusLD(Id)




-------------------------------------------------------------------------------------


select * from DomainCatalog
WHERE Id in (43,
44,
45,
46,
228,
247,
248,
249,
250,
251)
order by 2

select * from DomainCatalogColXRef WHERE domainCatalogId IN (250, 43)
SELECT * FROM Listdomain where domaincatalogId in (250, 43)--(250, 43)
select * from ##LDTables where domaincatalogId in (250, 43)

-- 250, 43
-- 248, 46
-- 249, 44
-- 247, 228


SELECT DISTINCT CoatingLineDomainId FROM POECoatingProperty

SELECT DISTINCT CoatingLineDomainId FROM POECoatingProperty
WHERE CoatingLineDomainId in 

sp_help Casing


SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Column_Name LIKE '%DomainId'

SELECT * FROM tmp_TrackListDomainChanges
where OldDomainId <> NewDomainId


SELECT * FROM TMC_IRASv6_CONFIG..TempListDomainTable
WHERE TableType = 'Virtual' 
ORDER BY 5, 4

select * from FailurePressureAlgorithmLD
SELECT * FROM SoilTypeLD-- SoilClassificationLD,, OFUnstableSlopeRemediationLD (empty), ENVStreamTraceLengthRangeLD
'coordsys'
'FailPressAlgthm'
'OF%Remediation'
select * from DomainCatalog where DomainDescr like 'Density'

SELECT * FROM TMC_IRASv6_CONFIG..TempListDomainTable 
WHERE ReferencedColumnName IN (
SELECT ReferencedColumnName FROM TMC_IRASv6_CONFIG..TempListDomainTable
WHERE DomainCatalogId IS NULL)
ORDER BY 4


UPDATE InlineInspectionCrsnCallBox
SET ILICBFailPressAlgthmDomainId = NULL
WHERE ILICBFailPressAlgthmDomainId IN (29, 83, 10150)

UPDATE InlineInspectionNonCrsnDfct 
SET ILINCDStatusDomainId = 10147
	WHERE ILINCDStatusDomainId = 10150


select * from domaincatalog where domaindescr like 'Structure%'
SELECT * FROM DomainCatalogColXRef where tablename = 'InlineInspectionFeature' and columnname = 'ILIFCoordSysDomainId'

--########################## Find all Virtual table list domain entries for specified domainCatalogId #####################

select * from LD_ENVOutflowVolumeRange
select * from LD_SoilClassification
select * from LD_StrayCurrentInterference

SELECT * FROM TempListDomainTable 
WHERE DomainCatalogId is null LIKE '%ENVOutflowVolumeRange%'

select * from Listdomain
where DomainCatalogId = 415
UNION
SELECT * FROM  ListDomain
WHERE Id IN (SELECT ENVOutflowVolumeRange FROM ENVOutflowVolumeRange)
--ENVOutflowVolumeLeakRange ENVOutflowVolumeRuptureRange

SELECT * FROM ListDomain 
WHERE Id IN (SELECT DataFieldValueDomainId FROM VirtualTableDataListDomain
			 WHERE VirtualTableId IN (SELECT Id FROM VirtualTable WHERE VirtualTableName = 'ECSoilMacroEnvironment')
			 AND VirtualColumnId IN (SELECT Id FROM VirtualColumn WHERE VirtualColumnName = 'ECSoilMacroEnvironment')
			 )

SELECT vc.VirtualColumnName, vt.VirtualTableName, COUNT(*) count --VirtualTableStationingId, DataFieldValueDomainId 
FROM VirtualTableDataListDomain vtdld
JOIN VirtualTable vt
	ON vt.Id = vtdld.VirtualTableId
JOIN VirtualColumn vc
	ON vc.Id = vtdld.VirtualColumnId
GROUP BY vc.VirtualColumnName, vt.VirtualTableName

SELECT DISTINCT Id, Code, Descr FROM ListDomain 
WHERE Id IN (SELECT DISTINCT ILIRToolDomainId FROM InlineInspectionRange
			UNION
			SELECT DISTINCT ILIRToolDomainId FROM Stg_ILIRange
			UNION
			SELECT DISTINCT ILITypeDomainId FROM InlineInspection
			UNION
			SELECT DISTINCT ILITypeDomainId FROM Stg_ILI)
EXCEPT
SELECT Id, Code, Descr FROM ILIToolLD
order by 2

--######################## CHECK FOR DUPLICATE CODE ENTRIES IN NEW LISTDOMAIN ###################
SELECT * FROM TempListDomainTable 
where ListDomainTableName like '%PMM%'

SELECT * FROM TempListDomainTable
WHERE ListDomainTableName like 'LD_CD%'

SELECT * FROM TempListDomainTable
where ListDomainTableName = 'LD_SoilType'

select * from ListDomain where DomainCatalogId = 141

select * from DomainCatalog where DomainDescr like 'Soil%Type%'
select * from LD_SoilType  --206
select * from LD_ILIFacilityType --65

		select * from ##NewDomainTableList
		where FKColumnName is NOT NULL and DomainCatalogId is null
		ORDER BY FKColumnName

		select * from TempListDomainTable
		where ReferencedColumnName is NOT NULL and ReferencedColumnName like '%Coord%sys%'
		ORDER BY ReferencedColumnName

		select ListDomainTableName from TempListDomainTable
		where ReferencedColumnName is NOT NULL and DomainCatalogId is null
		ORDER BY DomainCatalogId

		select * from LD_ValveTypeValveTypeClosureProfile
		select * from DomainCatalog where DomainDescr like '%Grading%'

		select * from LD_TankTankType

select * from InlineInspectionJoint
select * from DomainCatalog where Id=294

select * from LD_ProductType --33
ORDER BY Code

SELECT * FROM sys.tables 
WHERE name IN ('Category', 'CategoryDataListDomainXRef'
, 'ListDomain', 'DomainCatalog', 'DomainCatalogColXRef')

select TOP 5 * FROM RememberedListDomainValues 
select TOP 5 * FROM ActionItemPropDCXRef


select * from Listdomain where DomainCatalogId = 266

select * from ListDomain where id in (select ProductDomainId from OperatingData)

select * from ListDomain where id = 607123
select * from DomainCatalog where id = 266

SELECT * FROM 



DECLARE @SQL NVARCHAR(MAX)
DECLARE @TableName NVARCHAR(100) = 'SoilTypeLD'

SET @SQL = 'SELECT * FROM '+@TableName+' WHERE Code IN
(
SELECT Code FROM (
select code, COUNT(Code) cnt from '+@TableName+'
GROUP BY Code HAVING COUNT(Code) >1) tmp
)
order by 2'

EXECUTE (@SQL)

--################### CHECK ActionItemPropDCXRef and RememberedListDomainValues  ######################################

 SELECT * FROM ActionItemPropDCXRef
 SELECT * FROM RememberedListDomainValues

SELECT * FROM ##NewDomainTableList WHERE FKColumnName in (
SELECT FKColumnname from (
SELECT FKColumnName, Count(FKColumnName) cnt FROM ##NewDomainTableList
GROUP BY FKColumnname
HAVING COUNT(FKColumnName) > 1) st
)  
ORDER BY DomainCatalogId

--No rows should return
select * from ##NewDomainTableList
WHERE NewListDomainTable is null

-- No rows should return
SELECT * FROM ##NewDomainTableList
WHERE FKColumnName IN (SELECT FKColumnName FROM ##NewDomainTableList WHERE DomainCatalogId IS NOT NULL)
AND DomainCatalogId IS NULL

-- There should be around 100 returned rows
SELECT * FROM ##NewDomainTableList
 WHERE 
 (REPLACE(FKColumnName, 'DomainId', '') 
                        IN (SELECT REPLACE(DomainDescr, ' ', '') FROM DomainCatalog)
                    OR REPLACE(FKColumnName, 'Ld', '') 
                        IN (SELECT REPLACE(DomainDescr, ' ', '') FROM DomainCatalog)) AND
 DomainCatalogId IS NULL





SELECT TOP 1 NewListDomainTable, DomainCatalogId, DomainDescr
FROM ##NewDomainTableList 
WHERE DomainCatalogId = (SELECT Id FROM DomainCatalog
							WHERE REPLACE(DomainDescr, ' ', '') 
							IN ( REPLACE('ILIToolDomainId', 'DomainId', ''), REPLACE('ILIToolDomainId', 'Ld', ''))
							) 
