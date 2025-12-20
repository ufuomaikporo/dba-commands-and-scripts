---------------------------------- Virtual Tables ------------------------------

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Soil Corrosivity')
BEGIN
	INSERT INTO DomainCatalog (Id, DomainDescr)
	SELECT MAX(Id) + 1, 'Soil Corrosivity'
	FROM DomainCatalog
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'SoilsCorrosivity' AND ColumnName = 'SoilsCorrosivity')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'SoilsCorrosivity', 'SoilsCorrosivity', Id
	FROM DomainCatalog WHERE DomainDescr = 'Soil Corrosivity'
END

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Soil Rock Shapes')
BEGIN
	INSERT INTO DomainCatalog (Id, DomainDescr)
	SELECT MAX(Id) + 1, 'Soil Rock Shapes'
	FROM DomainCatalog
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'SoilsRockShapes' AND ColumnName = 'SoilsRockShapes')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'SoilsRockShapes', 'SoilsRockShapes', Id
	FROM DomainCatalog WHERE DomainDescr = 'Soil Rock Shapes'
END

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Soil Shrink Swell')
BEGIN
	INSERT INTO DomainCatalog (Id, DomainDescr)
	SELECT MAX(Id) + 1, 'Soil Shrink Swell'
	FROM DomainCatalog
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'SoilsShrinkSwell' AND ColumnName = 'SoilsShrinkSwell')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'SoilsShrinkSwell', 'SoilsShrinkSwell', Id
	FROM DomainCatalog WHERE DomainDescr = 'Soil Shrink Swell'
END

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Soil Texture')
BEGIN
	INSERT INTO DomainCatalog (Id, DomainDescr)
	SELECT MAX(Id) + 1, 'Soil Texture'
	FROM DomainCatalog
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'SoilsTexture' AND ColumnName = 'SoilsTexture')
BEGIN
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
	SELECT 'SoilsTexture', 'SoilsTexture', Id
	FROM DomainCatalog WHERE DomainDescr = 'Soil Texture'
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

-------------------------------------------- Non-Virtual Tables -------------------------------------------

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Distribution Service Head Susceptibility')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Distribution Service Head Susceptibility' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Tank Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Tank Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'PressureClass')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'PressureClass' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Distribution Population Density')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Distribution Population Density' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Datum')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Datum' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Coordinate Projection')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Coordinate Projection' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Datum')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Datum' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Soil Drainage')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Soil Drainage' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Survey Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Survey Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Survey Equipment')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Survey Equipment' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Survey Contractor')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Survey Contractor' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Reading Severity Classification')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Reading Severity Classification' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Reading Current Direction')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Reading Current Direction' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Reading Coating Resistance')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Reading Coating Resistance' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Reading Coating Conductance')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Reading Coating Conductance' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Severity Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Severity Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'FAULT AREA SLIP SENSE')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'FAULT AREA SLIP SENSE' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Anomoly Indication Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Anomoly Indication Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Fault Area Slip Rate')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Fault Area Slip Rate' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'FAULT AREA DIP DIRECTION')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'FAULT AREA DIP DIRECTION' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Right of Way Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Right of Way Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Right of Way Owner')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Right of Way Owner' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Facility Flow Product Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Facility Flow Product Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Pipe Subtype')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Pipe Subtype' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Fabrication Manufacturing Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Fabrication Manufacturing Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Distribution Service Head Susceptibility')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Distribution Service Head Susceptibility' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Distribution Population Density')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Distribution Population Density' FROM DomainCatalog          END

