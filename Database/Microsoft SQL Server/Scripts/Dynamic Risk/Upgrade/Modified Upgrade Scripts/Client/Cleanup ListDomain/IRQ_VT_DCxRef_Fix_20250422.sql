---- IRQ VTs with no DCxRefs, which is required for 6.5.1
/* List to be fixed
Query: 

SELECT vc.VirtualColumnName, vc.VirtualColumnDataTypeInd, vt.* FROM dbo.VirtualTable vt 
INNER JOIN dbo.VirtualColumn vc ON vc.VirtualTableId = vt.Id AND vc.VirtualColumnDataTypeInd = 'L'
WHERE NOT EXISTS (SELECT * FROM dbo.DomainCatalogColXRef xr WHERE vt.VirtualTableName = xr.TableName) ORDER BY vt.VirtualTableName

Output:
CoatingConditionFoundDomainID
ECSoilMacroEnvironment
ECSoilResistivity
ECSoilType
Prox_Downstream_PS
SCCHHistory
SCCNNHistory
StormDamageRM
TPDAdjacentBuriedUtility
TPDROWExposure
TransitionDescription
*/

DECLARE @SQL NVARCHAR(MAX)
SET @SQL = 'ALTER DATABASE ' + DB_NAME() + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE
ALTER DATABASE ' + DB_NAME() + ' SET READ_WRITE
ALTER DATABASE ' + DB_NAME() + ' SET MULTI_USER'

EXECUTE (@SQL)


-- Correction SQL only for IRQ IRAS database (NOT for their NON_PIPE database). Can be ran multiple times with no negative impact.
UPDATE dbo.VirtualColumn SET VirtualColumnDataTypeInd = 'N' WHERE VirtualTableId IN (SELECT Id FROM dbo.VirtualTable WHERE VirtualTableName = 'ECSoilResistivity') AND VirtualColumnName = 'ECSoilResistivity' AND VirtualColumnDataTypeInd = 'L'
UPDATE dbo.DomainCatalogColXRef SET TableName = 'StormDamageRM' WHERE ColumnName = 'StormDamageRM' AND DomainCatalogId = 314 AND TableName <> 'StormDamageRM'

IF NOT EXISTS (SELECT * FROM dbo.DomainCatalog WHERE DomainDescr = 'Adjacent Buried Utility')
	BEGIN
		INSERT INTO dbo.DomainCatalog
		(
			Id,
			DomainDescr
		)
		VALUES
		( (SELECT MAX(Id) + 1 FROM dbo.DomainCatalog), 'Adjacent Buried Utility' )
	END

IF NOT EXISTS (SELECT * FROM dbo.DomainCatalogColXRef WHERE TableName = 'CoatingConditionFoundDomainID')
	BEGIN
		INSERT INTO dbo.DomainCatalogColXRef
		(
			DomainCatalogId,
			TableName,
			ColumnName
		)
		VALUES
		( 46, 'CoatingConditionFoundDomainID', 'CoatingConditionFoundDomainID' )
	END

IF NOT EXISTS (SELECT * FROM dbo.DomainCatalogColXRef WHERE TableName = 'ECSoilMacroEnvironment')
	BEGIN
		INSERT INTO dbo.DomainCatalogColXRef
		(
			DomainCatalogId,
			TableName,
			ColumnName
		)
		VALUES
		( 371, 'ECSoilMacroEnvironment', 'ECSoilMacroEnvironment' )
	END

IF NOT EXISTS (SELECT * FROM dbo.DomainCatalogColXRef WHERE TableName = 'ECSoilType')
	BEGIN
		INSERT INTO dbo.DomainCatalogColXRef
		(
			DomainCatalogId,
			TableName,
			ColumnName
		)
		VALUES
		( 82, 'ECSoilType', 'ECSoilType' )
	END

IF NOT EXISTS (SELECT * FROM dbo.DomainCatalogColXRef WHERE TableName = 'Prox_Downstream_PS')
	BEGIN
		INSERT INTO dbo.DomainCatalogColXRef
		(
			DomainCatalogId,
			TableName,
			ColumnName
		)
		VALUES
		( 123, 'Prox_Downstream_PS', 'Prox_Downstream_PS' )
	END

IF NOT EXISTS (SELECT * FROM dbo.DomainCatalogColXRef WHERE TableName = 'SCCHHistory')
	BEGIN
		INSERT INTO dbo.DomainCatalogColXRef
		(
			DomainCatalogId,
			TableName,
			ColumnName
		)
		VALUES
		( 247, 'SCCHHistory', 'SCCHHistory' )
	END

IF NOT EXISTS (SELECT * FROM dbo.DomainCatalogColXRef WHERE TableName = 'SCCNNHistory')
	BEGIN
		INSERT INTO dbo.DomainCatalogColXRef
		(
			DomainCatalogId,
			TableName,
			ColumnName
		)
		VALUES
		( 246, 'SCCNNHistory', 'SCCNNHistory' )
	END

IF NOT EXISTS (SELECT * FROM dbo.DomainCatalogColXRef WHERE TableName = 'TPDAdjacentBuriedUtility')
	BEGIN
		INSERT INTO dbo.DomainCatalogColXRef
		(
			DomainCatalogId,
			TableName,
			ColumnName
		)
		VALUES
		( (SELECT TOP 1 Id FROM dbo.DomainCatalog WHERE DomainDescr = 'Adjacent Buried Utility'), 'TPDAdjacentBuriedUtility', 'TPDAdjacentBuriedUtility' )
	END

IF NOT EXISTS (SELECT * FROM dbo.DomainCatalogColXRef WHERE TableName = 'TPDROWExposure')
	BEGIN
		INSERT INTO dbo.DomainCatalogColXRef
		(
			DomainCatalogId,
			TableName,
			ColumnName
		)
		VALUES
		( 183, 'TPDROWExposure', 'TPDROWExposure' )
	END

IF NOT EXISTS (SELECT * FROM dbo.DomainCatalogColXRef WHERE TableName = 'TransitionDescription')
	BEGIN
		INSERT INTO dbo.DomainCatalogColXRef
		(
			DomainCatalogId,
			TableName,
			ColumnName
		)
		VALUES
		( 245, 'TransitionDescription', 'TransitionDescription' )
	END

-- Post Run Check (if anyone cares), should have 10 records (initial list minus ECSoilResistivity). If ran before will return 0 records.
SELECT * FROM dbo.DomainCatalogColXRef xr
INNER JOIN dbo.DomainCatalog dc ON dc.Id = xr.DomainCatalogId
WHERE xr.TableName IN ('CoatingConditionFoundDomainID','ECSoilMacroEnvironment','ECSoilResistivity','ECSoilType','Prox_Downstream_PS',
'SCCHHistory','SCCNNHistory','StormDamageRM','TPDAdjacentBuriedUtility','TPDROWExposure','TransitionDescription')


-- Following domaincatalogcolxref need to be updated as they are pointing to the wrong domaincatalog

insert into DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName)
select (select Id from DomainCatalog where DomainDescr = 'FacilityFlowProductType'), 'FacilityFlow', 'FacilityFlowProdTypeDomainId' 
where not exists (select * from DomainCatalogColXRef where TableName = 'FacilityFlow' and ColumnName = 'FacilityFlowProdTypeDomainId')	

GO
IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'OF Flood Ranking')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'OF Flood Ranking'
                        FROM
                                DomainCatalog
                END
GO

Update DomainCatalogColXRef 
SET DomainCatalogId = (Select ID From DomainCatalog where DomainDescr = 'OF Flood Ranking')
where TableName = 'FloodArea' AND ColumnName = 'FloodAreaRangeLD'

GO

Insert into DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName)
select (Select ID From DomainCatalog where DomainDescr = 'OF Flood Ranking'), 'FloodArea', 'FloodAreaLD' 
where not exists (select  * from DomainCatalogColXRef where TableName = 'FloodArea' AND ColumnName = 'FloodAreaLD')

GO


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'FROST AREA RANGE')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'FROST AREA RANGE'
                        FROM
                                DomainCatalog
                END
GO

Update DomainCatalogColXRef 
SET DomainCatalogId = (Select ID From DomainCatalog where DomainDescr = 'FROST AREA RANGE')
where TableName = 'FrostArea' AND ColumnName = 'FrostAreaRangeLD'

GO

	IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Pipe Subtype')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Pipe Subtype'
                        FROM
                                DomainCatalog
                END
GO

Insert into DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName)
select (Select ID From DomainCatalog where DomainDescr = 'Pipe Subtype'), 'PipeSegment', 'PipeSubtypeDomainId' 
where not exists (select  * from DomainCatalogColXRef where TableName = 'PipeSegment' AND ColumnName = 'PipeSubtypeDomainId')

GO

IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Distribution Population Density')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Distribution Population Density'
                        FROM
                                DomainCatalog
                END	
GO

Insert into DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName)
select (Select ID From DomainCatalog where DomainDescr = 'Distribution Population Density'), 'DistPopulationDensity', 'PopulationDensityDomainID' 
where not exists (select  * from DomainCatalogColXRef where TableName = 'DistPopulationDensity' AND ColumnName = 'PopulationDensityDomainID')

GO

	IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Distribution Service Head Susceptibility')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Distribution Service Head Susceptibility'
                        FROM
                                DomainCatalog
                END
GO

Insert into DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName)
select (Select ID From DomainCatalog where DomainDescr = 'Distribution Service Head Susceptibility'), 'DistServiceHeadSuscept', 'ServiceHeadSusceptDomainID' 
where not exists (select  * from DomainCatalogColXRef where TableName = 'DistServiceHeadSuscept' AND ColumnName = 'ServiceHeadSusceptDomainID')

GO

IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'OF Hurricane Ranking')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'OF Hurricane Ranking'
                        FROM
                                DomainCatalog
                END	
GO

Update DomainCatalogColXRef 
SET DomainCatalogId = (Select ID From DomainCatalog where DomainDescr = 'OF Hurricane Ranking')
where TableName = 'HurricaneArea' AND ColumnName = 'HurricaneAreaRangeLD'

GO

IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'OF Seismic Ranking')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'OF Seismic Ranking'
                        FROM
                                DomainCatalog
                END	
GO

Update DomainCatalogColXRef 
SET DomainCatalogId = (Select ID From DomainCatalog where DomainDescr = 'OF Seismic Ranking')
where TableName = 'EarthQuakeArea' AND ColumnName = 'EarthQuakeAreaRangeLD'

GO

IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Right of Way Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Right of Way Type'
                        FROM
                                DomainCatalog
                END
GO

Insert into DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName)
select (Select ID From DomainCatalog where DomainDescr = 'Right of Way Type'), 'RightOfWay', 'ROWTypeDomainId' 
where not exists (select  * from DomainCatalogColXRef where TableName = 'RightOfWay' AND ColumnName = 'ROWTypeDomainId')

GO

IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Right of Way Owner')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Right of Way Owner'
                        FROM
                                DomainCatalog
                END	
GO

Insert into DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName)
select (Select ID From DomainCatalog where DomainDescr = 'Right of Way Owner'), 'RightOfWay', 'ROWOwnerDomainId' 
where not exists (select  * from DomainCatalogColXRef where TableName = 'RightOfWay' AND ColumnName = 'ROWOwnerDomainId')

GO

IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ACVG Survey Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ACVG Survey Type'
                        FROM
                                DomainCatalog
                END	
GO

Insert into DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName)
select (Select ID From DomainCatalog where DomainDescr = 'ACVG Survey Type'), 'ACVGSurvey', 'ACVGSurveyTypeDomainid' 
where not exists (select  * from DomainCatalogColXRef where TableName = 'ACVGSurvey' AND ColumnName = 'ACVGSurveyTypeDomainid')

GO

IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ACVG Survey Equipment')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ACVG Survey Equipment'
                        FROM
                                DomainCatalog
                END
GO

Insert into DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName)
select (Select ID From DomainCatalog where DomainDescr = 'ACVG Survey Equipment'), 'ACVGSurvey', 'ACVGSurveyEquipmentDomainId' 
where not exists (select  * from DomainCatalogColXRef where TableName = 'ACVGSurvey' AND ColumnName = 'ACVGSurveyEquipmentDomainId')

GO

IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ACVG Survey Contractor')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ACVG Survey Contractor'
                        FROM
                                DomainCatalog
                END	
GO

Insert into DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName)
select (Select ID From DomainCatalog where DomainDescr = 'ACVG Survey Contractor'), 'ACVGSurvey', 'ACVGSurveyContractorDomainId' 
where not exists (select  * from DomainCatalogColXRef where TableName = 'ACVGSurvey' AND ColumnName = 'ACVGSurveyContractorDomainId')

GO

IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ACVG Severity Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ACVG Severity Type'
                        FROM
                                DomainCatalog
                END	
GO


Insert into DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName)
select (Select ID From DomainCatalog where DomainDescr = 'ACVG Severity Type'), 'ACVGSurveyAnomaly', 'ACVGAnomalySeverityTypeLD' 
where not exists (select  * from DomainCatalogColXRef where TableName = 'ACVGSurveyAnomaly' AND ColumnName = 'ACVGAnomalySeverityTypeLD')

GO

IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ACVG Anomoly Indication Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ACVG Anomoly Indication Type'
                        FROM
                                DomainCatalog
                END
GO

Insert into DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName)
select (Select ID From DomainCatalog where DomainDescr = 'ACVG Anomoly Indication Type'), 'ACVGSurveyAnomaly', 'ACVGAnomalyIndicationTypeLD' 
where not exists (select  * from DomainCatalogColXRef where TableName = 'ACVGSurveyAnomaly' AND ColumnName = 'ACVGAnomalyIndicationTypeLD')

GO


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Coordinate Projection')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Coordinate Projection'
                        FROM
                                DomainCatalog
                END
GO

Insert into DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName)
select (Select ID From DomainCatalog where DomainDescr = 'Coordinate Projection'), 'Stg_ILI', 'ILICoordProjDomainId' 
where not exists (select  * from DomainCatalogColXRef where TableName = 'Stg_ILI' AND ColumnName = 'ILICoordProjDomainId')

GO


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Datum')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Datum'
                        FROM
                                DomainCatalog
                END
GO

Insert into DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName)
select (Select ID From DomainCatalog where DomainDescr = 'Datum'), 'Stg_ILI', 'ILICoordDatumDomainId' 
where not exists (select  * from DomainCatalogColXRef where TableName = 'Stg_ILI' AND ColumnName = 'ILICoordDatumDomainId')

GO

Insert into DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName)
select (Select ID From DomainCatalog where DomainDescr = 'Datum'), 'Stg_ILI', 'ILIHeightDatumDomainId' 
where not exists (select  * from DomainCatalogColXRef where TableName = 'Stg_ILI' AND ColumnName = 'ILIHeightDatumDomainId')

GO


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ACVG Reading Current Direction')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ACVG Reading Current Direction'
                        FROM
                                DomainCatalog
                END	
GO

Insert into DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName)
select (Select ID From DomainCatalog where DomainDescr = 'ACVG Reading Current Direction'), 'ACVGSurveyReading', 'ACVGReadingCurrentDirection' 
where not exists (select  * from DomainCatalogColXRef where TableName = 'ACVGSurveyReading' AND ColumnName = 'ACVGReadingCurrentDirection')

GO

IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ACVG Reading Coating Conductance')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ACVG Reading Coating Conductance'
                        FROM
                                DomainCatalog
                END
GO


Insert into DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName)
select (Select ID From DomainCatalog where DomainDescr = 'ACVG Reading Coating Conductance'), 'ACVGSurveyReading', 'ACVGReadingCoatingConductance' 
where not exists (select  * from DomainCatalogColXRef where TableName = 'ACVGSurveyReading' AND ColumnName = 'ACVGReadingCoatingConductance')

GO


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ACVG Reading Coating Resistance')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ACVG Reading Coating Resistance'
                        FROM
                                DomainCatalog
                END
GO


Insert into DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName)
select (Select ID From DomainCatalog where DomainDescr = 'ACVG Reading Coating Resistance'), 'ACVGSurveyReading', 'ACVGReadingCoatingResistance' 
where not exists (select  * from DomainCatalogColXRef where TableName = 'ACVGSurveyReading' AND ColumnName = 'ACVGReadingCoatingResistance')

GO


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ACVG Reading Severity Classification')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ACVG Reading Severity Classification'
                        FROM
                                DomainCatalog
                END
GO


Insert into DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName)
select (Select ID From DomainCatalog where DomainDescr = 'ACVG Reading Severity Classification'), 'ACVGSurveyReading', 'ACVGReadingSevClassification' 
where not exists (select  * from DomainCatalogColXRef where TableName = 'ACVGSurveyReading' AND ColumnName = 'ACVGReadingSevClassification')

GO

IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Fabrication Manufacturing Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Fabrication Manufacturing Type'
                        FROM
                                DomainCatalog
                END	
GO


Insert into DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName)
select (Select ID From DomainCatalog where DomainDescr = 'Fabrication Manufacturing Type'), 'Fabrication', 'FabricationManufacturingTypeLd' 
where not exists (select  * from DomainCatalogColXRef where TableName = 'Fabrication' AND ColumnName = 'FabricationManufacturingTypeLd')

GO

IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'PressureClass')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'PressureClass'
                        FROM
                                DomainCatalog
                END	
GO

Insert into DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName)
select (Select ID From DomainCatalog where DomainDescr = 'PressureClass'), 'IncidentDetails', 'PressureClassDomainId' 
where not exists (select  * from DomainCatalogColXRef where TableName = 'IncidentDetails' AND ColumnName = 'PressureClassDomainId')

GO


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Distribution Population Density')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Distribution Population Density'
                        FROM
                                DomainCatalog
                END
GO


Insert into DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName)
select (Select ID From DomainCatalog where DomainDescr = 'Distribution Population Density'), 'IncidentDetails', 'PopulationDensityDomainID' 
where not exists (select  * from DomainCatalogColXRef where TableName = 'IncidentDetails' AND ColumnName = 'PopulationDensityDomainID')

GO

IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Distribution Service Head Susceptibility')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Distribution Service Head Susceptibility'
                        FROM
                                DomainCatalog
                END
GO


Insert into DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName)
select (Select ID From DomainCatalog where DomainDescr = 'Distribution Service Head Susceptibility'), 'IncidentDetails', 'ServiceHeadSusceptDomainID' 
where not exists (select  * from DomainCatalogColXRef where TableName = 'IncidentDetails' AND ColumnName = 'ServiceHeadSusceptDomainID')

GO

IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Facility Flow Component')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Facility Flow Component'
                        FROM
                                DomainCatalog
                END	
GO


Insert into DomainCatalogColXRef (DomainCatalogId, TableName, ColumnName)
select (Select ID From DomainCatalog where DomainDescr = 'Facility Flow Component'), 'FacilityFlowGroupComponent', 'FacilityFlowComponentDomainId' 
where not exists (select  * from DomainCatalogColXRef where TableName = 'FacilityFlowGroupComponent' AND ColumnName = 'FacilityFlowComponentDomainId')

GO









