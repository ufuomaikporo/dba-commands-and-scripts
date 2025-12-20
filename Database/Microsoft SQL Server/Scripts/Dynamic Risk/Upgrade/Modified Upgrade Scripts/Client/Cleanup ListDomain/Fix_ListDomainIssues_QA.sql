-------------------------------------- Virtual Tables --------------------------

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Unstable Slope Remediation')
BEGIN
	INSERT INTO DomainCatalog (Id, DomainDescr)
	SELECT MAX(Id) + 1, 'OF Unstable Slope Remediation'
	FROM DomainCatalog
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'OFUnstableSlope' AND ColumnName = 'UnstableSY')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'OFUnstableSlope', 'UnstableSY', Id
	FROM DomainCatalog WHERE DomainDescr = 'OF Unstable Slope Remediation'
END

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'IC Oxygen Contamination')
BEGIN
	INSERT INTO DomainCatalog (Id, DomainDescr)
	SELECT MAX(Id) + 1, 'IC Oxygen Contamination'
	FROM DomainCatalog
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'OxygenC' AND ColumnName = 'OxygenC')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'OxygenC', 'OxygenC', Id
	FROM DomainCatalog WHERE DomainDescr = 'IC Oxygen Contamination'
END

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Flood Remediation')
BEGIN
	INSERT INTO DomainCatalog (Id, DomainDescr)
	SELECT MAX(Id) + 1, 'OF Flood Remediation'
	FROM DomainCatalog
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'OFFloodingRemediation' AND ColumnName = 'OFFloodingRemediation')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'OFFloodingRemediation', 'OFFloodingRemediation', Id
	FROM DomainCatalog WHERE DomainDescr = 'OF Flood Remediation'
END

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ECDA Coating Condition')
BEGIN
	INSERT INTO DomainCatalog (Id, DomainDescr)
	SELECT MAX(Id) + 1, 'ECDA Coating Condition'
	FROM DomainCatalog
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'ECDA' AND ColumnName = 'ECDACoatingCondition')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'ECDA', 'ECDACoatingCondition', Id
	FROM DomainCatalog WHERE DomainDescr = 'ECDA Coating Condition'
END

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Maintenance')
BEGIN
	INSERT INTO DomainCatalog (Id, DomainDescr)
	SELECT MAX(Id) + 1, 'Maintenance'
	FROM DomainCatalog
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'ICMaintenance' AND ColumnName = 'Maintenance')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'ICMaintenance', 'Maintenance', Id
	FROM DomainCatalog WHERE DomainDescr = 'Maintenance'
END

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Blasting Remediation')
BEGIN
	INSERT INTO DomainCatalog (Id, DomainDescr)
	SELECT MAX(Id) + 1, 'OF Blasting Remediation'
	FROM DomainCatalog
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'OFBlastingRemediation' AND ColumnName = 'OFBlastingRemediation')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'OFBlastingRemediation', 'OFBlastingRemediation', Id
	FROM DomainCatalog WHERE DomainDescr = 'OF Blasting Remediation'
END

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Facility Flow Component')
BEGIN
	INSERT INTO DomainCatalog (Id, DomainDescr)
	SELECT MAX(Id) + 1, 'Facility Flow Component'
	FROM DomainCatalog
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'FacilityFlowGroupComponent' AND ColumnName = 'FacilityFlowComponentDomainId')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'FacilityFlowGroupComponent', 'FacilityFlowComponentDomainId', Id
	FROM DomainCatalog WHERE DomainDescr = 'Facility Flow Component'
END

------------------------------------------------- Non-Virtual Tables --------------------------------------------

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Datum')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Datum' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Coordinate Projection')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Coordinate Projection' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Datum')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Datum' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Right of Way Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Right of Way Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Facility Flow Product Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Facility Flow Product Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Right of Way Owner')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Right of Way Owner' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Pipe Subtype')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Pipe Subtype' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Fabrication Manufacturing Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Fabrication Manufacturing Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Tank Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Tank Type' FROM DomainCatalog          END

