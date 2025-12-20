USE DATASHARE
GO

 

/*
HOW TO

1) Execute the dbo.sp_CreateVirtualTables stored procedure in the DataShare database
2) Execute the dbo.sp_CreateViews stored procedure in the DataShare database
3) Run this script 
4) Run the table loading script 
*/

/************************************************************************************************
		1) Execute the dbo.sp_CreateVirtualTables stored procedure in the DataShare database
************************************************************************************************/

EXECUTE dbo.sp_CreateVirtualTables

PRINT '*************************************************************************'
PRINT 'VIRTUAL TABLES HAVE BEEN CREATED'
PRINT '*************************************************************************'

/************************************************************************************************
2) Execute the dbo.sp_CreateViews stored procedure in the DataShare database
************************************************************************************************/
EXECUTE dbo.sp_CreateViews

PRINT '*************************************************************************'
PRINT 'DATASHARE VIEWS HAVE BEEN REFRESHED'
PRINT '*************************************************************************'

/************************************************************************************************
3) Turn View to flat tables in the DATASHARE2 database
************************************************************************************************/
USE DATASHARE
GO
---------------------------------- Recreate DataShareTablesList Tables ---------------------

---- Query to generate necessary tables for DATASHARE (might need to be updated)
--/*
--SELECT name AS TableName--, CAST('1' AS BIT) AS IsConverted
--FROM Base_IRASv6_STAGE.sys.tables
--WHERE name NOT LIKE 'STG[_]%' AND name NOT LIKE 'DBS[_]%' 
--AND name NOT LIKE 'History[_]%' AND name NOT LIKE 'H[_]%' 
--AND name NOT LIKE 'i[_]%' AND name NOT LIKE 'RISK%'
--AND name NOT LIKE 'Load[_]%' -- AND name NOT LIKE 'VirtualTable%'
--AND name NOT LIKE 'tmp%'
--AND name NOT IN ('Connection', 'ConnectionType', 'DisplayField', 'ScriptTracker', 
--'CategoryDataListDomainXRef', 'DomainCatalog', 'DomainCatalogColXRef')
--AND name NOT IN (SELECT DISTINCT referencedTable 
--							FROM ForeignKeys
--							WHERE referencedTable in (SELECT DISTINCT
--									object_name(c1.object_id) --, c1.name , c2.name 
--								FROM sys.columns c1
--								inner join sys.columns c2
--									on c1.object_id = c2.object_id
--								WHERE c1.name = 'Code'
--								AND c2.name = 'Descr')
--				) 
--*/
----IF OBJECT_ID('dbo.DataShareTablesList') IS NOT NULL
----BEGIN
----	DROP TABLE dbo.DataShareTablesList
----END

--SELECT * FROM DATASHARE.INFORMATION_SCHEMA.tables 
--where table_name not like 'temp%' 
--AND table_name NOT LIKE 'tmp%'
--and table_name NOT LIKE 'VirtualTable%'
--AND table_name NOT LIKE '%[_][0-9]'
--AND table_name NOT LIKE 'Load_%'
--AND table_type = 'VIEW'
--order by table_name

IF OBJECT_ID('DataShareTablesList') IS NOT NULL
BEGIN
	DROP TABLE DataShareTablesList
END
GO

CREATE TABLe DataShareTablesList (TableName VARCHAR(250) , IsConverted BIT DEFAULT(1) )
GO

BEGIN TRANSACTION
INSERT INTO DataShareTablesList VALUES ( 'Corporation', 1)
INSERT INTO DataShareTablesList VALUES ( 'OperatingUnit', 1)
INSERT INTO DataShareTablesList VALUES ( 'PipelineSystem', 1)
INSERT INTO DataShareTablesList VALUES ( 'ListDomain', 1)
INSERT INTO DataShareTablesList VALUES ( 'LineLoop', 1)
INSERT INTO DataShareTablesList VALUES ( 'DischargeSubsystem', 1)
INSERT INTO DataShareTablesList VALUES ( 'StationSeries', 1)
INSERT INTO DataShareTablesList VALUES ( 'DistBusinessDistrict', 1)
INSERT INTO DataShareTablesList VALUES ( 'MLVSection', 1)
INSERT INTO DataShareTablesList VALUES ( 'MLVCorrection', 1)
INSERT INTO DataShareTablesList VALUES ( 'ActionItem', 1)
INSERT INTO DataShareTablesList VALUES ( 'AppTables', 1)
INSERT INTO DataShareTablesList VALUES ( 'AppList', 1)
INSERT INTO DataShareTablesList VALUES ( 'ActionItemComments', 1)
INSERT INTO DataShareTablesList VALUES ( 'ActionItemRange', 1)
INSERT INTO DataShareTablesList VALUES ( 'ActionItemRevision', 1)
INSERT INTO DataShareTablesList VALUES ( 'ActionItemProperty', 1)
INSERT INTO DataShareTablesList VALUES ( 'ActionItemPropDCXRef', 1)
INSERT INTO DataShareTablesList VALUES ( 'ActionItemPropertyValue', 1)
INSERT INTO DataShareTablesList VALUES ( 'ACVGSurvey', 1)
INSERT INTO DataShareTablesList VALUES ( 'ACVGSurveyAnomaly', 1)
INSERT INTO DataShareTablesList VALUES ( 'ACVGSurveyRange', 1)
INSERT INTO DataShareTablesList VALUES ( 'ACVGSurveyReading', 1)
INSERT INTO DataShareTablesList VALUES ( 'AlignmentRange', 1)
INSERT INTO DataShareTablesList VALUES ( 'BellHoleExcavation', 1)
INSERT INTO DataShareTablesList VALUES ( 'Bend', 1)
INSERT INTO DataShareTablesList VALUES ( 'BendRemark', 1)
INSERT INTO DataShareTablesList VALUES ( 'CalcClassArea', 1)
INSERT INTO DataShareTablesList VALUES ( 'CalcClassStructXref', 1)
INSERT INTO DataShareTablesList VALUES ( 'CalcLeakTimeProfile', 1)
INSERT INTO DataShareTablesList VALUES ( 'CalcOutflowLeakProfile', 1)
INSERT INTO DataShareTablesList VALUES ( 'CalcOutflowStatistics', 1)
INSERT INTO DataShareTablesList VALUES ( 'CalcOutflowStatisticsType', 1)
INSERT INTO DataShareTablesList VALUES ( 'CalcOutflowValveProfile', 1)
INSERT INTO DataShareTablesList VALUES ( 'CalcOverlandLeakProfile', 1)
INSERT INTO DataShareTablesList VALUES ( 'Calculator', 1)
INSERT INTO DataShareTablesList VALUES ( 'CalculatorKind', 1)
INSERT INTO DataShareTablesList VALUES ( 'CalculatorParameters', 1)
INSERT INTO DataShareTablesList VALUES ( 'CalculatorProject', 1)
INSERT INTO DataShareTablesList VALUES ( 'CalculatorProjectSelection', 1)
INSERT INTO DataShareTablesList VALUES ( 'CalculatorType', 1)
INSERT INTO DataShareTablesList VALUES ( 'Casing', 1)
INSERT INTO DataShareTablesList VALUES ( 'CasingRemark', 1)
INSERT INTO DataShareTablesList VALUES ( 'CASurvey', 1)
INSERT INTO DataShareTablesList VALUES ( 'CASurveyRange', 1)
INSERT INTO DataShareTablesList VALUES ( 'CASurveyReading', 1)
INSERT INTO DataShareTablesList VALUES ( 'Category', 1)
INSERT INTO DataShareTablesList VALUES ( 'UnitOfMeasure', 1)
INSERT INTO DataShareTablesList VALUES ( 'CategoryDataNumXRef', 1)
INSERT INTO DataShareTablesList VALUES ( 'CenterlineAlignment', 1)
INSERT INTO DataShareTablesList VALUES ( 'CenterlineAlignmentDependency', 1)
INSERT INTO DataShareTablesList VALUES ( 'CenterlineDefinition', 1)
INSERT INTO DataShareTablesList VALUES ( 'CenterlineMapping', 1)
INSERT INTO DataShareTablesList VALUES ( 'ClassArea', 1)
INSERT INTO DataShareTablesList VALUES ( 'Classification', 1)
INSERT INTO DataShareTablesList VALUES ( 'ClassificationRange', 1)
INSERT INTO DataShareTablesList VALUES ( 'ClassLocationStructCtgry', 1)
INSERT INTO DataShareTablesList VALUES ( 'Coating', 1)
INSERT INTO DataShareTablesList VALUES ( 'CoatingCondition', 1)
INSERT INTO DataShareTablesList VALUES ( 'CoatingDefect', 1)
INSERT INTO DataShareTablesList VALUES ( 'CoatingThickness', 1)
INSERT INTO DataShareTablesList VALUES ( 'ColocateCluster', 1)
INSERT INTO DataShareTablesList VALUES ( 'ColocateCrack', 1)
INSERT INTO DataShareTablesList VALUES ( 'ColocateGirthWeld', 1)
INSERT INTO DataShareTablesList VALUES ( 'ColocateNCD', 1)
INSERT INTO DataShareTablesList VALUES ( 'ColocateSite', 1)
--INSERT INTO DataShareTablesList VALUES ( 'Connection', 1)
--INSERT INTO DataShareTablesList VALUES ( 'ConnectionType', 1)
INSERT INTO DataShareTablesList VALUES ( 'Constant', 1)
INSERT INTO DataShareTablesList VALUES ( 'CorrosionDeposit', 1)
INSERT INTO DataShareTablesList VALUES ( 'Coupon', 1)
INSERT INTO DataShareTablesList VALUES ( 'CouponReading', 1)
INSERT INTO DataShareTablesList VALUES ( 'CoverDepth', 1)
INSERT INTO DataShareTablesList VALUES ( 'CoverDepthProfile', 1)
INSERT INTO DataShareTablesList VALUES ( 'CPRange', 1)
INSERT INTO DataShareTablesList VALUES ( 'CPSurvey', 1)
INSERT INTO DataShareTablesList VALUES ( 'CPSurveyRange', 1)
INSERT INTO DataShareTablesList VALUES ( 'CPSurveyReading', 1)
INSERT INTO DataShareTablesList VALUES ( 'CrackAnomaly', 1)
INSERT INTO DataShareTablesList VALUES ( 'CrackAnomalyCluster', 1)
INSERT INTO DataShareTablesList VALUES ( 'Crossing', 1)
INSERT INTO DataShareTablesList VALUES ( 'CrossingLocn', 1)
INSERT INTO DataShareTablesList VALUES ( 'DamagePrevention', 1)
INSERT INTO DataShareTablesList VALUES ( 'DataManagerCategory', 1)
INSERT INTO DataShareTablesList VALUES ( 'DataManagerField', 1)
INSERT INTO DataShareTablesList VALUES ( 'DataManagerTable', 1)
INSERT INTO DataShareTablesList VALUES ( 'Date', 1)
INSERT INTO DataShareTablesList VALUES ( 'DBS_Links', 1)
INSERT INTO DataShareTablesList VALUES ( 'DCVGSurvey', 1)
INSERT INTO DataShareTablesList VALUES ( 'DCVGSurveyRange', 1)
INSERT INTO DataShareTablesList VALUES ( 'DCVGSurveyAnomaly', 1)
INSERT INTO DataShareTablesList VALUES ( 'DCVGSurveyReading', 1)
INSERT INTO DataShareTablesList VALUES ( 'DesignClass', 1)
--INSERT INTO DataShareTablesList VALUES ( 'DisplayField', 1) -- has type mismatch
INSERT INTO DataShareTablesList VALUES ( 'DistInsideMeter', 1)
INSERT INTO DataShareTablesList VALUES ( 'DistPopulationDensity', 1)
INSERT INTO DataShareTablesList VALUES ( 'DistServiceHeadSuscept', 1)
INSERT INTO DataShareTablesList VALUES ( 'DynamicIntegration', 1)
INSERT INTO DataShareTablesList VALUES ( 'EarthQuakeArea', 1)
INSERT INTO DataShareTablesList VALUES ( 'Elbow', 1)
INSERT INTO DataShareTablesList VALUES ( 'ElectrolytePH', 1)
INSERT INTO DataShareTablesList VALUES ( 'ElevationProfile', 1)
INSERT INTO DataShareTablesList VALUES ( 'ExcavationAttachmentFile', 1)
INSERT INTO DataShareTablesList VALUES ( 'ExcavationAttachmentUrl', 1)
INSERT INTO DataShareTablesList VALUES ( 'ExcavationGirthWeld', 1)
INSERT INTO DataShareTablesList VALUES ( 'ExcavationProject', 1)
INSERT INTO DataShareTablesList VALUES ( 'ExcavationSite', 1)
INSERT INTO DataShareTablesList VALUES ( 'ExcavationSiteCrackAnomaly', 1)
INSERT INTO DataShareTablesList VALUES ( 'ExposedPipe', 1)
INSERT INTO DataShareTablesList VALUES ( 'Extrusion', 1)
INSERT INTO DataShareTablesList VALUES ( 'Fabrication', 1)
INSERT INTO DataShareTablesList VALUES ( 'FabricationRemark', 1)
INSERT INTO DataShareTablesList VALUES ( 'Facility', 1)
INSERT INTO DataShareTablesList VALUES ( 'FacilityAlignment', 1)
INSERT INTO DataShareTablesList VALUES ( 'FacilityFlow', 1)
INSERT INTO DataShareTablesList VALUES ( 'FacilityFlowGroup', 1)
INSERT INTO DataShareTablesList VALUES ( 'FacilityFlowGroupComponent', 1)
INSERT INTO DataShareTablesList VALUES ( 'FacilityFlowOperator', 1)
INSERT INTO DataShareTablesList VALUES ( 'FailureDetection', 1)
INSERT INTO DataShareTablesList VALUES ( 'FaultArea', 1)
INSERT INTO DataShareTablesList VALUES ( 'Flange', 1)
INSERT INTO DataShareTablesList VALUES ( 'FloodArea', 1)
INSERT INTO DataShareTablesList VALUES ( 'FrostArea', 1)
INSERT INTO DataShareTablesList VALUES ( 'GirthWeld', 1)
INSERT INTO DataShareTablesList VALUES ( 'HCACFR', 1)
INSERT INTO DataShareTablesList VALUES ( 'HCACFRSeg', 1)
INSERT INTO DataShareTablesList VALUES ( 'HCAPipeGasConstantFactor', 1)
INSERT INTO DataShareTablesList VALUES ( 'HCAPipePIRBuffer', 1)
INSERT INTO DataShareTablesList VALUES ( 'HCAReasons', 1)
INSERT INTO DataShareTablesList VALUES ( 'HCAStructureCounts', 1)
INSERT INTO DataShareTablesList VALUES ( 'HurricaneArea', 1)
INSERT INTO DataShareTablesList VALUES ( 'HydroTest', 1)
INSERT INTO DataShareTablesList VALUES ( 'HydroTestRange', 1)
INSERT INTO DataShareTablesList VALUES ( 'IDAllocation', 1)
INSERT INTO DataShareTablesList VALUES ( 'IdentityColumn', 1)
INSERT INTO DataShareTablesList VALUES ( 'IdentityColumnGrouping', 1)
INSERT INTO DataShareTablesList VALUES ( 'ILIArtifactXRef', 1)
INSERT INTO DataShareTablesList VALUES ( 'ILIError', 1)
INSERT INTO DataShareTablesList VALUES ( 'ILIExcavation', 1)
INSERT INTO DataShareTablesList VALUES ( 'Image', 1)
INSERT INTO DataShareTablesList VALUES ( 'ImageVertex', 1)
INSERT INTO DataShareTablesList VALUES ( 'Incident', 1)
INSERT INTO DataShareTablesList VALUES ( 'IncidentDetails', 1)
INSERT INTO DataShareTablesList VALUES ( 'IncidentHistory', 1)
INSERT INTO DataShareTablesList VALUES ( 'InlineInspection', 1)
INSERT INTO DataShareTablesList VALUES ( 'InlineInspectionRange', 1)
INSERT INTO DataShareTablesList VALUES ( 'InlineInspectionFeature', 1)
INSERT INTO DataShareTablesList VALUES ( 'InlineInspectionJoint', 1)
INSERT INTO DataShareTablesList VALUES ( 'InlineInspectionBendStrain', 1)
INSERT INTO DataShareTablesList VALUES ( 'InlineInspectionCrackAnomaly', 1)
INSERT INTO DataShareTablesList VALUES ( 'InlineInspectionCrsnCallBox', 1)
INSERT INTO DataShareTablesList VALUES ( 'InlineInspectionFacility', 1)
INSERT INTO DataShareTablesList VALUES ( 'InlineInspectionNonCrsnDfct', 1)
INSERT INTO DataShareTablesList VALUES ( 'InlineInspectionRemark', 1)
INSERT INTO DataShareTablesList VALUES ( 'InlineInspectionStrain', 1)
INSERT INTO DataShareTablesList VALUES ( 'InspectionData', 1)
INSERT INTO DataShareTablesList VALUES ( 'IntegrationType', 1)
INSERT INTO DataShareTablesList VALUES ( 'InternalCoating', 1)
INSERT INTO DataShareTablesList VALUES ( 'InternalInspection', 1)
INSERT INTO DataShareTablesList VALUES ( 'IRASCustomData1', 1)
INSERT INTO DataShareTablesList VALUES ( 'IRASCustomData11', 1)
INSERT INTO DataShareTablesList VALUES ( 'IRASCustomData2', 1)
INSERT INTO DataShareTablesList VALUES ( 'IRASCustomData3', 1)
INSERT INTO DataShareTablesList VALUES ( 'IRASCustomData4', 1)
INSERT INTO DataShareTablesList VALUES ( 'IRASCustomData5', 1)
INSERT INTO DataShareTablesList VALUES ( 'IRASCustomData6', 1)
INSERT INTO DataShareTablesList VALUES ( 'IRASCustomData7', 1)
INSERT INTO DataShareTablesList VALUES ( 'IRASCustomData8', 1)
INSERT INTO DataShareTablesList VALUES ( 'IRASCustomData9', 1)
INSERT INTO DataShareTablesList VALUES ( 'IrasType', 1)
INSERT INTO DataShareTablesList VALUES ( 'Joint', 1)
--INSERT INTO DataShareTablesList VALUES ( 'Joint2010', 1)
INSERT INTO DataShareTablesList VALUES ( 'JointAlignment', 1)
INSERT INTO DataShareTablesList VALUES ( 'JointCoating', 1)
INSERT INTO DataShareTablesList VALUES ( 'LandSlideArea', 1)
INSERT INTO DataShareTablesList VALUES ( 'LandUse', 1)
INSERT INTO DataShareTablesList VALUES ( 'LightningStrikeArea', 1)
INSERT INTO DataShareTablesList VALUES ( 'LineLoopStatus', 1)
INSERT INTO DataShareTablesList VALUES ( 'Maintenance', 1)
INSERT INTO DataShareTablesList VALUES ( 'MaintenanceProject', 1)
INSERT INTO DataShareTablesList VALUES ( 'MAOP', 1)
INSERT INTO DataShareTablesList VALUES ( 'MAOPPipeProperties', 1)
INSERT INTO DataShareTablesList VALUES ( 'Marker', 1)
INSERT INTO DataShareTablesList VALUES ( 'MarkerRemark', 1)
INSERT INTO DataShareTablesList VALUES ( 'MaterialRoughness', 1)
INSERT INTO DataShareTablesList VALUES ( 'MatrixCellColorTemplate', 1)
INSERT INTO DataShareTablesList VALUES ( 'MatrixColorTemplate', 1)
INSERT INTO DataShareTablesList VALUES ( 'MechanicalDamage', 1)
INSERT INTO DataShareTablesList VALUES ( 'MetaDataColumn', 1)
INSERT INTO DataShareTablesList VALUES ( 'MetaDataForeignKey', 1)
INSERT INTO DataShareTablesList VALUES ( 'MetaDataForeignKeyColumn', 1)
INSERT INTO DataShareTablesList VALUES ( 'MetaDataTable', 1)
INSERT INTO DataShareTablesList VALUES ( 'MetalLoss', 1)
INSERT INTO DataShareTablesList VALUES ( 'MICAnalysis', 1)
INSERT INTO DataShareTablesList VALUES ( 'MICAnalysisReading', 1)
INSERT INTO DataShareTablesList VALUES ( 'MILEPOST', 1)
INSERT INTO DataShareTablesList VALUES ( 'MonteCarloPOE', 1)
INSERT INTO DataShareTablesList VALUES ( 'MonteCarloPOECalc', 1)
INSERT INTO DataShareTablesList VALUES ( 'MonteCarloPOEYear', 1)
INSERT INTO DataShareTablesList VALUES ( 'MOP', 1)
INSERT INTO DataShareTablesList VALUES ( 'Node', 1)
INSERT INTO DataShareTablesList VALUES ( 'NodeConnection', 1)
INSERT INTO DataShareTablesList VALUES ( 'NodeNetwork', 1)
INSERT INTO DataShareTablesList VALUES ( 'NodeNetworkNodes', 1)
--INSERT INTO DataShareTablesList VALUES ( 'NonClusteredIndexes', 1)
INSERT INTO DataShareTablesList VALUES ( 'OperatingData', 1)
INSERT INTO DataShareTablesList VALUES ( 'OperatingProfileState', 1)
INSERT INTO DataShareTablesList VALUES ( 'OutsideForces', 1)
INSERT INTO DataShareTablesList VALUES ( 'PCMSurvey', 1)
INSERT INTO DataShareTablesList VALUES ( 'PCMSurveyRange', 1)
INSERT INTO DataShareTablesList VALUES ( 'PCMSurveyReading', 1)
INSERT INTO DataShareTablesList VALUES ( 'PIMSRiskResults', 1)
INSERT INTO DataShareTablesList VALUES ( 'PIMSRiskResultsDyseg', 1)
INSERT INTO DataShareTablesList VALUES ( 'PipeCondition', 1)
INSERT INTO DataShareTablesList VALUES ( 'PipeSegment', 1)
INSERT INTO DataShareTablesList VALUES ( 'PipeSegmentRemark', 1)
INSERT INTO DataShareTablesList VALUES ( 'PipeSoilPotentialPipe', 1)
INSERT INTO DataShareTablesList VALUES ( 'PipeSoilPotentialSurface', 1)
INSERT INTO DataShareTablesList VALUES ( 'PipeWallThickness', 1)
INSERT INTO DataShareTablesList VALUES ( 'POECoatingProperty', 1)
INSERT INTO DataShareTablesList VALUES ( 'POECompanyLookup', 1)
INSERT INTO DataShareTablesList VALUES ( 'PointChar', 1)
INSERT INTO DataShareTablesList VALUES ( 'PredefinedLocation', 1)
INSERT INTO DataShareTablesList VALUES ( 'Pressure', 1)
INSERT INTO DataShareTablesList VALUES ( 'ProductComponent', 1)
INSERT INTO DataShareTablesList VALUES ( 'QueryStructure', 1)
INSERT INTO DataShareTablesList VALUES ( 'RADIMClassifierCategory', 1)
INSERT INTO DataShareTablesList VALUES ( 'RADIMP', 1)
INSERT INTO DataShareTablesList VALUES ( 'RADIMPClassifier', 1)
INSERT INTO DataShareTablesList VALUES ( 'RADIMPClassifierItem', 1)
INSERT INTO DataShareTablesList VALUES ( 'RADIMPEquipmentService', 1)
INSERT INTO DataShareTablesList VALUES ( 'RADIMPScoreTable', 1)
INSERT INTO DataShareTablesList VALUES ( 'RADIMPVariable', 1)
INSERT INTO DataShareTablesList VALUES ( 'RADIMPView', 1)
INSERT INTO DataShareTablesList VALUES ( 'RADIMPViewColumn', 1)
INSERT INTO DataShareTablesList VALUES ( 'RADIMPViewSection', 1)
INSERT INTO DataShareTablesList VALUES ( 'RADIMPViewSectionColumnXRef', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCCategoryStructure', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCComputationType', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCCSAClassCalc', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCCSAClassCalcFlagType', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCCSAClassCalcSeg', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCCSAClassFlags', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCCSAClassFlagType', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCDIMP', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCDIMPBaseRun', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCDIMPBucket', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCDIMPBucketCategory', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCDIMPBucketCategoryValue', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCDIMPBucketConstraint', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCDIMPBucketCount', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCDIMPBucketLeakGradeConseq', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCDIMPBucketMileage', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCDIMPEquipment', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCDIMPEquipmentCount', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCDIMPEquipmentPerBucket', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCDIMPLeakGrade', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCDIMPPromote', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCDIMPRemarks', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCDIMPScoreTableValue', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCDIMPThreat', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCDIMPVariable', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCDIMPVariableLeakGradeXRef', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCDIMPVariableValueNum_1', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCDOTClassCalc', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCDOTClassCalcFlagType', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCDOTClassCalcSeg', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCDOTClassFlags', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCDOTClassFlagType', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCHCACalc', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCHCACalcSeg', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCHCAFlags', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCHCAFlagType', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCHCAReasons', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCHCAReasonType', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCHCAStructures', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCMAOPCALC', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCMAOPCalcSeg', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCMAOPFlagActionType', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCMAOPFlagProcessType', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCMAOPFlagReasonType', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCMAOPFlags', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCMAOPLIMIT', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCProject', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCProjectSelection', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCScenario', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCScenarioCategoryStructure', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCScenarioOptions', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCScenarioStructure', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCScenarioStructureVertex', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCStructureCategory', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCStructureCategoryType', 1)
INSERT INTO DataShareTablesList VALUES ( 'RCStructureData', 1)
INSERT INTO DataShareTablesList VALUES ( 'Rectifier', 1)
INSERT INTO DataShareTablesList VALUES ( 'RectifierReading', 1)
INSERT INTO DataShareTablesList VALUES ( 'Reducer', 1)
INSERT INTO DataShareTablesList VALUES ( 'RememberedListDomainValues', 1)
--INSERT INTO DataShareTablesList VALUES ( 'RememberedListDomainValues11102020B4Cleanup', 1)
INSERT INTO DataShareTablesList VALUES ( 'RightOfWay', 1)
INSERT INTO DataShareTablesList VALUES ( 'SeriesConnection', 1)
INSERT INTO DataShareTablesList VALUES ( 'ShutdownProfileState', 1)
INSERT INTO DataShareTablesList VALUES ( 'Sleeve', 1)
INSERT INTO DataShareTablesList VALUES ( 'SleeveRemark', 1)
INSERT INTO DataShareTablesList VALUES ( 'SoilAnalysis', 1)
INSERT INTO DataShareTablesList VALUES ( 'SoilAnalysisReading', 1)
INSERT INTO DataShareTablesList VALUES ( 'SoilArea', 1)
INSERT INTO DataShareTablesList VALUES ( 'SoilCondition', 1)
INSERT INTO DataShareTablesList VALUES ( 'SoilEnvironment', 1)
INSERT INTO DataShareTablesList VALUES ( 'SoilLandUseArea', 1)
INSERT INTO DataShareTablesList VALUES ( 'SoilResistivityGrade', 1)
INSERT INTO DataShareTablesList VALUES ( 'SoilResistivityPipe', 1)
INSERT INTO DataShareTablesList VALUES ( 'SoilVertex', 1)
INSERT INTO DataShareTablesList VALUES ( 'StationSeriesAttribute', 1)
INSERT INTO DataShareTablesList VALUES ( 'StationSeriesReplacement', 1)
INSERT INTO DataShareTablesList VALUES ( 'StructOccupancyCtgry', 1)
INSERT INTO DataShareTablesList VALUES ( 'Structure', 1)
INSERT INTO DataShareTablesList VALUES ( 'StructureAreaFill', 1)
INSERT INTO DataShareTablesList VALUES ( 'StructurePointChar', 1)
INSERT INTO DataShareTablesList VALUES ( 'StructureVertex', 1)
INSERT INTO DataShareTablesList VALUES ( 'SupplementalPermissions', 1)
INSERT INTO DataShareTablesList VALUES ( 'SystemPreferences', 1)
INSERT INTO DataShareTablesList VALUES ( 'Tank', 1)
INSERT INTO DataShareTablesList VALUES ( 'Tap', 1)
INSERT INTO DataShareTablesList VALUES ( 'TblChkErrCenterline', 1)
INSERT INTO DataShareTablesList VALUES ( 'TblChkErrDataGaps', 1)
INSERT INTO DataShareTablesList VALUES ( 'TblChkErrInvalidRecord', 1)
INSERT INTO DataShareTablesList VALUES ( 'TblChkErrOverlap', 1)
INSERT INTO DataShareTablesList VALUES ( 'TblChkErrStationGap', 1)
INSERT INTO DataShareTablesList VALUES ( 'Tee', 1)
--INSERT INTO DataShareTablesList VALUES ( 'temp', 1)
INSERT INTO DataShareTablesList VALUES ( 'TempTableLog', 1)
INSERT INTO DataShareTablesList VALUES ( 'TestPostPoint', 1)
INSERT INTO DataShareTablesList VALUES ( 'TestPostPointReading', 1)
INSERT INTO DataShareTablesList VALUES ( 'TornadoDensityArea', 1)
INSERT INTO DataShareTablesList VALUES ( 'UntitledDefaultSummary', 1)
INSERT INTO DataShareTablesList VALUES ( 'Valve', 1)
INSERT INTO DataShareTablesList VALUES ( 'ValveRemark', 1)
INSERT INTO DataShareTablesList VALUES ( 'ValveType', 1)
INSERT INTO DataShareTablesList VALUES ( 'Vent', 1)
INSERT INTO DataShareTablesList VALUES ( 'VersionHistory', 1)
INSERT INTO DataShareTablesList VALUES ( 'VersionInfo', 1)
INSERT INTO DataShareTablesList VALUES ( 'VirtualColumn', 1)
INSERT INTO DataShareTablesList VALUES ( 'VirtualTable', 1)
INSERT INTO DataShareTablesList VALUES ( 'VirtualTableStationing', 1)
INSERT INTO DataShareTablesList VALUES ( 'WaterAnalysis', 1)
INSERT INTO DataShareTablesList VALUES ( 'WaterAnalysisReading', 1)
INSERT INTO DataShareTablesList VALUES ( 'WaterTesting', 1)
INSERT INTO DataShareTablesList VALUES ( 'Weight', 1)
COMMIT TRANSACTION

--***********************************************************************************************
-- 
--**********************************************************************************************
DECLARE @SQL NVARCHAR(MAX)
DECLARE @TableName NVARCHAR(100)

------------------------------- Add Missing Tables From DATASHARE DB Target DB -----------------

DECLARE AddTable_Cursor CURSOR FOR
SELECT 'SELECT * INTO [' + TableName + '] FROM [DATASHARE].[dbo].' + TableName + ' WHERE 1 = 0'
FROM DataShareTablesList
WHERE TableName IN (SELECT table_name FROM DATASHARE.INFORMATION_SCHEMA.tables)
AND TableName NOT IN (SELECT name FROM sys.tables) 

OPEN AddTable_Cursor
FETCH NEXT FROM AddTable_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	EXECUTE (@SQL)
	FETCH NEXT FROM AddTable_Cursor INTO @SQL
END

CLOSE AddTable_Cursor
DEALLOCATE AddTable_Cursor

----------------------------------- Delete Unnecessary Tables -------------------

DECLARE DeleteTables_Cursor CURSOR FOR
SELECT name 
FROM sys.tables
WHERE (name LIKE 'STG[_]%' OR name LIKE 'DBS[_]%' 
OR name LIKE 'History[_]%' OR name LIKE 'H[_]%' 
OR name LIKE 'i[_]%' OR name LIKE 'RISK%'
OR name LIKE 'Load[_]%' -- AND name NOT LIKE 'VirtualTable%'
OR name LIKE 'tmp%'
OR name IN ('Connection', 'ConnectionType', 'DisplayField', 'ScriptTracker', 
'CategoryDataListDomainXRef', 'DomainCatalog', 'DomainCatalogColXRef'))
AND temporal_type = 0

OPEN DeleteTables_Cursor
FETCH NEXT FROM DeleteTables_Cursor INTO @TableName

WHILE @@FETCH_STATUS = 0
BEGIN
	-- Drop all foreign keys referncing the table to be droped
	DECLARE DropFK_Cursor CURSOR FOR
	SELECT DISTINCT 'ALTER TABLE ' + fk_info.table_name + ' DROP CONSTRAINT ' + rc.constraint_name + ';' AS drop_fk_ddl
	FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
	JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE fk_info
	ON rc.constraint_name = fk_info.constraint_name
	JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE pk_info
	ON rc.unique_constraint_name = pk_info.constraint_name
	WHERE pk_info.table_name = @TableName

	OPEN DropFK_Cursor
	FETCH NEXT FROM DropFK_Cursor INTO @SQL

	WHILE @@FETCH_STATUS = 0
	BEGIN 
		BEGIN TRANSACTION
			EXECUTE (@SQL)
			FETCH NEXT FROM DropFK_Cursor INTO @SQL
		COMMIT TRANSACTION
	END

	CLOSE DropFK_Cursor
	DEALLOCATE DropFK_Cursor

	SET @SQL = 'DROP TABLE ' + @TableName
	EXECUTE (@SQL)
	FETCH NEXT FROM DeleteTables_Cursor INTO @TableName
END

CLOSE DeleteTables_Cursor
DEALLOCATE DeleteTables_Cursor

-------------------------------- Disable Foreign Keys ---------------------------

-- Disable foreign keys to delete data from tables
DECLARE DiableFK_Cursor CURSOR FOR
SELECT 'ALTER TABLE ' + SCHEMA_NAME(schema_id) + '.' + OBJECT_NAME(parent_object_id) + ' NOCHECK CONSTRAINT ' + name
FROM sys.foreign_keys
WHERE is_disabled = 0

OPEN DiableFK_Cursor
FETCH NEXT FROM DiableFK_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	EXECUTE (@SQL)
	FETCH NEXT FROM DiableFK_Cursor INTO @SQL
END

CLOSE DiableFK_Cursor
DEALLOCATE DiableFK_Cursor

----------------------------------- Delete Data from Tables ---------------------------

DECLARE DeleteData_Cursor CURSOR FOR
SELECT 'DELETE FROM ' + name + ';' AS DeleteStmt
FROM sys.tables
WHERE temporal_type = 0
AND name NOT IN ('DataShareTablesList', 'ForeignKeys')

OPEN DeleteData_Cursor
FETCH NEXT FROM DeleteData_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	BEGIN TRANSACTION
		EXECUTE (@SQL)
		FETCH NEXT FROM DeleteData_Cursor INTO @SQL
	COMMIT TRANSACTION
END

CLOSE DeleteData_Cursor
DEALLOCATE DeleteData_Cursor

----------------------------------- Re-enable Foreign Keys -------------------------------------

DECLARE EnableFK_Cursor CURSOR FOR
SELECT 'ALTER TABLE ' + SCHEMA_NAME(schema_id) + '.' + OBJECT_NAME(parent_object_id) + + ' CHECK CONSTRAINT ' + name
FROM sys.foreign_keys
WHERE is_disabled = 1

OPEN EnableFK_Cursor
FETCH NEXT FROM EnableFK_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	EXECUTE (@SQL)
	FETCH NEXT FROM EnableFK_Cursor INTO @SQL
END

CLOSE EnableFK_Cursor
DEALLOCATE EnableFK_Cursor

--------------------------------- Re-Create/Create Table to Save Foreign Key Definitions  ----------------------------------

-- Only drop the created ForeignKeys table if there are foreign keys
IF OBJECT_ID(N'dbo.ForeignKeys', N'U') IS NOT NULL AND EXISTS (SELECT * FROM sys.foreign_keys) 
BEGIN
   DROP TABLE dbo.ForeignKeys;
END

IF OBJECT_ID ('dbo.ForeignKeys', 'U') IS NULL
BEGIN
	SET @SQL = '
	SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS Id,
		   OBJECT_NAME(fkc.constraint_object_id) AS ForeignKeyName,
		   SCHEMA_NAME(t1.schema_id) AS TableSchema,
		   OBJECT_NAME(fkc.parent_object_id) AS TableName,
		   COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ColumnName,
		   SCHEMA_NAME(t2.schema_id) AS ReferencedTableSchema,
		   OBJECT_NAME(fkc.referenced_object_id) AS ReferencedTable,
		   COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ReferencedColumn,
		   NULL AS ColumnId
	INTO ForeignKeys
	FROM sys.foreign_key_columns fkc
	JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
	JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id'

	EXECUTE sp_executesql @SQL

	-- Save Default Constraints, Check Constraint and Trigger definitions
	DROP TABLE IF EXISTS Temp_DependentTableObjects

	CREATE TABLE Temp_DependentTableObjects (TableName NVARCHAR(100), 
								 ObjectName NVARCHAR(100), 
								ObjectType NVARCHAR(100), 
								Definition NVARCHAR(MAX))

	INSERT INTO Temp_DependentTableObjects
	SELECT OBJECT_NAME(parent_object_id),
			name,
		   'CheckConstraint' AS ObjectType,
		  ('ALTER TABLE ' + OBJECT_NAME(parent_object_id) + ' ADD CONSTRAINT ' + name + ' CHECK' + definition) AS definition
	FROM sys.check_constraints cc
	UNION
	SELECT OBJECT_NAME(parent_object_id),
		   name,
		   'DefaultConstraint' AS typr,
		   ('ALTER TABLE ' + OBJECT_NAME(parent_object_id) + ' ADD CONSTRAINT ' +
			+ name + ' DEFAULT' + definition + ' FOR ' + COL_NAME(parent_object_id, parent_column_id)) AS definition
	FROM sys.default_constraints dc 
	UNION
	SELECT OBJECT_NAME(parent_id) AS TableName,
		   name,
		   'Trigger' AS ObjectType,
		   (SELECT OBJECT_DEFINITION (t.object_id)) AS definition
	FROM sys.triggers t
END
GO



--*******************************************************************************************
-- Create Stored Procedures and Functions
--*******************************************************************************************

---------------------------- Create/Re-Create dbo.sp_LoadTable Stored Procedure -----------------------

SET ANSI_NULLS ON

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.sp_LoadTable
@TableName NVARCHAR(250)
AS
BEGIN

	DECLARE @SQL NVARCHAR(MAX) 
	DECLARE @SQL2 NVARCHAR(MAX)
	DECLARE @SQL3 NVARCHAR(MAX)
	DECLARE @SQL4 NVARCHAR(MAX)
	DECLARE @MissingData INT = NULL
	DECLARE @PKColumns NVARCHAR(MAX)
	DECLARE @FKColumn NVARCHAR(100)
	--DECLARE @TableName NVARCHAR(100) = 'CalculatorParameters'

	SET @SQL = ''
	SET @SQL2 = ''
	SET @SQL3 = ''
	SET @SQL4 = ''

	IF OBJECT_ID(@TableName, 'U') IS NOT NULL 
	BEGIN
		
		IF OBJECT_ID('tempdb..##PKColumns') IS NOT NULL 
		BEGIN
			DROP TABLE ##PKColumns;
		END

		--Save list of primary key columns
		SELECT ic.column_id AS ColumnId,
				CASE WHEN COL_NAME(ic.object_id,column_id) = 'Id'  AND COL_LENGTH(@TableName, 'OriginalId') IS NOT NULL 
						THEN 'OriginalId' 
					ELSE COL_NAME(ic.object_id,column_id) 
				END AS ColumnName,
				CASE data_type WHEN 'numeric' THEN 'NUMERIC(' + CAST(numeric_precision AS NVARCHAR) + ', ' + CAST(numeric_scale AS NVARCHAR) + ')'
							   WHEN 'varchar' THEN 'VARCHAR(' + CAST(character_maximum_length AS NVARCHAR) + ')'
							   WHEN 'int' THEN 'INT'
							   WHEN 'date' THEN 'DATE'
							   WHEN 'datetime' THEN 'DATETIME'
				END AS DataType
		INTO ##PKColumns
		FROM sys.indexes i
		JOIN sys.index_columns ic
		ON i.object_id = ic.object_id
		AND i.index_id = ic.index_id
		JOIN INFORMATION_SCHEMA.columns c
		ON COL_NAME(ic.object_id, ic.column_id) = c.column_name
		AND OBJECT_NAME(ic.object_id) = c.table_name
		WHERE OBJECT_NAME(ic.object_id) = @TableName
		AND i.type_desc = 'CLUSTERED'
		AND COL_NAME(ic.object_id, column_id) <> 'Client_Code'
	
		SELECT @PKColumns = STRING_AGG(ColumnName, ', ') WITHIN GROUP (ORDER BY ColumnId)
		FROM ##PKColumns

		
		-- Turn off System-versioning for tables that have it enabled
		IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'systemPreferences' AND temporal_type <> 0)
		BEGIN
			SET @SQL += 'ALTER TABLE dbo.' + @TableName + ' SET (SYSTEM_VERSIONING = OFF);
						ALTER TABLE dbo.' + @TableName + '
						DROP PERIOD FOR SYSTEM_TIME;' + CHAR(10) + CHAR(10)

		END

		-- Drop all unique keys and primary key constraints on the table
		SELECT @SQL += 'ALTER TABLE ' + @TableName + ' DROP CONSTRAINT ' + name + CHAR(10)
		FROM sys.key_constraints 
		WHERE type IN ('PK', 'UQ') 
		AND OBJECT_NAME(parent_object_id) = @TableName 			
	
		-- Drop all check constraints on the table
		SELECT @SQL += 'ALTER TABLE ' + @TableName + ' DROP CONSTRAINT ' + name + CHAR(10)
		FROM sys.check_constraints 
		WHERE COL_NAME(parent_object_id, parent_column_id) = 'Id'
		AND OBJECT_NAME(parent_object_id) = @TableName

		-- Set INDENTITY INSERT ON if the table has an identity column
		IF EXISTS (SELECT 1 WHERE   OBJECTPROPERTY(OBJECT_ID(@TableName), 'TableHasIdentity') = 1) 
		BEGIN
			SET @SQL += 'SET IDENTITY_INSERT ' + @TableName + ' ON' + CHAR(10)
		END

		-- Make non-null columns with null values nullable
		SELECT @SQL += 'ALTER TABLE ' + @TableName + ' ALTER COLUMN ' + column_name 
			+ CASE data_type WHEN 'numeric' THEN ' NUMERIC(' 
								+ CAST(numeric_precision AS NVARCHAR) + ', ' + CAST(numeric_scale AS NVARCHAR) + ')'
							 WHEN 'datetime' THEN ' DATETIME'
			  END + ' NULL;' + CHAR(10)
		FROM INFORMATION_SCHEMA.columns
		WHERE table_name = @TableName
		AND column_name IN ('EffectiveStartDate', 'BeginStationSeriesId')
		AND column_name NOT IN (SELECT column_name FROM INFORMATION_SCHEMA.key_column_usage WHERE table_name = @TableName)
		AND is_nullable = 'NO'

		-- Alter any foreign key columns referencing an Id column without a precision of 10 and scale of 0 
		SELECT @SQL += 'ALTER TABLE ' + fk.TableName + ' ALTER COLUMN ' + fk.ColumnName + ' NUMERIC(10, 0) NULL' + CHAR(10)  
		FROM ForeignKeys fk
		JOIN sys.columns  c
		ON c.name = fk.ColumnName
		AND OBJECT_NAME(c.object_id) = fk.TableName
		WHERE TableName = @TableName
		AND ReferencedColumn = 'Id'
		AND (precision <> 10
		OR scale <> 0)

		-- Rearrange column order using a temporary table
		SET @SQL2 += 'DROP TABLE IF EXISTS Temp_' + @TableName + CHAR(10)
		SET @SQL3 += 
		(SELECT 'SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1), Client_Code' + ISNULL(', ' + REPLACE(@PKColumns, 'OriginalId', 'Id'), '') + ') AS Id,'
		+ ' [Client_Code], ' 
		+ (CASE WHEN COL_LENGTH('DATASHARE.dbo.' + @TableName, 'Id') IS NOT NULL THEN ' OriginalId = [Id],' ELSE '' END )
		+ '[' +STRING_AGG(column_name, '], [') WITHIN GROUP (ORDER BY ordinal_position) + ']' 
		+ CHAR(10) + 'INTO Temp_' + @TableName + CHAR(10) + 'FROM DATASHARE.dbo.' + @TableName 
		FROM DATASHARE.INFORMATION_SCHEMA.columns
		WHERE table_name = @TableName
		AND column_name NOT IN ('Id','Client_Code', 'OriginalID')) + CHAR(10) + CHAR(10) 

		-- Make the 'Id' column not-null and drop table so the temporary table can be renamed as the new table
		SET @SQL4 += 'ALTER TABLE Temp_' + @TableName + ' ALTER COLUMN [Id] INT NOT NULL;' + CHAR(10)
		+ 'DROP TABLE ' + @TableName + CHAR(10) + CHAR(10) +
		'EXECUTE sp_rename ''Temp_' + @TableName + ''', ''' + @TableName + '''' + CHAR(10)

		SET @SQL4 += 'ALTER TABLE ' + @TableName + ' ALTER COLUMN Client_Code VARCHAR(100) NOT NULL;' + CHAR(10)
		
		SELECT @SQL4 += 'ALTER TABLE ' + @TableName + ' ALTER COLUMN ' + ColumnName + ' ' + DataType + ' NOT NULL;' + CHAR(10)
		FROM ##PKColumns
	
		PRINT @SQL 
		PRINT @SQL2 
		PRINT @SQL3 
		PRINT @SQL4
		EXECUTE(@SQL + @SQL2 + @SQL3 + @SQL4)
			
		SET @SQL = NULL

		-- Recreate the triggers, check constraints and default constraints on tables
		SELECT @SQL = definition + CHAR(10) 
		FROM Temp_DependentTableObjects 
		WHERE TableName = @TableName 
		AND ObjectName NOT IN ('CKC_ID_VERSIONI')
		AND ObjectName NOT LIKE '%ValidTo%'
		AND Objectname NOT LIKE '%ValidFrom%'
		ORDER BY ObjectType DESC

		PRINT @SQL 
		EXECUTE (@SQL)
		
		--Recreate the primary key on the Id column
		IF (@PKColumns IS NOT NULL) 
		BEGIN
			SET @SQL = 'ALTER TABLE ' + @TableName + ' ADD CONSTRAINT PK_' + @TableName + ' PRIMARY KEY (Client_Code, ' + @PKColumns + ');' + CHAR(10)
		END
		ELSE 	
		BEGIN
			SET @SQL = 'ALTER TABLE ' + @TableName + ' ADD CONSTRAINT PK_' + @TableName + ' PRIMARY KEY (Id);' + CHAR(10)
		END

		PRINT @SQL
		EXECUTE (@SQL);
	END
END
GO

--*******************************************************************************************
-- PREP TABLES
--********************************************************************************************

DECLARE @SQL NVARCHAR(MAX)
DECLARE @TargetTable NVARCHAR(100)
DECLARE @TargetDB NVARCHAR(100) = DB_NAME()

-------------------------------- Add Client_Code column to tables  -------------------------

DECLARE AddClientCode_Cursor CURSOR FOR
SELECT 
    'ALTER TABLE dbo.[' + name + '] ADD Client_Code  VARCHAR(100) NULL;'
FROM 
    sys.tables Tab
WHERE NOT EXISTS
    (
        SELECT 
            'X'
        FROM 
            INFORMATION_SCHEMA.COLUMNS  Col
        WHERE 
            Col.TABLE_NAME = Tab.name
            AND Col.COLUMN_NAME='Client_Code'
    )
AND Tab.temporal_type_desc = 'NON_TEMPORAL_TABLE'
AND tab.name NOT IN ('ForeignKeys', 'DataShareTablesList')

OPEN AddClientCode_Cursor
FETCH NEXT FROM AddClientCode_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	EXECUTE (@SQL)
	FETCH NEXT FROM AddClientCode_Cursor INTO @SQL
END

CLOSE AddClientCode_Cursor
DEALLOCATE AddClientCode_Cursor

---------------------------------- Add OriginalID column to all tables ---------------------------

DECLARE AddOriginalId_Cursor CURSOR FOR
SELECT 
    'ALTER TABLE dbo.[' + name + '] ADD OriginalID NUMERIC(10,0) NULL;'
FROM 
    sys.tables Tab
WHERE NOT EXISTS
    (
        SELECT 
            'X'
        FROM 
            INFORMATION_SCHEMA.COLUMNS  Col
        WHERE 
            Col.TABLE_NAME = Tab.name
            AND Col.COLUMN_NAME='OriginalID'
    )
AND Tab.temporal_type_desc = 'NON_TEMPORAL_TABLE'
AND tab.name NOT IN ('ForeignKeys', 'DataShareTableList')
AND COL_LENGTH('DATASHARE.dbo.' + name, 'Id') IS NOT NULL

OPEN AddOriginalId_Cursor
FETCH NEXT FROM AddOriginalId_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	EXECUTE (@SQL)
	FETCH NEXT FROM AddOriginalId_Cursor INTO @SQL
END

CLOSE AddOriginalId_Cursor
DEALLOCATE AddOriginalId_Cursor

-------------------------------------Add Id column to tables that do not have it ----------------

DECLARE AddId_Cursor CURSOR FOR
SELECT 
    'ALTER TABLE dbo.[' + name + '] ADD Id INT NULL;' + CHAR(10)
FROM 
    sys.tables Tab
WHERE NOT EXISTS
    (
        SELECT 
            'X'
        FROM 
            INFORMATION_SCHEMA.COLUMNS  Col
        WHERE 
            Col.TABLE_NAME = Tab.name
            AND Col.COLUMN_NAME='Id'
    )
AND Tab.temporal_type_desc = 'NON_TEMPORAL_TABLE'
AND tab.name NOT IN ('ForeignKeys', 'DataShareTablesList')

OPEN AddId_Cursor
FETCH NEXT FROM AddId_Cursor INTO @SQL

WHILE @@FETCH_STATUS = 0
BEGIN
	EXECUTE (@SQL)
	FETCH NEXT FROM AddId_Cursor INTO @SQL
END
CLOSE AddId_Cursor
DEALLOCATE AddId_Cursor
GO



