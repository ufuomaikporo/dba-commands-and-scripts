DECLARE @SQL NVARCHAR(MAX)
SELECT @SQL = STRING_AGG('DROP TABLE ' + name, CHAR(10)) FROM sys.tables
WHERE name LIKE 'ERDiagram%'

EXECUTE (@SQL)


CREATE TABLE ERDiagram_CenterlineTables (TableName VARCHAR(100))
CREATE TABLE ERDiagram_ILITables (TableName VARCHAR(100))
CREATE TABLE ERDiagram_EventTables (TableName VARCHAR(100))
CREATE TABLE ERDiagram_VirtualTables (TableName VARCHAR(100))
CREATE TABLE ERDiagram_RiskTables (TableName VARCHAR(100))
CREATE TABLE ERDiagram_OutsideForceTables (TableName VARCHAR(100))
CREATE TABLE ERDiagram_DataExchangeTables (TableName VARCHAR(100))
CREATE TABLE ERDiagram_POETables (TableName VARCHAR(100))
CREATE TABLE ERDiagram_IRASCustomTables (TableName VARCHAR(100))
CREATE TABLE ERDiagram_DataManagerTables (TableName VARCHAR(100))
CREATE TABLE ERDiagram_ConfiguratonTables (TableName VARCHAR(100))
CREATE TABLE ERDiagram_StagingTables (TableName VARCHAR(100))
CREATE TABLE ERDiagram_TableCheckerTables (TableName VARCHAR(100))
CREATE TABLE ERDiagram_ComplianceAuditorTables (TableName VARCHAR(100))
CREATE TABLE ERDiagram_LookupTables (TableName VARCHAR(100))

INSERT INTO ERDiagram_CenterlineTables
SELECT name FROM sys.tables WHERE name IN ('Corporation', 'DischargeSubsystem', 'LineLoop', 'MLVCorrection', 'MLVSection', 'OperatingUnit', 'SeriesConnection', 'StationSeries')

INSERT INTO ERDiagram_ILITables
SELECT name FROM sys.tables WHERE name IN ('AlignmentRange', 'CenterlineAlignment', 'CenterlineAlignmentDependency', 'CenterlineDefinition', 'CenterlineMapping', 
'ColocateCluster', 'ColocateCrack', 'ColocateGirthWeld', 'ColocateNCD', 'ColocateSite', 'CrackAnomaly', 'CrackAnomalyCluster', 'ILIArtifactXRef', 'ILIError', 'ILIExcavation', 'InlineInspection', 
'InlineInspectionAxialStrain', 'InlineInspectionBendStrain', 'InlineInspectionCrackAnomaly', 'InlineInspectionCrsnCallBox', 'InlineInspectionFacility', 'InlineInspectionFeature', 'InlineInspectionJoint', 
'InlineInspectionJoint12102019', 'InlineInspectionNonCrsnDfct', 'InlineInspectionRange', 'InlineInspectionRemark', 'InlineInspectionStrain')

INSERT INTO ERDiagram_EventTables
SELECT name FROM sys.tables WHERE name IN ('ACVGSurvey', 'ACVGSurveyAnomaly', 'ACVGSurveyRange', 'ACVGSurveyReading', 'BellHoleExcavation', 'Bend', 'BendRemark', 'Casing', 'CasingReading', 'CasingRemark', 'CASurvey', 'CASurveyRange', 'CASurveyReading', 'ClassArea', 'Classification', 'ClassificationRange', 'ClassLocationStructCtgry', 'Coating', 'CoatingCondition', 'CoatingDefect', 'CoatingThickness', 'Coupon', 'CouponReading', 'CoverDepth', 'CoverDepthProfile', 'CPRange', 'CPSurvey', 'CPSurveyRange', 'CPSurveyReading', 'Crossing', 'CrossingLocn', 'DamagePrevention', 'DCVGSurvey', 'DCVGSurveyAnomaly', 'DCVGSurveyRange', 'DCVGSurveyReading', 'DesignClass', 'DistBusinessDistrict', 'DistInsideMeter', 'DistPopulationDensity', 'DistServiceHeadSuscept', 'Elbow', 'ElectrolytePH', 'ElevationProfile', 'ExcavationAttachmentFile', 'ExcavationAttachmentUrl', 'ExcavationGirthWeld', 'ExcavationProject', 'ExcavationSite', 'ExcavationSiteCrackAnomaly', 'ExposedPipe', 'Extrusion', 'Fabrication', 'FabricationRemark', 'Facility', 'FacilityAlignment', 'FacilityFlow', 'FacilityFlowGroup', 'FacilityFlowGroupComponent', 'FacilityFlowOperator', 'FailureDetection', 'Flange', 'GirthWeld', 'HCACFR', 'HCACFRSeg', 'HCAPipeGasConstantFactor', 'HCAPipePIRBuffer', 'HCAReasons', 'HCAStructureCounts', 'HydroTest', 'HydroTestRange', 'Image', 'ImageVertex', 'Incident', 'IncidentDetails', 'IncidentHistory', 'InspectionData', 'IntegrationType', 'InternalCoating', 'InternalInspection', 'Joint', 'JointAlignment', 'JointCoating', 'Maintenance', 'MaintenanceProject', 'MAOP', 'MAOPPipeProperties', 'Marker', 'MarkerRemark', 'MaterialRoughness', 'MechanicalDamage', 'MetalLoss', 'MICAnalysis', 'MICAnalysisReading', 'MILEPOST', 'MOP', 'Node', 'NodeConnection', 'NodeNetwork', 'NodeNetworkNodes', 'OperatingData', 'OperatingProfileState', 'OutsideForces', 'PCMSurvey', 'PCMSurveyRange', 'PCMSurveyReading', 'PipeCondition', 'PipelineSystem', 'PipeSegment', 'PipeSegmentRemark', 'PipeSoilPotentialPipe', 'PipeSoilPotentialSurface', 'PipeWallThickness', 'PointChar', 'PredefinedLocation', 'Pressure', 'ProductComponent', 'QueryStructure', 'Rectifier', 'RectifierReading', 'Reducer', 'RightOfWay', 'ShutdownProfileState', 'SimCalcFeatureLeak', 'SimCalcFeatureRupture', 'SimCalcFeatureTotal', 'Sleeve', 'SoilAnalysis', 'SoilAnalysisReading', 'SoilArea', 'SoilCondition', 'SoilEnvironment', 'SoilResistivityGrade', 'SoilResistivityPipe', 'SoilVertex', 'StationSeriesAttribute', 'StationSeriesReplacement', 'StructOccupancyCtgry', 'Structure', 'StructureAreaFill', 'StructurePointChar', 'StructureVertex', 'Tank', 'Tap', 'Tee', 'TestPostPoint', 'TestPostPointReading', 'Valve', 'ValveRemark', 'ValveType', 'Vent', 'WaterAnalysis', 'WaterAnalysisReading', 'WaterTesting', 'Weight')
 
INSERT INTO ERDiagram_VirtualTables
SELECT name FROM sys.tables WHERE name IN ('VirtualColumn', 'VirtualTable', 'VirtualTableDataDate', 'VirtualTableDataFlg', 'VirtualTableDataInd', 'VirtualTableDataListDomain', 'VirtualTableDataNum', 'VirtualTableDataString', 'VirtualTableStationing')

INSERT INTO ERDiagram_RiskTables
SELECT name FROM sys.tables WHERE name IN ('CalcClassArea', 'CalcClassStructXref', 'CalcLeakTimeProfile', 'CalcOutflowLeakProfile', 'CalcOutflowStatistics', 'CalcOutflowStatisticsType', 'CalcOutflowValveProfile', 
'CalcOverlandLeakProfile', 'Calculator', 'CalculatorKind', 'CalculatorParameters', 'CalculatorProject', 'CalculatorProjectSelection', 'CalculatorType', 'MatrixCellColorTemplate', 'MatrixColorTemplate')
AND name LIKE 'Risk%'

INSERT INTO ERDiagram_OutsideForceTables
SELECT name FROM sys.tables WHERE name IN ('EarthQuakeArea', 'FaultArea', 'FloodArea', 'FrostArea', 'HurricaneArea', 'LandSlideArea', 'LandUse', 'LightningStrikeArea', 'SoilLandUseArea', 'TornadoDensityArea')

INSERT INTO ERDiagram_DataExchangeTables
SELECT name FROM sys.tables WHERE name IN ('Load_Bend', 'Load_Casing', 'Load_ClassArea', 'Load_Coating', 'Load_CoatingCondition', 'Load_Corporation', 'Load_Coupon', 'Load_CouponReading', 'Load_CoverDepth', 'Load_CoverDepthProfile', 'Load_CPSurvey', 'Load_CPSurveyRange', 'Load_CPSurveyReading', 'Load_Crossing', 'Load_CrossingLocn', 'Load_DamagePrevention', 'Load_DesignClass', 'Load_DischargeSubsystem', 'Load_EarthQuakeArea', 'Load_Elbow', 'Load_ElevationProfile', 'Load_ExcavationProject', 'Load_ExcavationSite', 'LOAD_EXCAVSITECRACKANOMALY', 'Load_ExposedPipe', 'Load_Extrusion', 'Load_Flange', 'Load_FloodArea', 'Load_GirthWeld', 'Load_HCACFR', 'Load_HCACFRSeg', 'Load_HCAPipeGasConstantFactor', 'Load_HCAPipePIRBuffer', 'Load_HydroTest', 'Load_HydroTestRange', 'Load_ILICrackAnomaly', 'Load_ILICrsnCallBox', 'Load_ILINonCrsnDfct', 'Load_Incident', 'Load_IncidentHistory', 'Load_InlineInspection', 'Load_InlineInspectionFacility', 'Load_InlineInspectionFeature', 'Load_InlineInspectionJoint', 'Load_InlineInspectionRange', 'Load_InternalCoating', 'Load_IRASCustomData1', 'Load_IRASCustomData11', 'Load_IRASCustomData2', 'Load_IRASCustomData3', 'Load_IRASCustomData4', 'Load_IRASCustomData5', 'Load_IRASCustomData6', 'Load_IRASCustomData7', 'Load_IRASCustomData8', 'Load_IRASCustomData9', 'Load_JointCoating', 'load_LandSlideArea', 'Load_LandUse', 'Load_LineLoop', 'Load_MAOP', 'Load_Marker', 'Load_MetalLoss', 'Load_MLVCorrection', 'Load_MLVSection', 'Load_MOP', 'Load_Node', 'Load_NodeConnection', 'Load_OperatingData', 'Load_OperatingUnit', 'Load_PipelineSystem', 'Load_PipeSegment', 'Load_ProductComponent', 'Load_Rectifier', 'Load_RectifierReading', 'Load_Reducer', 'Load_RightOfWay', 'Load_SeriesConnection', 'Load_Sleeve', 'Load_SoilArea', 'Load_SoilLandUseArea', 'Load_StationSeries', 'Load_Structure', 'Load_StructureVertex', 'Load_Tap', 'Load_Tee', 'Load_TestPostPoint', 'Load_TestPostPointReading', 'Load_Valve', 'Load_Vent', 'LOAD_VT_DATADATE', 'LOAD_VT_DATAFLG', 'LOAD_VT_DATAIND', 'LOAD_VT_DATALISTDOMAIN', 'LOAD_VT_DATANUM', 'LOAD_VT_DATASTRING', 'LOAD_VT_STATIONING', 'Load_Weight')

INSERT INTO ERDiagram_POETables
SELECT name FROM sys.tables WHERE name IN ('MonteCarloPOE', 'MonteCarloPOECalc', 'MonteCarloPOEYear', 'POECoatingProperty', 'POECompanyLookup')

INSERT INTO ERDiagram_IRASCustomTables
SELECT name FROM sys.tables WHERE name IN ('IRASCustomData1', 'IRASCustomData11', 'IRASCustomData2', 'IRASCustomData3', 'IRASCustomData4', 'IRASCustomData5', 'IRASCustomData6', 'IRASCustomData7', 'IRASCustomData8', 'IRASCustomData9')

INSERT INTO ERDiagram_DataManagerTables
SELECT name FROM sys.tables WHERE name IN ('DataManagerCategory', 'DataManagerField', 'DataManagerTable')

INSERT INTO ERDiagram_ConfiguratonTables
SELECT name FROM sys.tables WHERE name IN ('ActionItem', 'ActionItemComments', 'ActionItemPropDCXRef', 'ActionItemProperty', 'ActionItemPropertyValue', 'ActionItemRange', 'ActionItemRevision', 'AppList', 'AppTableListXref', 'AppTables', 'Category', 'CategoryDataListDomainXRef', 'CategoryDataNumXRef', 'Connection', 'ConnectionType', 'Constant', 'DisplayField', 'DynamicIntegration', 'IDAllocation', 'IdentityColumn', 'IdentityColumnGrouping', 'IrasType', 'LineLoopStatus', 'MetaDataColumn', 'MetaDataForeignKey', 'MetaDataForeignKeyColumn', 'MetaDataTable', 'RememberedListDomainValues', 'ScriptTracker', 'SupplementalPermissions', 'sysdiagrams', 'SystemPreferences', 'TempTableLog', 'UnitConversion', 'UnitOfMeasure', 'VersionHistory', 'VersionInfo')

INSERT INTO ERDiagram_StagingTables
SELECT name FROM sys.tables WHERE name IN ('Stg_ILI', 'Stg_ILIAxialStrain', 'Stg_ILIBendStrain', 'Stg_ILICrackAnomaly', 'Stg_ILICrsnCallBox', 'Stg_ILIEventTable', 'Stg_ILIEventTableLD', 'Stg_ILIFacility', 'Stg_ILIFeature', 'Stg_ILIJoint', 'Stg_ILINonCrsnDfct', 'Stg_ILIRange', 'Stg_ILIStrain', 'Stg_Maintenance')

INSERT INTO ERDiagram_TableCheckerTables
SELECT name FROM sys.tables WHERE name IN ('TblChkErrCenterline', 'TblChkErrDataGaps', 'TblChkErrInvalidRecord', 'TblChkErrOverlap', 'TblChkErrStationGap')

INSERT INTO ERDiagram_ComplianceAuditorTables
SELECT name FROM sys.tables WHERE name IN ('RADIMClassifierCategory', 'RADIMP', 'RADIMPClassifier', 'RADIMPClassifierItem', 'RADIMPEquipmentService', 'RADIMPScoreTable', 'RADIMPVariable', 'RADIMPView', 'RADIMPViewColumn', 'RADIMPViewSection', 'RADIMPViewSectionColumnXRef', 'RCCategoryStructure', 'RCComputationType', 'RCCSAClassCalc', 'RCCSAClassCalcFlagType', 'RCCSAClassCalcSeg', 'RCCSAClassFlags', 'RCCSAClassFlagType', 'RCDIMP', 'RCDIMPBaseRun', 'RCDIMPBucket', 'RCDIMPBucketCategory', 'RCDIMPBucketCategoryValue', 'RCDIMPBucketConstraint', 'RCDIMPBucketCount', 'RCDIMPBucketLeakGradeConseq', 'RCDIMPBucketMileage', 'RCDIMPEquipment', 'RCDIMPEquipmentCount', 'RCDIMPEquipmentPerBucket', 'RCDIMPLeakGrade', 'RCDIMPPromote', 'RCDIMPRemarks', 'RCDIMPScoreTableValue', 'RCDIMPThreat', 'RCDIMPVariable', 'RCDIMPVariableLeakGradeXRef', 'RCDIMPVariableValueNum_1', 'RCDOTClassCalc', 'RCDOTClassCalcFlagType', 'RCDOTClassCalcSeg', 'RCDOTClassFlags', 'RCDOTClassFlagType', 'RCHCACalc', 'RCHCACalcSeg', 'RCHCAFlags', 'RCHCAFlagType', 'RCHCAReasons', 'RCHCAReasonType', 'RCHCAStructures', 'RCMAOPCALC', 'RCMAOPCalcSeg', 'RCMAOPFlagActionType', 'RCMAOPFlagProcessType', 'RCMAOPFlagReasonType', 'RCMAOPFlags', 'RCMAOPLIMIT', 'RCProject', 'RCProjectSelection', 'RCScenario', 'RCScenarioCategoryStructure', 'RCScenarioOptions', 'RCScenarioStructure', 'RCScenarioStructureVertex', 'RCStructureCategory', 'RCStructureCategoryType', 'RCStructureData')

INSERT INTO ERDiagram_LookupTables
SELECT name FROM sys.tables WHERE name IN ('DomainCatalog', 'DomainCatalogColXRef', 'ListDomain')
