/*
Add missing DomainCatalog and DomainCatalogColXRef entries for 6.5.0 upgrade
*/

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Tank Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Tank Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Datum')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Datum' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Coordinate Projection')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Coordinate Projection' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Datum')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Datum' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Right of Way Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Right of Way Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Facility Flow Product Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Facility Flow Product Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Right of Way Owner')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Right of Way Owner' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Pipe Subtype')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Pipe Subtype' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Fabrication Manufacturing Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Fabrication Manufacturing Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Facility Flow Component')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Facility Flow Component' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Soil Corrosivity')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Soil Corrosivity' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Soil Rock Shapes')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Soil Rock Shapes' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Soil Shrink Swell')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Soil Shrink Swell' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Soil Texture')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Soil Texture' FROM DomainCatalog          END


IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Blasting Remediation')
BEGIN
	INSERT INTO DomainCatalog (Id, domainDescr) 
	SELECT MAX(Id) + 1, 'OF Blasting Remediation'  FROM DomainCatalog
END

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Maintenance')
BEGIN
	INSERT INTO DomainCatalog (Id, domainDescr) 
	SELECT MAX(Id) + 1, 'Maintenance'  FROM DomainCatalog
END

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ECDA Coating Condition')
BEGIN
	INSERT INTO DomainCatalog (Id, domainDescr) 
	SELECT MAX(Id) + 1, 'ECDA Coating Condition'  FROM DomainCatalog
END

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Flood Remediation')
BEGIN
	INSERT INTO DomainCatalog (Id, domainDescr) 
	SELECT MAX(Id) + 1, 'OF Flood Remediation'  FROM DomainCatalog
END

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Oxygen C')
BEGIN
	INSERT INTO DomainCatalog (Id, domainDescr) 
	SELECT MAX(Id) + 1, 'Oxygen C'  FROM DomainCatalog
END

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Unstable Slope Ranking')
BEGIN
	INSERT INTO DomainCatalog (Id, domainDescr) 
	SELECT MAX(Id) + 1, 'OF Unstable Slope Ranking'  FROM DomainCatalog
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'OFBlastingRemediation' AND ColumnName = 'OFBlastingRemediation')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'OFBlastingRemediation', 'OFBlastingRemediation', Id 
	FROM DomainCatalog WHERE DomainDescr = 'OF Blasting Remediation'
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'ICMaintenance' AND ColumnName = 'Maintenance')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'ICMaintenance', 'Maintenance', Id 
	FROM DomainCatalog WHERE DomainDescr = 'Maintenance'
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'ECDA' AND ColumnName = 'ECDACoatingCondition')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'ECDA', 'ECDACoatingCondition', Id 
	FROM DomainCatalog WHERE DomainDescr = 'ECDA Coating Condition'
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'OFFloodingRemediation' AND ColumnName = 'OFFloodingRemediation')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'OFFloodingRemediation', 'OFFloodingRemediation', Id 
	FROM DomainCatalog WHERE DomainDescr = 'OF Flood Remediation'
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'OxygenC' AND ColumnName = 'OxygenC')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'OxygenC', 'OxygenC', Id 
	FROM DomainCatalog WHERE DomainDescr = 'Oxygen C'
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'OFUnstableSlope' AND ColumnName = 'UnstableSY')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'OFUnstableSlope', 'UnstableSY', Id 
	FROM DomainCatalog WHERE DomainDescr = 'OF Unstable Slope Ranking'
END

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Facility Flow Component')
BEGIN
	INSERT INTO DomainCatalog (Id, domainDescr) 
	SELECT MAX(Id) + 1, 'Facility Flow Component'  FROM DomainCatalog
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'FacilityFlowGroupComponent' AND ColumnName = 'FacilityFlowComponentDomainId')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'FacilityFlowGroupComponent', 'FacilityFlowComponentDomainId', Id
	FROM DomainCatalog WHERE DomainDescr = 'Facility Flow Component'
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'SoilsCorrosivity' AND ColumnName = 'SoilsCorrosivity')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'SoilsCorrosivity', 'SoilsCorrosivity', Id
	FROM DomainCatalog WHERE DomainDescr = 'Soil Corrosivity'
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'SoilsRockShapes' AND ColumnName = 'SoilsRockShapes')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'SoilsRockShapes', 'SoilsRockShapes', Id
	FROM DomainCatalog WHERE DomainDescr = 'Soil Rock Shapes'
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'SoilsShrinkSwell' AND ColumnName = 'SoilsShrinkSwell')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'SoilsShrinkSwell', 'SoilsShrinkSwell', Id
	FROM DomainCatalog WHERE DomainDescr = 'Soil Shrink Swell'
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'SoilsTexture' AND ColumnName = 'SoilsTexture')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'SoilsTexture', 'SoilsTexture', Id
	FROM DomainCatalog WHERE DomainDescr = 'Soil Texture'
END
/*
SoilOther	SoilOther
CoatingCondition	CoatingCondition
InternalCondition	InternalCondition
CouponData	CouponData
CasingDescription	CasingDescription

select * from DomainCatalog WHERE Domaindescr like 'Soil%'
*/
IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'CasingDescription' AND ColumnName = 'CasingDescription')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'CasingDescription', 'CasingDescription', Id
	FROM DomainCatalog WHERE DomainDescr = 'Casing Description'
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'CouponData' AND ColumnName = 'CouponData')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'CouponData', 'CouponData', Id
	FROM DomainCatalog WHERE DomainDescr = 'Coupon Type'
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'InternalCondition' AND ColumnName = 'InternalCondition')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'InternalCondition', 'InternalCondition', Id
	FROM DomainCatalog WHERE DomainDescr = 'Internal Condition'
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'CoatingCondition' AND ColumnName = 'CoatingCondition')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'CoatingCondition', 'CoatingCondition', Id
	FROM DomainCatalog WHERE DomainDescr = 'Coating Condition Found'
END

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Soil Other')
BEGIN
	INSERT INTO DomainCatalog (Id, domainDescr) 
	SELECT MAX(Id) + 1, 'Soil Other'  FROM DomainCatalog
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'SoilOther' AND ColumnName = 'SoilOther')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'SoilOther', 'SoilOther', Id
	FROM DomainCatalog WHERE DomainDescr = 'Soil Other'
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'FaultLine_R' AND ColumnName = 'FaultLine_R')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'FaultLine_R', 'FaultLine_R', Id
	FROM DomainCatalog WHERE DomainDescr = 'Stream Hazard Remediation'
END
ELSE
BEGIN
	UPDATE DomainCatalogColXRef SET DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Stream Hazard Remediation')
	WHERE TableName = 'FaultLine_R' AND ColumnName = 'FaultLine_R'
END


