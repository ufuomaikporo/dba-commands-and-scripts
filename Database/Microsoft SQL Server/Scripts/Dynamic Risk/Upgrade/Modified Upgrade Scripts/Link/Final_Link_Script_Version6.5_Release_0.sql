IF NOT EXISTS (SELECT * FROM dbo.SystemPreferences sp WHERE sp.ParameterName = 'DatabaseType' AND sp.Value = 'Link')
BEGIN
	RAISERROR( 'The target database is not Link database for applying this upgrade script.', 11, 0)
END
GO


--Script_To_Improve_Query_Performance_SQLServer.sql
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640205 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			--Script_To_Improve_Query_Performance_SQLServer.sql
			DECLARE @sql nvarchar(max)

			SET @sql = 'IF EXISTS (SELECT * FROM sys.objects WHERE type = ''P'' AND name = ''GetLineRangeIdsByToolTypeProcedure'')
						BEGIN
							DROP PROCEDURE [dbo].[GetLineRangeIdsByToolTypeProcedure]
						END'
			EXEC sp_executesql @sql

			SET @sql = 'IF type_id(''[dbo].[LineInfoTableType]'') IS NOT NULL
						BEGIN
							DROP TYPE [dbo].[LineInfoTableType];
						END'
			EXEC sp_executesql @sql

			SET @sql = 'CREATE TYPE [dbo].[LineInfoTableType] AS TABLE(
							[LineId] [numeric](10, 0) NULL,
							[BeginMeasure] [numeric](13, 5) NULL,
							[EndMeasure] [numeric](13, 5) NULL
						)'
			EXEC sp_executesql @sql

			SET @sql = 'CREATE PROCEDURE [dbo].[GetLineRangeIdsByToolTypeProcedure]
							@LineInfoTableParameter dbo.LineInfoTableType READONLY,
							@ToolTypeIdParameter numeric(10,0)
						AS
						BEGIN

						DECLARE @lineID numeric(10,0);
						DECLARE @beginMeasure numeric(13,5);
						DECLARE @endMeasure numeric(13,5);



						DECLARE LineInfoCursor CURSOR FOR
						SELECT LineID, BeginMeasure, EndMeasure FROM @LineInfoTableParameter;

						CREATE TABLE #TempTable
							(
								InlineInspectionID numeric(10,0),
								 InlineInspectionRangeID numeric(10,0),
								 ILIStartDate  Date
							);

						OPEN LineInfoCursor;

						FETCH NEXT FROM LineInfoCursor INTO  @lineID, @beginMeasure, @endMeasure;
						 print @lineID;
						 print @beginMeasure;
						 print  @endMeasure;
						WHILE @@FETCH_STATUS = 0
						BEGIN
								INSERT INTO #TempTable
  													SELECT ili.Id AS InlineInspectionID, 
																							ilir.Id AS InlineInspectionRangeID,
																							ili.ILIStartDate 
																	
																				   FROM InlineInspection ili
																				   INNER JOIN (
																						SELECT case when MAX(ili.ILIStartDate) IS null then @@DATEFIRST ELSE MAX(ili.ILIStartDate) END AS LatestDate
																						FROM InlineInspection ili
																						INNER JOIN InlineInspectionRange ilir
																						 ON ilir.InlineInspectionId = ili.Id
																						INNER JOIN MLVCorrection beginMLVC
																						 ON beginMLVC.StationSeriesId = ilir.BeginStationSeriesId
																						 AND beginMLVC.EffectiveEndDate IS NULL
																						 AND beginMLVC.BeginStationNum <= ilir.BeginStationNum
																						 AND beginMLVC.EndStationNum >= ilir.BeginStationNum
																						INNER JOIN MLVCorrection endMLVC
																						 ON endMLVC.StationSeriesId = ilir.EndStationSeriesId
																						 AND endMLVC.EffectiveEndDate IS NULL
																						 AND endMLVC.BeginStationNum <= ilir.EndStationNum
																						 AND endMLVC.EndStationNum >= ilir.EndStationNum
																						INNER JOIN StationSeries beginSS
																						 ON beginSS.Id = ilir.BeginStationSeriesId
																						 AND beginSS.EffectiveEndDate IS NULL
																						 AND beginSS.LineLoopId = @lineID
																						WHERE (ilir.EffectiveEndDate IS NULL
																						AND (ilir.BeginStationNum * beginMLVC.MultiplierNum + beginMLVC.FactorNum <= @beginMeasure AND ilir.EndStationNum * endMLVC.MultiplierNum + endMLVC.FactorNum >= @beginMeasure)
																						OR (ilir.BeginStationNum * beginMLVC.MultiplierNum + beginMLVC.FactorNum >= @beginMeasure AND ilir.BeginStationNum * beginMLVC.MultiplierNum + beginMLVC.FactorNum <= @endMeasure))
																						 AND ((@ToolTypeIdParameter is null) OR (NOT (@ToolTypeIdParameter is null) AND (ili.ILITypeDomainId = @ToolTypeIdParameter)))
																					) dateQuery ON case when ili.ILIStartDate IS null then @@DATEFIRST ELSE ili.ILIStartDate END = dateQuery.LatestDate
																					INNER JOIN InlineInspectionRange ilir
																						 ON ilir.InlineInspectionId = ili.Id
																						INNER JOIN MLVCorrection beginMLVC
																						 ON beginMLVC.StationSeriesId = ilir.BeginStationSeriesId
																						 AND beginMLVC.EffectiveEndDate IS NULL
																						 AND beginMLVC.BeginStationNum <= ilir.BeginStationNum
																						 AND beginMLVC.EndStationNum >= ilir.BeginStationNum
																						INNER JOIN MLVCorrection endMLVC
																						 ON endMLVC.StationSeriesId = ilir.EndStationSeriesId
																						 AND endMLVC.EffectiveEndDate IS NULL
																						 AND endMLVC.BeginStationNum <= ilir.EndStationNum
																						 AND endMLVC.EndStationNum >= ilir.EndStationNum
																						INNER JOIN StationSeries beginSS
																						 ON beginSS.Id = ilir.BeginStationSeriesId
																						 AND beginSS.EffectiveEndDate IS NULL
																						 AND beginSS.LineLoopId = @lineID
																						WHERE ilir.EffectiveEndDate IS NULL
																						AND ((ilir.BeginStationNum * beginMLVC.MultiplierNum + beginMLVC.FactorNum <= @beginMeasure AND ilir.EndStationNum * endMLVC.MultiplierNum + endMLVC.FactorNum >= @beginMeasure)
																						 OR (ilir.BeginStationNum * beginMLVC.MultiplierNum + beginMLVC.FactorNum >= @beginMeasure AND ilir.BeginStationNum * beginMLVC.MultiplierNum + beginMLVC.FactorNum <= @endMeasure))

																						FETCH NEXT FROM LineInfoCursor INTO  @lineID, @beginMeasure, @endMeasure;
										
						END
				
										SELECT * FROM #TempTable;
										Drop Table #TempTable;
						END'
			EXEC sp_executesql @sql

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	PRINT CHAR(10) + 'Suspected Failed SQL Statement: ' + CHAR(10) + CHAR(10) + @SQL + CHAR(10)
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


-- 1_CleanUp_Transmission_Database.sql
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640205 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			-- 1_CleanUp_Transmission_Database.sql

			DECLARE @list NVARCHAR(MAX)
			DECLARE @TableName NVARCHAR(100)
			DECLARE @GetTableList NVARCHAR(MAX)
			DECLARE @TableList TABLE (table_name NVARCHAR(100))
			DECLARE @FKConstraintList TABLE (id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED, FK_Table NVARCHAR(100), constraint_name NVARCHAR(100))
			DECLARE @GetFKConstraints NVARCHAR(MAX)
			DECLARE @SQL NVARCHAR(600)
			DECLARE @FK_Table NVARCHAR(100)
			DECLARE @constraint_name NVARCHAR(100)

			-- List of tables to be deleted
			SET @List = N'AppList
			AppTableListXref
			AppTables
			CASurvey
			CASurveyRange
			CASurveyReading
			CategoryDataNumXRef
			CenterlineAlignment
			CenterlineAlignmentDependency
			CenterlineDefinition
			CenterlineMapping
			Classification
			ClassificationRange
			ClassLocationStructCtgry
			CoatingDefect
			CoatingThickness
			Constant
			CrackAnomaly
			CrackAnomalyCluster
			CrossingLocnMay8
			CrossingMay8
			DBS_Data_Dat_1
			DBS_Data_Dat_2
			DBS_Data_Dat_3
			DBS_Data_Dat_4
			DBS_Data_Dat_5
			DBS_Data_Dat_6
			DBS_Data_Dat_7
			DBS_Data_Dat_8
			DBS_Data_Ind_1
			DBS_Data_Ind_10
			DBS_Data_Ind_11
			DBS_Data_Ind_12
			DBS_Data_Ind_13
			DBS_Data_Ind_14
			DBS_Data_Ind_15
			DBS_Data_Ind_16
			DBS_Data_Ind_17
			DBS_Data_Ind_18
			DBS_Data_Ind_19
			DBS_Data_Ind_2
			DBS_Data_Ind_20
			DBS_Data_Ind_3
			DBS_Data_Ind_4
			DBS_Data_Ind_5
			DBS_Data_Ind_6
			DBS_Data_Ind_7
			DBS_Data_Ind_8
			DBS_Data_Ind_9
			DBS_Data_Int_1
			DBS_Data_Int_10
			DBS_Data_Int_11
			DBS_Data_Int_12
			DBS_Data_Int_13
			DBS_Data_Int_14
			DBS_Data_Int_15
			DBS_Data_Int_16
			DBS_Data_Int_17
			DBS_Data_Int_18
			DBS_Data_Int_19
			DBS_Data_Int_2
			DBS_Data_Int_20
			DBS_Data_Int_3
			DBS_Data_Int_4
			DBS_Data_Int_5
			DBS_Data_Int_6
			DBS_Data_Int_7
			DBS_Data_Int_8
			DBS_Data_Int_9
			DBS_Data_Num_1
			DBS_Data_Num_10
			DBS_Data_Num_11
			DBS_Data_Num_12
			DBS_Data_Num_13
			DBS_Data_Num_14
			DBS_Data_Num_15
			DBS_Data_Num_16
			DBS_Data_Num_17
			DBS_Data_Num_18
			DBS_Data_Num_19
			DBS_Data_Num_2
			DBS_Data_Num_20
			DBS_Data_Num_3
			DBS_Data_Num_4
			DBS_Data_Num_5
			DBS_Data_Num_6
			DBS_Data_Num_7
			DBS_Data_Num_8
			DBS_Data_Num_9
			DBS_Data_Str_1
			DBS_Data_Str_2
			DBS_Data_Str_3
			DBS_Data_Str_4
			DBS_Data_Str_5
			DBS_Data_Str_6
			DBS_Data_Str_7
			DBS_Data_Str_8
			DBS_Links
			DynamicIntegration
			EditValueisnull
			FailureDetection
			IdentityColumn
			IdentityColumnGrouping
			ILIArtifactXRef
			ILIError
			ILIExcavation
			InlineInspectionJoint12102019
			InlineInspectionRemark
			InspectionData
			IntegrationType
			InternalInspection
			IrasType
			Joint
			Joint2010
			LineLoopStatus
			Maintenance
			MaintenanceProject
			MAOPPipeProperties
			MetaDataColumn
			MetaDataForeignKey
			MetaDataForeignKeyColumn
			MetaDataTable
			MetricfullsystemDefaultSu
			MICAnalysis
			MICAnalysisReading
			Node
			NodeConnection
			NodeNetwork
			NodeNetworkNodes
			PCMSurvey
			PCMSurveyRange
			PCMSurveyReading
			PointChar
			PredefinedLocation
			QueryStructure
			RADIMClassifierCategory
			RADIMP
			RADIMPClassifier
			RADIMPClassifierItem
			RADIMPEquipmentService
			RADIMPScoreTable
			RADIMPVariable
			RADIMPView
			RADIMPViewColumn
			RADIMPViewSection
			RADIMPViewSectionColumnXRef
			RCCategoryStructure
			RCCSAClassCalc
			RCCSAClassCalcFlagType
			RCCSAClassCalcSeg
			RCCSAClassFlags
			RCCSAClassFlagType
			RCDIMP
			RCDIMPBaseRun
			RCDIMPBucket
			RCDIMPBucketCategory
			RCDIMPBucketCategoryValue
			RCDIMPBucketConstraint
			RCDIMPBucketCount
			RCDIMPBucketLeakGradeConseq
			RCDIMPBucketMileage
			RCDIMPEquipment
			RCDIMPEquipmentCount
			RCDIMPEquipmentPerBucket
			RCDIMPLeakGrade
			RCDIMPPromote
			RCDIMPRemarks
			RCDIMPScoreTableValue
			RCDIMPThreat
			RCDIMPVariable
			RCDIMPVariableLeakGradeXRef
			RCDIMPVariableValueNum_1
			RCDOTClassCalc
			RCDOTClassCalcFlagType
			RCDOTClassCalcSeg
			RCDOTClassFlags
			RCDOTClassFlagType
			RCMAOPCALC
			RCMAOPCalcSeg
			RCMAOPFlagActionType
			RCMAOPFlagProcessType
			RCMAOPFlagReasonType
			RCMAOPFlags
			RCMAOPLIMIT
			RCStructureCategory
			RCStructureCategoryType
			RiskAlgorithm
			RISKALGORITHMCHARTCATDATXREF
			RISKALGORITHMCHARTCATEGORY
			RISKALGORITHMCHARTCATEGORYDATA
			RISKALGORITHMCOLUMBYCATEGORY
			RISKALGORITHMCOLUMN
			RISKALGORITHMCOLUMNCATEGORY
			RiskAlgorithmConstant
			RiskAlgorithmDissolve
			RiskAlgorithmDissolveBase
			RiskAlgorithmDissolveColumn
			RiskAlgorithmMIMProgram
			RiskAlgorithmMIMProgramCat
			RiskAlgorithmMIMPVariable
			RiskAlgorithmModel
			RiskAlgorithmModelColXRef
			RiskAlgorithmModelDisplay
			RiskAlgorithmProgramXRef
			RiskAlgorithmScoreTable
			RiskAlgorithmScript
			RiskAlgorithmSeries
			RiskAlgorithmSeriesTable
			RiskAlgorithmSeriesVarXRef
			RiskAlgorithmVariable
			RiskAlgorithmVirtualTable
			RiskCalcModelVariableXRef
			RiskCalcModelVariablHierarchy
			RiskCalcScoreTableValue
			RiskCalculation
			RiskCalculationCaseStudy
			RiskCalculationCaseStudyId
			RiskCalculationCaseStudyProg
			RiskCalculationCaseStudyRange
			RiskCalculationCaseStudyVar
			RISKCALCULATIONCOLOURING
			RISKCALCULATIONCOLOURINGRANGE
			RiskCalculationConstant
			RiskCalculationCorporation
			RiskCalculationCorrectionPos
			RISKCALCULATIONDATACOLUMN
			RISKCALCULATIONDATACONDITION
			RISKCALCULATIONDATASOURCE
			RISKCALCULATIONDATATABLE
			RiskCalculationDCColXRef
			RiskCalculationDischargeSubSys
			RiskCalculationDomainCatalog
			RiskCalculationGroup
			RiskCalculationGrouping
			RiskCalculationGroupingFilter
			RiskCalculationHCA
			RiskCalculationHCAAssesFolder
			RiskCalculationHCAAssessment
			RiskCalculationHCACatalog
			RiskCalculationHCACatalogItem
			RiskCalculationHCAFolder
			RiskCalculationHCAILI
			RiskCalculationHCAModel
			RiskCalculationHCARankColor
			RiskCalculationHCAReasons
			RISKCALCULATIONHCARTGROUP
			RISKCALCULATIONHCARTGRREASON
			RiskCalculationHCASeg
			RiskCalculationHCASetup
			RiskCalculationHCASubst
			RiskCalculationId
			RISKCALCULATIONILICALC
			RISKCALCULATIONILICALCCOND
			RiskCalculationILIDefectType
			RiskCalculationILIDomainIds
			RISKCALCULATIONILIFEATURE
			RISKCALCULATIONILIRANGE
			RISKCALCULATIONILIRANGEDEFECT
			RISKCALCULATIONILISEGMENT
			RISKCALCULATIONILISEGMENTOVR
			RiskCalculationILISetup
			RiskCalculationIncident
			RISKCALCULATIONINCIDENTCOND
			RiskCalculationIncidentDamage
			RiskCalculationIncidentGroup
			RiskCalculationIncidentThreat
			RiskCalculationLineGroup
			RiskCalculationLineGroupSSFact
			RiskCalculationLineLoop
			RiskCalculationListDomain
			RiskCalculationMarkerPos
			RiskCalculationMatrix
			RiskCalculationMatrixCell
			RiskCalculationMatrixColor
			RiskCalculationMatrixRange
			RiskCalculationMLVCorrection
			RiskCalculationMLVSection
			RiskCalculationModel
			RISKCALCULATIONMODELSET
			RISKCALCULATIONMODELSETGROUP
			RISKCALCULATIONMODELSETMODEL
			RISKCALCULATIONMODELSETVAR
			RiskCalculationOperatingUnit
			RiskCalculationPipelineSystem
			RiskCalculationRemark
			RiskCalculationSectionPos
			RiskCalculationSegment
			RiskCalculationSegmentByGroup
			RiskCalculationSegmentFull
			RiskCalculationSegmentOverlap
			RiskCalculationStationSeries
			RiskCalculationTotalVarXRef
			RiskCalculationTPSurveySetup
			RiskCalculationVariable
			RiskCalculationVariableDepend
			RiskCalculationView
			RiskCalculationViewSelection
			StationSeriesAttribute
			StationSeriesReplacement
			Stg_ILIEventTable
			Stg_ILIEventTableLD
			Stg_Maintenance
			SupplementalPermissions
			TempTableLog
			TestCustom
			tmpListDomain
			tmpListDomain_Identity
			tmpStg_ILIAxialStrain'

			SET @List = REPLACE(@List, ' ', '')
			SET @List = REPLACE(@List, CHAR(10), ' ')
			SET @List = REPLACE(@List, CHAR(13), '')
			SET @List = REPLACE(@List, CHAR(9), '')
			SET @List = REPLACE(@List, ' ', ''', ''')
			SET @List = REPLACE(@List, ''''', ', '')

			SET @List = '''' + @List + ''''

			-- Generate Query to get a list of all the tables that need to be dropped (results stored in a temporary table)
			SET @GetTableList = 'DECLARE @result TABLE (table_name NVARCHAR(100))
			INSERT INTO @Result
			SELECT table_name FROM information_schema.tables
			WHERE table_name in (' + @List + ') 
			SELECT * FROM @Result'

			INSERT INTO @TableList
			EXECUTE sp_executesql @GetTableList

			DECLARE DeleteTable_Cursor CURSOR FOR
			SELECT * FROM @TableList

			OPEN DeleteTable_Cursor  
			FETCH NEXT FROM DeleteTable_Cursor INTO @TableName 

			-- Outer While loop cycles through the tables that needs to be deleted
			WHILE @@FETCH_STATUS = 0  
			BEGIN 
	
				-- Generate query to get list of foreign keys referencing the table in the current iteration (store result in temp table)
				SET @GetFKConstraints = 'DECLARE @Result TABLE (FK_table NVARCHAR(100), constraint_name NVARCHAR(300))
				INSERT INTO @Result
				SELECT SubQ.table_name, SubQ.constraint_name 
				FROM
				(
				SELECT DISTINCT(rc.constraint_name), fk_info.TABLE_NAME
				FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
				JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE fk_info
					ON rc.constraint_name = fk_info.constraint_name
				JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE pk_info
					ON rc.unique_constraint_name = pk_info.constraint_name
				JOIN INFORMATION_SCHEMA.TABLES tab
					ON tab.TABLE_NAME = pk_info.table_name
				WHERE pk_info.table_name = ''' + @TableName + '''
				AND tab.TABLE_TYPE = ''BASE TABLE'') SubQ
	
				SELECT * FROM @Result'

				INSERT INTO @FKConstraintList
				EXECUTE sp_executesql @GetFKConstraints

				-- Check if there are any foreign key constraints on the table
				IF (SELECT COUNT(*) FROM @FKConstraintList) > 0
				BEGIN
					DECLARE @Counter INT = 1
					DECLARE @TabLength INT 
					SELECT @TabLength = MAX(id) FROM @FKConstraintList

					-- Inner loop deletes foreign keys referencing the table in the outer loop
					WHILE @Counter <= (SELECT MAX(ID) FROM @FKConstraintList)
					BEGIN
						SELECT @constraint_name = constraint_name FROM @FKConstraintList
						WHERE id = @Counter

						SELECT @FK_Table = FK_Table FROM @FKConstraintList
						WHERE id = @Counter

						IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = @constraint_name) --AND parent_object_id = OBJECT_ID('' + @FK_Table + ''))
						BEGIN
							SET @SQL = 'ALTER TABLE ' + @FK_Table + ' DROP CONSTRAINT ' + @constraint_name

							-- Drops foreign key
							EXECUTE (@SQL)
						END
		
						SET @Counter += 1
					END
				END 
    
				-- Drops Table
				EXECUTE ('DROP TABLE dbo.' + @TableName )

				FETCH NEXT FROM DeleteTable_Cursor INTO @TableName 
			END 
			CLOSE DeleteTable_Cursor  
			DEALLOCATE DeleteTable_Cursor			
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 2, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	PRINT CHAR(10) + 'Suspected Failed SQL Statement: ' + CHAR(10) + CHAR(10) + @SQL + CHAR(10)
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


-- 2_Modify_ListDomain_ColumnDefinition.sql
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640205 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			/*

			This script modifies the length of the Listdomain 'Id' column as well as the length of all other tables columns
			reference it to precision 10 and scale 0. 

			This script must be executed on the target database

			*/
			DECLARE @SQL NVARCHAR(MAX)
			DECLARE @TableName NVARCHAR(100)
			DECLARE @ColumnName NVARCHAR(100)
			DECLARE @IndexName NVARCHAR(100)
			DECLARE @GetIndexInfo NVARCHAR(MAX)
			DECLARE @ColumnList1 NVARCHAR(600)
			DECLARE @ColumnList2 NVARCHAR(600)
			DECLARE @IsNullable NVARCHAR(10) 

			DECLARE @GetFKConstraints NVARCHAR(MAX)
			DECLARE @FK_Table NVARCHAR(100)
			DECLARE @FK_column NVARCHAR(100)
			DECLARE @PK_table NVARCHAR(100)
			DECLARE @PK_column NVARCHAR(100)
			DECLARE @ConstraintName NVARCHAR(100)
			DECLARE @CMD NVARCHAR(MAX)
			DECLARE @GetExistsCheck NVARCHAR(MAX)
			DECLARE @IfExistsCheck INT = 0

			-- Temporary Table to store Foriegn key info
			DECLARE @FKConstraintList TABLE (constraint_name NVARCHAR(300), 
											FK_table_name NVARCHAR(100), 
											FK_column_name NVARCHAR(100),
											PK_table_name NVARCHAR(100),
											PK_column_name NVARCHAR(100))

			DROP TABLE IF EXISTS Temp_Constraint_Definitions_upgr

			-- Table to Store Foreign Key Constraints
			IF OBJECT_ID('Temp_Constraint_Definitions_upgr', 'U') IS NULL
			BEGIN
				CREATE TABLE Temp_Constraint_Definitions_upgr (id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED, 
															table_name NVARCHAR(100),
															constraint_name NVARCHAR(100), 
															definition NVARCHAR(MAX)
															)
			END

			-- Permanent table to store commands for recreating an index
			IF OBJECT_ID('Temp_Index_Definition_Upgr', 'U') IS NULL
			BEGIN
				CREATE TABLE Temp_Index_Definition_Upgr (id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED, 
													  index_name NVARCHAR(100), 
													  table_name NVARCHAR(100),
													  column_name NVARCHAR(100),
													  definition NVARCHAR(MAX)
													 )
			END

			IF OBJECT_ID('AlterColumnList_upgr') IS NOT NULL
			BEGIN 
				DROP TABLE AlterColumnList_upgr
			END

			IF OBJECT_ID('tempdb..AlterColumnList_upgr') IS  NULL
			BEGIN
				CREATE TABLE AlterColumnList_upgr (fk_table NVARCHAR(100), 
										  fk_column NVARCHAR(100), 
										  is_nullable NVARCHAR(15),
										  precision INT,
										  scale INT)

				INSERT INTO AlterColumnList_upgr
				SELECT 'ListDomain', 'Id', 'NOT NULL', NULL precision, NULL scale
				UNION
				SELECT fk_table, fk_column, is_nullable, precision, scale
				FROM
				(SELECT OBJECT_NAME(parent_object_id) AS fk_table, 
					COL_NAME(parent_object_id, parent_column_id) AS fk_column,
					CASE
						WHEN is_nullable = 0 THEN 'NOT NULL'
						ELSE 'NULL'
					END AS is_nullable,
					col.precision,
					col.scale 
				FROM sys.foreign_key_columns fk_col
				JOIN sys.columns col ON fk_col.parent_object_id = col.object_id
					AND fk_col.parent_column_id = col.column_id
				WHERE OBJECT_NAME(referenced_object_id) = 'ListDomain'
				AND COL_NAME(referenced_object_id, referenced_column_id) = 'Id'
				OR COL_NAME(parent_object_id, parent_column_id) LIKE '%DomainId'
				) SubQ
				
				INSERT INTO AlterColumnList_upgr
				SELECT table_name AS fk_table, 
						column_name AS fk_column,
						CASE
							WHEN is_nullable = 'NO' THEN 'NOT NULL'
							ELSE 'NULL'
						END AS is_nullable,
						numeric_precision,
						numeric_scale
				FROM INFORMATION_SCHEMA.columns col
				WHERE column_name LIKE '%DomainId'
				AND data_type = 'numeric' 
				AND NOT EXISTS (SELECT * FROM AlterColumnList_upgr WHERE fk_column = col.column_name 
								AND fk_table = col.table_name
								)
				AND col.table_name IN (SELECT name FROM sys.tables)
			END

			DECLARE AlterColumn_cursor CURSOR FOR
			SELECT fk_table, fk_column, is_nullable 
			FROM AlterColumnList_upgr
			WHERE precision <> 10 OR scale <> 0	
			

			OPEN AlterColumn_cursor
			FETCH NEXT FROM AlterColumn_cursor INTO @TableName, @ColumnName, @IsNullable

			WHILE @@FETCH_STATUS = 0
			BEGIN
	
			------------------------------------------ SAVE INDEX DEFINITIONS Then Drop Indexes -----------------------------------------------

				/*
					Indexes on a column whose definition needs to be modified must be dropped first before modifying the column definition.
					This section of the script stores index definitions for the table and column in the current loop iteration, 
					then drops the selected indexes
				*/

				-- Temp table to store info for rebulding index
				DECLARE @IndexInfo_Tab TABLE (id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
											index_name NVARCHAR(100), 
											type NVARCHAR(50), 
											table_name NVARCHAR(100), 
											column_name NVARCHAR(100),
											is_descending CHAR(3),
											index_column_id INT,
											is_included_column INT,
											is_padded NVARCHAR(3),
											allow_row_locks NVARCHAR(3),
											allow_page_locks NVARCHAR(3)
											--optimize_for_sequential_key NVARCHAR(3)
											)

				-- Command to generate index info
				SET @GetIndexInfo = 'DECLARE @result TABLE (index_name NVARCHAR(100), 
															type NVARCHAR(50), 
															table_name NVARCHAR(100), 
															column_name NVARCHAR(100),
															is_descending CHAR(3),
															index_column_id INT,
															is_included_column INT,
															is_padded NVARCHAR(3),
															allow_row_locks NVARCHAR(3),
															allow_page_locks NVARCHAR(3)
															--optimize_for_sequential_key NVARCHAR(3)
															)
				INSERT INTO @result
				SELECT DISTINCT(ind.name) AS index_name,
						ind.type_desc,
						OBJECT_NAME(ind.object_id) AS table_name, 
						COL_NAME(ind.object_id, column_id) AS column_name,  
						CASE
							WHEN is_descending_key = 0 THEN ''ASC''
							ELSE ''DESC''
						END AS is_descending,
						ind_col.Index_column_id,
						ind_col.is_included_column,
						CASE
						WHEN ind.is_padded = 0 THEN ''OFF''
						ELSE ''ON''
						END AS is_padded,
						CASE
						WHEN ind.allow_row_locks = 1 THEN ''ON''
						ELSE ''OFF''
						END AS allow_row_locks,
						CASE
						WHEN ind.allow_page_locks = 1 THEN ''ON''
						ELSE ''OFF''
						END AS allow_page_locks
				FROM sys.index_columns ind_col
					JOIN sys.indexes ind ON ind_col.object_id = ind.object_id
						AND ind_col.index_id = ind.index_id
				WHERE OBJECT_NAME(ind.object_id) = ''' + @TableName + '''
				AND COL_NAME(ind.object_id, ind_col.column_id) = ''' + @ColumnName + '''
				AND ind.is_primary_key = 0

				SELECT * FROM @result'

				INSERT INTO @IndexInfo_Tab
				EXECUTE (@GetIndexInfo)

				-- Cursor to cycle through each index on a specific column and generate the CREATE INDEX command for each index that is to be dropped
				DECLARE IndexOnCol_Cursor CURSOR FOR
				SELECT DISTINCT(index_name) FROM @IndexInfo_Tab

				OPEN IndexOnCol_Cursor
				FETCH NEXT FROM IndexOnCol_Cursor INTO @IndexName

				WHILE @@FETCH_STATUS = 0
				BEGIN
					SELECT @SQL = 'CREATE ' + type + ' INDEX [' + index_name + '] ON [dbo].[' + table_name + ']' + CHAR(13) 
								+ '(' 

					FROM @IndexInfo_Tab
					WHERE index_name = @IndexName

					-- Index keys list
					SET @ColumnList1 = NULL

					SELECT @ColumnList1 = COALESCE(@ColumnList1 + ', ' + CHAR(13) + ' ', '') + column_name + ' ' + is_descending 
					FROM @IndexInfo_Tab
					WHERE index_name = @IndexName
					AND is_included_column = 0
					ORDER BY index_column_id

					SET @SQL += @ColumnList1 + CHAR(13) + ')'

					-- builds INCLUDE clause
					IF EXISTS (SELECT 1 FROM @IndexInfo_Tab WHERE index_name = @indexName AND is_included_column = 1)
					BEGIN
						SET @SQL += CHAR(13) + 'INCLUDE ('
		
						SET @ColumnList1 = NULL

						SELECT @ColumnList1 = COALESCE(@ColumnList1 + ', ' + CHAR(13) + ' ', '') + column_name  
						FROM @IndexInfo_Tab
						WHERE index_name = @IndexName
						AND is_included_column = 1
						ORDER BY index_column_id

						SET @SQL += @ColumnList1 + ')'

					END

					--Add WITH CLAUSE
					SELECT @SQL += ' WITH (PAD_INDEX = ' + is_padded + ', ALLOW_ROW_LOCKS = '
					+  allow_row_locks + ', ALLOW_PAGE_LOCKS = ' + allow_page_locks --+ ', OPTIMIZE_FOR_SEQUENTIAL_KEY = ' + optimize_for_sequential_key
					+ ')' 
					FROM @IndexInfo_Tab
					WHERE index_name = @IndexName
					AND id = (SELECT TOP 1 id
					FROM @IndexInfo_Tab
					WHERE index_name = @IndexName)

					SET @GetExistsCheck = 'IF EXISTS (SELECT 1 FROM Temp_Index_Definition_Upgr WHERE index_name = ''' + @IndexName + ''')
											BEGIN
												SET @result = 1
											END
											ELSE
											BEGIN
												SET @result = 0
											END'

					EXECUTE sp_executesql @GetExistsCheck, N'@result INT out', @IfExistsCheck out

					-- Save index in a temporary table
					IF @IfExistsCheck = 0
					BEGIN
						-- Save Foreign Key definition in a permanent table
						INSERT INTO Temp_Index_Definition_Upgr 
						SELECT DISTINCT Index_name, table_name, column_name, @SQL  
						FROM @IndexInfo_Tab
						WHERE Index_name =  @IndexName 

						EXECUTE (@CMD)	
					END

					-- Drop index
					IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = @IndexName)
					BEGIN
						SET @SQL = 'DROP INDEX ' + @IndexName + ' ON ' + @TableName
						EXECUTE sp_executesql @SQL
					END

					FETCH NEXT FROM IndexOnCol_Cursor INTO @IndexName
				END
				CLOSE IndexOnCol_Cursor
				DEALLOCATE IndexOnCol_Cursor

			--------------------------------------- Save Foreign Key Definitions and Drop Foreign keys ---------------------------------

			/*
				Foreign keys referencing the column who's definition needs to be modified must be dropped first before the modification.
				This section of the script saves the foreign key definitions for all foreign keys referencing the table and column
				in the current loop iteration, then drops the foreign key.
			*/

				-- Generate query to get list of foreign keys referencing the column in the current iteration (store result in temp table)
				SET @GetFKConstraints = 'DECLARE @Result TABLE (constraint_name NVARCHAR(300), 
																FK_table_name NVARCHAR(100), 
																FK_column_name NVARCHAR(100),
																PK_table_name NVARCHAR(100),
																PK_column_name NVARCHAR(100)
																)
				INSERT INTO @Result
				SELECT constraint_name, fk_table, fk_column, pk_table, pk_column
				FROM
				(SELECT OBJECT_NAME(constraint_object_id) AS constraint_name,
						OBJECT_NAME(parent_object_id) AS fk_table,
						COL_NAME(parent_object_id, parent_column_id) AS fk_column,
						OBJECT_NAME(referenced_object_id) AS pk_table,
						COL_NAME(referenced_object_id, referenced_column_id) AS pk_column
				FROM sys.foreign_key_columns
				WHERE OBJECT_NAME(referenced_object_id) = ''' + @TableName +  '''
				AND COL_NAME(referenced_object_id, referenced_column_id) = ''' + @ColumnName + '''
				UNION
				SELECT OBJECT_NAME(constraint_object_id) AS constraint_name,
						OBJECT_NAME(parent_object_id) AS fk_table,
						COL_NAME(parent_object_id, parent_column_id) AS fk_column,
						OBJECT_NAME(referenced_object_id) AS pk_table,
						COL_NAME(referenced_object_id, referenced_column_id) AS pk_column
				FROM sys.foreign_key_columns
				WHERE OBJECT_NAME(parent_object_id) = ''' + @TableName + '''
				AND COL_NAME(parent_object_id, parent_column_id) = ''' + @ColumnName + '''
				) SQ
	
				SELECT constraint_name,	FK_table_name, FK_column_name, PK_table_name, PK_column_name 
				FROM @Result'

				INSERT INTO @FKConstraintList
				EXECUTE sp_executesql @GetFKConstraints

				-- Check if there are any foreign key constraints on the table
				IF (SELECT COUNT(1) FROM @FKConstraintList) > 0
				BEGIN
					DECLARE Delete_FK_Cursor CURSOR FOR
					SELECT Constraint_Name, FK_table_name, FK_column_name, PK_table_name, PK_column_name
					FROM @FKConstraintList

					OPEN Delete_FK_Cursor
					FETCH NEXT FROM Delete_FK_Cursor INTO @ConstraintName, @FK_table, @FK_column, @PK_table, @PK_column

					-- Loop to iterate through foreign keys referencing the table column in the outer loop
					WHILE @@FETCH_STATUS = 0
					BEGIN
						SET @ColumnList1 = NULL
						SET @ColumnList2  = NULL

						SELECT @ColumnList1 = COALESCE(@ColumnList1 + ', ' , '' ) + COL_NAME(parent_object_id, parent_column_id) 
						FROM sys.foreign_key_columns
						WHERE constraint_object_id = OBJECT_ID('' + @ConstraintName + '')
						ORDER BY constraint_column_id

						SELECT @ColumnList2 = COALESCE(@ColumnList2 + ', ' , '' ) +    COL_NAME(referenced_object_id, referenced_column_id)
						FROM sys.foreign_key_columns
						WHERE constraint_object_id = OBJECT_ID('' + @ConstraintName + '')
						ORDER BY constraint_column_id

						IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = @ConstraintName ) 
						BEGIN
							-- Generate command to re-create the foreign key
							SET @SQL =	'ALTER TABLE [dbo].[' + @FK_Table + '] WITH CHECK ADD CONSTRAINT [' + @ConstraintName +
										'] FOREIGN KEY(' + @ColumnList1 + ')' + ' REFERENCES [dbo].[' + @PK_table + '](' + @ColumnList2 + ')'
						
							SET @GetExistsCheck = 'IF EXISTS (SELECT 1 FROM Temp_Constraint_Definitions_upgr WHERE constraint_name = ''' + @ConstraintName + ''')
											BEGIN
												SET @result = 1
											END
											ELSE
											BEGIN
												SET @result = 0
											END'

							EXECUTE sp_executesql @GetExistsCheck, N'@result INT out', @IfExistsCheck out
			
							-- Save foreign key constraint to table if it is not already in the table
							IF @IfExistsCheck = 0
							BEGIN
								-- Save Foreign Key definition in a permanent table
								EXECUTE ('INSERT INTO Temp_Constraint_Definitions_upgr SELECT ''' + @FK_Table  + ''', ''' + @ConstraintName + ''',''' + @SQL + '''')
							END

							-- Drop Foreign key constraint
							IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE constraint_name = @ConstraintName)
							BEGIN
								SET @SQL = 'ALTER TABLE ' +  @FK_table + ' DROP CONSTRAINT ' + @ConstraintName
								EXECUTE sp_executesql @SQL
							END
	
						END
		
						FETCH NEXT FROM Delete_FK_Cursor INTO  @ConstraintName, @FK_table, @FK_column, @PK_table, @PK_column
					END -- End of WHILE-LOOP

					CLOSE Delete_FK_Cursor
					DEALLOCATE Delete_FK_Cursor
				END 

				--------------------------------------- Save Primary Key Definitions Then Drop Primary Keys on Column --------------------------------
	
				-- In order to modify the column definition, the primary (if one exists on the column) must be dropped and recreated after modifying the column
				IF EXISTS (SELECT * FROM sys.indexes i JOIN sys.index_columns ic ON i.object_id = ic.object_id
							AND i.index_id = ic.index_id WHERE OBJECT_NAME(ic.object_id) = @TableName AND COL_NAME(ic.object_id, column_id) = @ColumnName )
				BEGIN
					SELECT @ConstraintName = i.name 
					FROM sys.indexes i JOIN sys.index_columns ic 
					ON i.object_id = ic.object_id
					AND i.index_id = ic.index_id
					WHERE OBJECT_NAME(ic.object_id) = @TableName 
					AND COL_NAME(ic.object_id, column_id) = @ColumnName 

					SET @ColumnList1 = NULL

					SELECT @ColumnList1 =  COALESCE(@ColumnList1 + ', ' , '' ) + COL_NAME(ic.object_id, column_id) 
					FROM sys.indexes i JOIN sys.index_columns ic 
					ON i.object_id = ic.object_id
					AND i.index_id = ic.index_id
					WHERE i.name = @ConstraintName

					SET @SQL = 'ALTER TABLE [' + @TableName + '] WITH CHECK ADD CONSTRAINT [' + @ConstraintName + '] PRIMARY KEY (' + @ColumnList1 + ')'
			
					SET @GetExistsCheck = 'IF EXISTS (SELECT 1 FROM Temp_Constraint_Definitions_upgr WHERE constraint_name = ''' + @ConstraintName + ''')
									BEGIN
										SET @result = 1
									END
									ELSE
									BEGIN
										SET @result = 0
									END'

					EXECUTE sp_executesql @GetExistsCheck, N'@result INT out', @IfExistsCheck out
			
					-- Save Primary Key definition in a permanent table if not already there
					IF @IfExistsCheck = 0
					BEGIN
						SET @CMD = 'INSERT INTO Temp_Constraint_Definitions_upgr
						SELECT ''' + @TableName + ''', ''' + @ConstraintName +  ''', ''' + @SQL + ''''
						EXECUTE (@CMD)	
					END

					--Drop Primary Key
					IF EXISTS (SELECT * FROM sys.indexes WHERE name = @ConstraintName AND is_primary_key = 1)
					BEGIN
						SET @SQL = 'ALTER TABLE ' + @TableName + ' DROP CONSTRAINT ' + @ConstraintName
						EXECUTE sp_executesql @SQL
					END
				END

				--------------------------------------------- Modify Column Definition ---------------------------------------------------
				
				-- The column definition for the column in the current loop iteration is being modified
				IF COL_LENGTH(@TableName, @ColumnName) IS NOT NULL
				BEGIN
					SET @SQL =  'ALTER TABLE [' + @TableName + '] ALTER COLUMN [' + @ColumnName + '] NUMERIC(10,0) '  + @IsNullable
					EXECUTE sp_executesql @SQL
				END
	
				FETCH NEXT FROM AlterColumn_cursor INTO @TableName, @ColumnName, @IsNullable
			END -- End of WHILE-LOOP

			CLOSE AlterColumn_cursor
			DEALLOCATE AlterColumn_cursor

			/* 
			'The FOREIGN KEY definitions have been saved to the following table: Temp_Constraint_Definitions_upgr'
			 'The INDEX definitions have been saved to the following table: Temp_Index_Definition_Upgr'
			*/

			------------------------------------------ MODIFY ListDomain ID Column Definition ----------------------------------------------------

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.columns WHERE table_name = 'ListDomain' AND column_name = 'Id'
						AND numeric_precision = 10 AND numeric_scale = 0)
			BEGIN
				ALTER TABLE ListDomain DROP CONSTRAINT PK_ListDomain 
				ALTER TABLE ListDomain ALTER COLUMN Id NUMERIC(10,0) NOT NULL
				ALTER TABLE ListDomain WITH CHECK ADD CONSTRAINT PK_ListDomain PRIMARY KEY (Id)
			END

			-------------------------------------------- RECREATING INDEXES AND FOREIGN KEYS --------------------------------------------------------

			DECLARE RecreateIndex_Cursor CURSOR FOR
			SELECT index_name, definition FROM Temp_Index_Definition_Upgr
			WHERE COL_LENGTH(table_name, column_name) IS NOT NULL

			OPEN RecreateIndex_Cursor
			FETCH NEXT FROM RecreateIndex_Cursor INTO @IndexName, @SQL

			WHILE @@FETCH_STATUS = 0
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = @IndexName) 
				BEGIN
					EXECUTE sp_executesql @SQL
				END
				FETCH NEXT FROM RecreateIndex_Cursor INTO @IndexName, @SQL		
			END

			CLOSE RecreateIndex_Cursor
			DEALLOCATE RecreateIndex_Cursor

			--------------------------------------------- RECREATE PRIMARY AND FOREIGN KEY CONSTRAINTS ----------------------------------------------------------------

			DECLARE RecreateConstraint_Cursor CURSOR FOR
			SELECT constraint_name, definition 
			FROM Temp_Constraint_Definitions_upgr
			WHERE table_name IN (SELECT name FROM sys.tables)
			ORDER BY constraint_name DESC

			OPEN RecreateConstraint_Cursor
			FETCH NEXT FROM RecreateConstraint_Cursor INTO @ConstraintName, @SQL

			WHILE @@FETCH_STATUS = 0
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE WHERE constraint_name = @ConstraintName) 
				BEGIN
					EXECUTE sp_executesql @SQL
				END

				FETCH NEXT FROM RecreateConstraint_Cursor INTO @ConstraintName, @SQL
			END
			CLOSE RecreateConstraint_Cursor
			DEALLOCATE RecreateConstraint_Cursor

			SET @SQL = NULL

			SELECT @SQL = COALESCE(@SQL + CHAR(10), '') + 'DROP TABLE ' + name
			FROM sys.tables WHERE name LIKE '%[_]upgr'

			EXECUTE (@SQL)

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 3, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	PRINT CHAR(10) + 'Suspected Failed SQL Statement: ' + CHAR(10) + CHAR(10) + @SQL + CHAR(10)
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


--4_Create_VirtualTableListDomainTables.sql
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640205 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 3
		BEGIN
			/*
			This script takes the ListDomain data for virtual tables and seperates them
			into various ListDomain tables with names prefixed by 'LD_'. 

			This script also creates or deletes and recreates the TempListdomainTable table. This script must be executed
			on the target database
			*/

			DECLARE @NewTableName NVARCHAR(100)
			DECLARE @VirtualColumnId INT
			DECLARE @VirtualTableId INT
			DECLARE @VirtualTableName NVARCHAR(100)
			DECLARE @VirtualColumnName NVARCHAR(100)
			DECLARE @SQL NVARCHAR(MAX)
			DECLARE @Count INT
			DECLARE @DomainCatalogId INT
			DECLARE @flag INT
			DECLARE @ErrorMessage NVARCHAR(MAX)
			DECLARE @NewLine NVARCHAR(100) = CHAR(10) + CHAR(9) + CHAR(9) + CHAR(9) + CHAR(9);

			---------------------------------- Create/Define Temporary tables ---------------------------------
			
			-- Check to make sure that the VirtualTableDataListDomain table exists
			IF OBJECT_ID('VirtualTableDataListDomain', 'U') IS NULL
			BEGIN
				RAISERROR('The VirtualTableDataListDomain table is missing ', 11, 0)
			END

			IF OBJECT_ID ('tmp_NewDomainTableList_VT', 'u') IS NOT NULL
			BEGIN
				DROP TABLE tmp_NewDomainTableList_VT
			END

			-- Create a table to store info on all LD tables being created for virtual table columns
			IF OBJECT_ID ('tmp_NewDomainTableList_VT', 'U') IS NULL
			BEGIN

				CREATE TABLE tmp_NewDomainTableList_VT (VirtualColumnId INT,
													VirtualColumnName NVARCHAR(100),
													VirtualTableId INT,
													VirtualTableName NVARCHAR(100),
													LDTableName NVARCHAR(100),
													DomainCatalogId INT,
													DomainDescr VARCHAR(100),
													VirtualColumnComment VARCHAR(MAX),
													VirtualTableComment VARCHAR(MAX))

				INSERT INTO tmp_NewDomainTableList_VT
				SELECT DISTINCT vc.Id AS VirtualColumnId,
								REPLACE(vc.VirtualColumnName, CHAR(32), ''),
								vt.Id AS VirtualTableId,
								REPLACE(vt.VirtualTableName, CHAR(32), ''),
								'LD_' + VirtualColumnname,
								dcxr.DomainCatalogId,
								DomainDescr = dc.DomainDescr,
								vt.VirtualTableComment,
								vc.VirtualColumnComment
				FROM VirtualColumn vc 
				JOIN VirtualTable vt
					ON vc.VirtualTableId = vt.Id
				LEFT JOIN DomainCatalogColXRef dcxr
					ON dcxr.TableName = vt.VirtualTableName
					AND dcxr.ColumnName = vc.VirtualColumnName
				LEFT JOIN DomainCatalog dc ON dc.Id = dcxr.DomainCatalogId
				WHERE VirtualColumnDataTypeInd = 'L'
				AND vc.VirtualColumnComment <> 'DO NOT USE'
				
			END

			-- Add missing DomainDescr and DomainCatalogId to virtual table entries in tmp_NewDomainTableList_VT table that have a ListDomain entry  
			UPDATE tmp_NewDomainTableList_VT
			SET DomainCatalogId = ld.Id,
				DomainDescr = dc.DomainDescr
			FROM tmp_NewDomainTableList_VT nvt
			LEFT JOIN VirtualTableDataListDomain vtld 
				ON vtld.VirtualTableId = nvt.VirtualTableId
				AND vtld.VirtualColumnId = nvt.VirtualColumnId
			LEFT JOIN ListDomain ld ON ld.Id = vtld.DataFieldValueDomainId
			LEFT JOIN DomainCatalog dc ON dc.Id = ld.DomainCatalogId
			WHERE nvt.DomainDescr IS NULL

			-- Add the LD table names from DRASSQL2019.DrasInternal.dbo.ListDomainTableInfo to tmp_NewDomainTableList_VT table
			UPDATE tmp_NewDomainTableList_VT
			SET LDTableName = CASE WHEN ld.LDTableName LIKE '%[0-9]%' OR ld.LDTableName IS NULL
					THEN (CASE	
							WHEN LEN('LD_' + nld.VirtualColumnName) > 30
								THEN REPLACE(REPLACE('LD_' + nld.VirtualColumnName
											, 'Remediation', 'Remed'), 'Reinforcement', 'Reinforce')
							ELSE 'LD_' + nld.VirtualColumnName
						  END)
					ELSE ld.LDTableName
				END Collate SQL_Latin1_General_CP1_CI_AS
			FROM tmp_NewDomainTableList_VT nld
			LEFT JOIN DRASSQL2019.DrasInternal.dbo.ListDomainTableInfo ld
			ON nld.DomainDescr = ld.DomainDescr collate SQL_Latin1_General_CP1_CI_AS
			
			------------- Create copies the ListDomain and VirtualTableDataListDomain tables ---------------

			IF OBJECT_ID('Temp_ListDomain') IS NOT NULL
			BEGIN
				DROP TABLE Temp_ListDomain
			END

			-- Create a copy of the ListDomain tables and add an extra column to store the LD table names
			SET @SQL = 'SELECT ld.Id AS Old_Id, 
					CAST(NULL AS INT) AS New_Id,
					ld.DomainCatalogId, 
					dc.DomainDescr, 
					ld.Code, 
					ld.Descr, 
					CAST(NULL AS NVARCHAR(100)) LDTableName,
					ld.SourceDomainId, 
					ld.LastModByUserId, 
					ld.LastModDateTime
			INTO Temp_ListDomain
			FROM ListDomain ld
			LEFT JOIN DomainCatalog dc
				ON dc.Id = ld.DomainCatalogId'

			EXECUTE (@SQL)

			IF OBJECT_ID('Temp_VirtualTableDataListDomain', 'U') IS NOT NULL
			BEGIN
				DROP TABLE Temp_VirtualTableDataListDomain
			END


			-- Create a copy of the VirtualTableDataListDomain tables and add extra columns to store ListDomain data
			SET @SQL = 'SELECT vtld.VirtualColumnId,
					nld.VirtualColumnName,
					vtld.VirtualTableId,
					nld.VirtualTableName,
					vtld.VirtualTableStationingId,
					vtld.DataFieldValueDomainId Old_DataFieldValueDomainId,
					CAST(NULL AS INT) New_DataFieldValueDomainId,
					ld.code,
					ld.Descr,
					CASE WHEN dcxr.DomainCatalogId IS NOT NULL THEN dcxr.DomainCatalogId ELSE ld.DomainCatalogId END AS DomainCatalogId,
					CASE WHEN dcxr.DomainCatalogId IS NOT NULL THEN (SELECT DomainDescr FROM DomainCatalog WHERE Id = dcxr.DomainCatalogId) 
						 ELSE (SELECT DomainDescr FROM DomainCatalog WHERE Id = ld.DomainCatalogId) 
					END AS DomainDescr, 
					nld.LDTableName,
					nld.VirtualTableComment,
					nld.VirtualColumnComment,
					vtld.SourceId, 
					vtld.LastModByUserId, 
					vtld.LastModDateTime,
					vtld.CreatedDate,
					vtld.CreatedUser
			INTO Temp_VirtualTableDataListDomain 
			FROM VirtualTableDataListDomain vtld
			JOIN ListDomain ld
				ON vtld.DataFieldValueDomainId = ld.Id
			JOIN tmp_NewDomainTableList_VT nld
				ON nld.VirtualTableId = vtld.VirtualTableId
				AND nld.VirtualColumnId = vtld.VirtualColumnId
			LEFT JOIN DomainCatalogcolXRef dcxr 
				ON dcxr.TableName = nld.VirtualTableName
				AND dcxr.ColumnName = nld.VirtualColumnName'

			EXECUTE (@SQL)

			-- Add the LD table names in the ListDomain table
			SET @SQL = 'UPDATE Temp_ListDomain
			SET LDTableName = vtld.LDTableName
			FROM Temp_ListDomain ld
			LEFT JOIN Temp_VirtualTableDataListDomain vtld
				 ON vtld.Old_DataFieldValueDomainId = ld.Old_Id'

			EXECUTE (@SQL)

			-- Ensure that the DomainCatalogId and DomainDescr in Temp_ListDomain table matches DomainCatalogColXRef table
			UPDATE Temp_ListDomain
			SET DomainCatalogId = dcxr.DomainCatalogId,
				DomainDescr = dc.DomainDescr
			FROM Temp_VirtualTableDataListDomain vtld
			JOIN Temp_ListDomain ld ON ld.Old_Id = vtld.Old_DataFieldValueDomainId
			JOIN DomainCatalogColXRef dcxr ON dcxr.TableName = vtld.VirtualTableName
			AND dcxr.ColumnName = vtld.VirtualColumnName
			JOIN DomainCatalog dc ON dc.Id = dcxr.DomainCatalogId
			WHERE dcxr.DomainCatalogId <> ld.DomainCatalogId

			-- Ensure that the DomainCatalogId in Temp_ListDomain table matches DomainCatalogColXRef table
			UPDATE tmp_NewDomainTableList_VT
			SET DomainCatalogId = dc.Id,
				DomainDescr = dc.DomainDescr
			FROM tmp_NewDomainTableList_VT nld
			JOIN DomainCatalog dc ON dc.DomainDescr = nld.DomainDescr
			WHERE nld.DomainCatalogId <> dc.Id OR nld.DomainDescr <> dc.DomainDescr

			------------------------------- CREATE AND/OR UPDATE the TempListDomainTable table ------------------------

			-- Create a temporary table to store list domain info for all LD tables
			IF OBJECT_ID('dbo.TempListDomainTable') IS NOT NULL
			BEGIN
				DROP TABLE dbo.TempListDomainTable
			END

			IF OBJECT_ID('dbo.TempListDomainTable') IS NULL
			BEGIN
				CREATE TABLE TempListDomainTable (Id INT IDENTITY(1,1),
												  TableType VARCHAR(20),
												  LDTableSchema NVARCHAR(100),
												  LDTableName VARCHAR(100),
												  TableSchema VARCHAR(100),
												  TableName VARCHAR(100),
												  ColumnName VARCHAR(100),
												  DomainCatalogId INT,
												  DomainDescr VARCHAR(100),
												  HasData VARCHAR(3),
												  ListDomainDataCountMatches VARCHAR(3),
												  CreatedUser VARCHAR(45) DEFAULT (SUSER_SNAME()) NOT NULL,
												  CreatedDate DATETIME DEFAULT (GETDATE()) NOT NULL,
												  LastModByUserId VARCHAR(45) DEFAULT (SUSER_SNAME()) NOT NULL,
												  LastModDateTime DATETIME DEFAULT (GETDATE()) NOT NULL)
			END

			SET @SQL = 'CREATE TRIGGER [dbo].[tu_TempListDomainTable] ON [dbo].[TempListDomainTable] FOR UPDATE AS 
			IF EXISTS(SELECT * FROM DELETED)
			BEGIN
				UPDATE dbo.TempListDomainTable
				SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
				FROM dbo.TempListDomainTable as t, DELETED as d
				WHERE t.Id=d.Id;
			END'

			EXECUTE (@SQL)
			
			-- Store the info for each LD table in the TempListDomainTable table
			INSERT INTO dbo.TempListDomainTable (TableType, 
										LDTableName, 
										TableName, 
										ColumnName, 
										DomainCatalogId, 
										DomainDescr)
				  SELECT DISTINCT 'Virtual',
							nld.LDTableName,
							nld.VirtualTableName,
							nld.VirtualColumnName,
							nld.DomainCatalogId,
							nld.DomainDescr
					FROM tmp_NewDomainTableList_VT nld
					LEFT JOIN TempListDomainTable tld
						ON nld.VirtualColumnName = tld.ColumnName
						AND nld.VirtualTableName = tld.TableName
					WHERE tld.ColumnName IS NULL

			/*
				Check that all LD tables except the ones referenced by Field_#_DomainId column of IRASCustom 
				tables have a DomainDescr and DomainCatalogId
			*/

			SELECT @flag = COUNT(*) FROM tmp_NewDomainTableList_VT 
			WHERE (DomainDescr IS NULL OR DomainCatalogId IS NULL)
			AND VirtualTableName NOT LIKE 'IRASCustom%'

			IF @flag <> 0
			BEGIN
				SELECT LDTableName, 
						VirtualTableName, 
						VirtualColumnName, 
						DomainCatalogId, 
						DomainDescr
				FROM tmp_NewDomainTableList_VT 
				WHERE (DomainDescr IS NULL OR DomainCatalogId IS NULL)
				AND VirtualTableName NOT LIKE 'IRASCustom%'

				SET @SQL = NULL

				SET @ErrorMessage = 'The Virtual tables listed in the Results tab are MISSING A DOMAIN CATALOG REFERENCE.'
				+ CHAR(10) + 'To resolve the issue, add and/or modify entries in the DomainCatalog and/or DomainCatalogColXRef '
				+ CHAR(10) + 'tables for the listed table-columns' + CHAR(10);

				THROW 51001, @ErrorMessage, 1
			END

			------------------------- Check that each LD table has a unique Domain ----------

			SET @SQL = 'IF OBJECT_ID(''CheckVirtualTableData'') IS NOT NULL
			BEGIN
				DROP TABLE CheckVirtualTableData;
			END

			SELECT DISTINCT ld.Old_Id ListDomainId, vtld.VirtualTableName, vtld.VirtualColumnname, 
					ld.DomainCatalogId ListDomain_DomainCatalogId, ld.Domaindescr ListDomain_DomainDescr,
					vtld.DomainCatalogId VListDomain_DomainCatalogId, vtld.DomainDescr VirtualTableDataListDomain_DomainDescr
			INTO CheckVirtualTableData
			FROM Temp_VirtualTableDataListDomain vtld
			JOIN Temp_Listdomain ld ON vtld.Old_DataFieldValueDomainId = ld.Old_id 

			SELECT @flag = COUNT(*) from CheckVirtualTableData tab1 WHERE EXISTS (SELECT VirtualTableName, VirtualColumnName, COUNT(DISTINCT ListDomain_DomainCatalogId)
													FROM CheckVirtualTableData tab2 WHERE ListDomain_DomainCatalogId <> -1
													AND tab1.VirtualTableName = tab2.VirtualTableName AND tab1.VirtualColumnName = tab2.VirtualColumnName
											 		GROUP BY VirtualTableName, VirtualColumnName HAVING COUNT(DISTINCT ListDomain_DomainCatalogId) > 1)
				OR
				EXISTS (SELECT ListDomainId, COUNT(DISTINCT ListDomain_DomainCatalogId), COUNT(DISTINCT VListDomain_DomainCatalogId)
													FROM CheckVirtualTableData tab2 WHERE ListDomain_DomainCatalogId <> -1
													AND tab1.ListDomainId = tab2.ListDomainId
													GROUP BY ListDomainId HAVING COUNT(DISTINCT ListDomain_DomainCatalogId) > 1 
													OR COUNT(DISTINCT VListDomain_DomainCatalogId) > 1)'

			EXECUTE sp_executesql @SQL, N'@flag INT OUTPUT', @flag OUTPUT	

			IF @Flag <> 0
			BEGIN
				SET @SQL = '	SELECT DISTINCT ListDomainId, VirtualTableName, VirtualColumnName,
				CASE WHEN EXISTS (SELECT VirtualTableName, VirtualColumnName, COUNT(DISTINCT ListDomain_DomainCatalogId)
													FROM CheckVirtualTableData tab2 WHERE ListDomain_DomainCatalogId <> -1
													AND tab1.VirtualTableName = tab2.VirtualTableName AND tab1.VirtualColumnName = tab2.VirtualColumnName
													GROUP BY VirtualTableName, VirtualColumnName HAVING COUNT(DISTINCT ListDomain_DomainCatalogId) > 1)
								THEN ListDomain_DomainCatalogId 
							ELSE VListDomain_DomainCatalogId
				END AS DomainCatalogId,
				CASE WHEN EXISTS (SELECT VirtualTableName, VirtualColumnName, COUNT(DISTINCT ListDomain_DomainCatalogId)
													FROM CheckVirtualTableData tab2 WHERE ListDomain_DomainCatalogId <> -1
													AND tab1.VirtualTableName = tab2.VirtualTableName AND tab1.VirtualColumnName = tab2.VirtualColumnName
													GROUP BY VirtualTableName, VirtualColumnName HAVING COUNT(DISTINCT ListDomain_DomainCatalogId) > 1)
								THEN ListDomain_DomainDescr
							ELSE VirtualTableDataListDomain_DomainDescr
				END AS DomainDescr
				FROM CheckVirtualTableData tab1 WHERE EXISTS (SELECT VirtualTableName, VirtualColumnName, COUNT(DISTINCT ListDomain_DomainCatalogId)
													FROM CheckVirtualTableData tab2 WHERE ListDomain_DomainCatalogId <> -1
													AND tab1.VirtualTableName = tab2.VirtualTableName AND tab1.VirtualColumnName = tab2.VirtualColumnName
													GROUP BY VirtualTableName, VirtualColumnName HAVING COUNT(DISTINCT ListDomain_DomainCatalogId) > 1)
				OR
				EXISTS (SELECT ListDomainId, COUNT(DISTINCT ListDomain_DomainCatalogId), COUNT(DISTINCT VListDomain_DomainCatalogId)
													FROM CheckVirtualTableData tab2 WHERE ListDomain_DomainCatalogId <> -1
													AND tab1.ListDomainId = tab2.ListDomainId
													GROUP BY ListDomainId HAVING COUNT(DISTINCT ListDomain_DomainCatalogId) > 1 OR COUNT(DISTINCT VListDomain_DomainCatalogId) > 1)
				ORDER BY VirtualTableName, ListDomainId';

				EXECUTE (@SQL)

				SET @SQL = NULL

				SET @ErrorMessage = N'There are conflicting DomainCatalogIds for the virtual table columns and/or Listdomain Ids listed in the Results tab ' + CHAR(10)  
				+ 'To resolve the issue, add or modify entries in the DomainCatalogColXRef table for the virtual table columns listed in the Results tab' + CHAR(10);
		
				THROW 51001, @ErrorMessage, 1

			END

		/**************************************************************************************************
											VALIDATE LISTDOMAIN DATA
		**********************************************************************************************/

			DECLARE tmp_NewDomainTableList CURSOR FOR
			SELECT VirtualColumnId, 
				   VirtualColumnName, 
				   VirtualTableId, 
				   VirtualTableName, 
				   LDTableName, 
				   DomainCatalogId
			FROM tmp_NewDomainTableList_VT
	
			OPEN tmp_NewDomainTableList
			FETCH FROM tmp_NewDomainTableList INTO @VirtualColumnId, @VirtualColumnName, @VirtualTableId, @VirtualTableName, @NewTableName, @DomainCatalogId

			WHILE @@FETCH_STATUS = 0
			BEGIN
				
				SET @DomainCatalogId = NULL

				SELECT @DomainCatalogId = DomainCatalogId 
				FROM DomainCatalogColXRef 
				WHERE TableName = @VirtualTableName 
				AND ColumnName =  @VirtualColumnName 

				IF (@DomainCatalogId IS NULL) AND (SELECT COUNT(DISTINCT DomainCatalogId) FROM ListDomain 
						WHERE Id IN (SELECT DataFieldValueDomainId FROM VirtualTableDataListDomain
										WHERE VirtualTableId = @VirtualTableId
										AND VirtualColumnId = @VirtualColumnId
										) 
						) = 1
				BEGIN
					SELECT TOP 1 @DomainCatalogId = DomainCatalogId FROM ListDomain
					WHERE Id IN (SELECT DataFieldValueDomainId FROM VirtualTableDataListDomain
									WHERE VirtualTableId = @VirtualTableId
									AND VirtualColumnId = @VirtualColumnId
									) 

				END
				ELSE IF (SELECT COUNT(DISTINCT @DomainCatalogId) FROM ListDomain 
						WHERE Id IN (SELECT DataFieldValueDomainId FROM VirtualTableDataListDomain
										WHERE VirtualTableId = @VirtualTableId
										AND VirtualColumnId = @VirtualColumnId
										) 
						) > 1
				BEGIN 
		
					SET @SQL = ''

					RAISERROR('There are more than 1 domain categories for virtual table ----> ''%s'' and virtual column %s.%sOnly 1 domain category can be assigned for each table and column combination for this script to continue', 11, 0, 
					@VirtualTableName, @VirtualColumnName, @NewLine)

				END

			--------------------------------------- CREATE THE NEW LIST DOMAIN TABLES ----------------------------------
	
				IF OBJECT_ID( @NewTableName) IS NULL
				BEGIN
					SET @SQL = 'CREATE TABLE [' + @NewTableName + '](
								[Id] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
								[Code] [varchar](60) NOT NULL,
								[Descr] [varchar](255) NOT NULL,
								[EffectiveEndDate] [Datetime] DEFAULT NULL,
								[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
								[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
								[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
								[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL
								)';

					EXECUTE (@SQL);

				END;

				--Recreate update trigger on LD tableS
				SET @SQL = 'IF NOT EXISTS (SELECT * FROM sys.triggers WHERE name = ''tu_' + @NewTableName + ''')
				BEGIN
					EXECUTE(''CREATE TRIGGER [dbo].[tu_' + @NewTableName + '] ON [dbo].[' + @NewTableName + '] FOR UPDATE AS 
					IF EXISTS(SELECT * FROM DELETED)
					BEGIN
						UPDATE dbo.' + @NewTableName + '
						SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
						FROM dbo.' + @NewTableName + ' as t, DELETED as d
						WHERE t.Id=d.Id;
					END'')
				END'

				EXECUTE (@SQL)

			---------------------------- Populate the LD tables with Virtual table data ----------------------------------------
				
				-- Populate LD tables with virtual table ListDomain data from the VirtualTableDataListDomain table
				SET @SQL = 'SET IDENTITY_INSERT ' + @NewTableName + ' ON;
				WITH CTE AS 
				(SELECT DISTINCT ld.Old_Id AS Id, 
								 LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(ld.Code, CHAR(10), '' ''), CHAR(9), '' ''), CHAR(13), '' '')))  AS Code,
								 LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(ld.Descr, CHAR(10), '' ''), CHAR(9), '' ''), CHAR(13), '' '')))  AS Descr
				 FROM Temp_ListDomain ld
				 WHERE ld.LDTableName = ''' + @NewTableName + '''
				)
				INSERT INTO ' + @NewTableName  + ' (Id, Code, Descr, EffectiveEndDate)
				SELECT Id, 
					   Code, 
					   Descr,
					   NULL
				FROM CTE
				WHERE NOT EXISTS (SELECT * FROM ' + @NewTableName  + ' nt2 
									WHERE cte.Id = nt2.Id)
				  
				SET IDENTITY_INSERT ' + @NewTableName + ' OFF'

				EXECUTE (@SQL)
				
				--------------------------- Track Data in LD tables ----------------------------------

				-- Check if the LD table has data and if the data matches what's in the ListDomain table
				SET  @SQL = 'UPDATE TempListDomainTable
							SET ListDomainDataCountMatches = (SELECT CASE WHEN COUNT(*) = 0 THEN ''YES''
																		ELSE ''NO''
																	 END	
																FROM Temp_ListDomain ld
																	WHERE NOT EXISTS (SELECT * FROM ' + @NewTableName + ' nt
																					  WHERE nt.Id = ld.Old_Id)
																	AND LDTableName = '''+ @NewTableName +'''
															  ),
								 HasData = (SELECT CASE WHEN COUNT(*) > 0 THEN ''YES''
														ELSE ''NO''
													END
											FROM ' + @NewTableName + ')
							FROM TempListDomainTable tld
							LEFT JOIN Temp_VirtualTableDataListDomain vtld
							ON vtld.VirtualTableName = tld.TableName
							AND vtld.VirtualColumnName = tld.ColumnName
							WHERE tld.LDTableName = ''' + @NewTableName + ''''

				EXECUTE (@SQL)	

		
				FETCH FROM tmp_NewDomainTableList INTO @VirtualColumnId, @VirtualColumnName, @VirtualTableId, @VirtualTableName, @NewTableName, @DomainCatalogId
			END

			CLOSE tmp_NewDomainTableList
			DEALLOCATE tmp_NewDomainTableList

			/***********************************************************************************************
												 Sanity Check 
			***********************************************************************************************/
		
			/*
				Check that the LDTableName and DomainCatalogId are conistent in
				Temp_VirtualTableDataListDomain, Temp_ListDomain and TempListDomainTable tables
			*/

			SELECT  @flag = COUNT(*)
			FROM Temp_VirtualTableDataListDomain vtld
			JOIN Temp_ListDomain ld
			ON ld.Old_Id = vtld.Old_DataFieldValueDomainId
			JOIN TempListDomainTable tmp
			ON vtld.VirtualTableName = tmp.TableName
			AND vtld.VirtualColumnName = tmp.ColumnName
			WHERE ld.New_Id <> vtld.New_DataFieldValueDomainId OR
				vtld.LDTableName <> ld.LDTableName OR vtld.LDTableName <> tmp.LDTableName
				OR ld.LDTableName <> tmp.LDTableName OR vtld.LDTableName IS NULL
				OR ld.LDTableName IS NULL OR tmp.LDTableName IS NULL
				OR vtld.DomainDescr <> ld.DomainDescr OR vtld.Domaindescr <> tmp.DomainDescr
				OR ld.DomainDescr <> tmp.DomainDescr 
				OR (vtld.DomainDescr IS NULL OR ld.DomainDescr IS NULL OR tmp.DomainDescr IS NULL AND TableName NOT LIKE 'IRASCustom%')
				OR vtld.DomainCatalogId <> ld.DomainCatalogId OR vtld.DomainCatalogId <> tmp.DomainCatalogId
				OR ld.DomainCatalogId <> tmp.DomainCatalogId 
				OR (vtld.DomainCatalogId IS NULL OR ld.DomainCatalogId IS NULL OR tmp.DomainCatalogId IS NULL AND TableName NOT LIKE 'IRASCustom%')
				 

			EXECUTE sp_executesql @SQL, N'@flag INT OUTPUT', @flag OUTPUT

			IF @Flag <> 0
			BEGIN

				SELECT DISTINCT VirtualTableName
						,VirtualColumnName
						,vtld.Old_DataFieldValueDomainId
						,ld.Old_Id
				FROM Temp_VirtualTableDataListDomain vtld
				JOIN Temp_ListDomain ld
				ON ld.Old_Id = vtld.Old_DataFieldValueDomainId
				JOIN TempListDomainTable tmp
				ON vtld.VirtualTableName = tmp.TableName
				AND vtld.VirtualColumnName = tmp.ColumnName
				WHERE ld.New_Id <> vtld.New_DataFieldValueDomainId 

				SELECT DISTINCT VirtualTableName
						,VirtualColumnName
						,vtld.LDTableName VirtualTableDataListDomain_LDTableName
						,ld.LDTableName ListDomain_LDTableName
						,tmp.LDTableName TempListDomainTable_LDTableName
				FROM Temp_VirtualTableDataListDomain vtld
				JOIN Temp_ListDomain ld
				ON ld.Old_Id = vtld.Old_DataFieldValueDomainId
				JOIN TempListDomainTable tmp
				ON vtld.VirtualTableName = tmp.TableName
				AND vtld.VirtualColumnName = tmp.ColumnName
				WHERE vtld.LDTableName <> ld.LDTableName OR vtld.LDTableName <> tmp.LDTableName
					OR ld.LDTableName <> tmp.LDTableName OR vtld.LDTableName IS NULL
					OR ld.LDTableName IS NULL OR tmp.LDTableName IS NULL

				SELECT DISTINCT VirtualTableName
						,VirtualColumnName
						,vtld.DomainDescr VirtualTableDataListDomain_DomainDescr
						,ld.DomainDescr ListDomain_DomainDescr
						,tmp.DomainDescr TempListDomainTable_DomainDescr
				FROM Temp_VirtualTableDataListDomain vtld
				JOIN Temp_ListDomain ld
				ON ld.Old_Id = vtld.Old_DataFieldValueDomainId
				JOIN TempListDomainTable tmp
				ON vtld.VirtualTableName = tmp.TableName
				AND vtld.VirtualColumnName = tmp.ColumnName
				WHERE vtld.DomainDescr <> ld.DomainDescr OR vtld.Domaindescr <> tmp.DomainDescr
					OR ld.DomainDescr <> tmp.DomainDescr 
					OR (vtld.DomainDescr IS NULL OR ld.DomainDescr IS NULL OR tmp.DomainDescr IS NULL AND TableName NOT LIKE 'IRASCustom%')
					
				SELECT DISTINCT VirtualTableName
						,VirtualColumnName
						,vtld.DomainCatalogId VirtualTableDataListDomain_DomainCatalogId
						,ld.DomainCatalogId ListDomain_DomainCatalogId
						,tmp.DomainCatalogId TempListDomainTable_DomainCatalogId
				FROM Temp_VirtualTableDataListDomain vtld
				JOIN Temp_ListDomain ld
				ON ld.Old_Id = vtld.Old_DataFieldValueDomainId
				JOIN TempListDomainTable tmp
				ON vtld.VirtualTableName = tmp.TableName
				AND vtld.VirtualColumnName = tmp.ColumnName
				WHERE vtld.DomainCatalogId <> ld.DomainCatalogId OR vtld.DomainCatalogId <> tmp.DomainCatalogId
					OR ld.DomainCatalogId <> tmp.DomainCatalogId 
					OR (vtld.DomainCatalogId IS NULL OR ld.DomainCatalogId IS NULL 
					OR tmp.DomainCatalogId IS NULL AND TableName NOT LIKE 'IRASCustom%');			 

				EXECUTE (@SQL)

				SET @SQL = NULL

				SET @ErrorMessage = N'The DomainDescr, DomainCatalogId, and/or LD table names are not consistent in the Temp_VirtualTableDataListDomain, Temp_ListDomain and TempListDomainTable tables' + CHAR(10);
		
				THROW 51001, @ErrorMessage, 1

			END

			----------------------------- Check Data Count in LD tables -----------------------------------------

			SET @SQL = 'SELECT @flag = COUNT(*) FROM TempListDomainTable WHERE ListDomainDataCountMatches = ''NO'''

			EXECUTE sp_executesql @SQL, N'@flag INT OUTPUT', @flag OUTPUT

			IF @Flag <> 0
			BEGIN
				SET @SQL = 'SELECT * FROM TempListDomainTable WHERE ListDomainDataCountMatches = ''NO''';

				EXECUTE (@SQL)

				SET @SQL = NULL

				SET @ErrorMessage = N'The data in the LD tables listed in the Results tab do not match the corresponding data ' +
				CHAR(10) + 'in the ListDomain table for its specific domain catalog group ' + CHAR(10);
		
				THROW 51001, @ErrorMessage, 1

			END

			--------------------- DROP FK on VirtualTableDataListDomain referencing ListDomain table -------------------------------

			-- Drop foreign key on VirtualTableDataListDomain table
			SELECT @SQL = 'ALTER TABLE dbo.VirtualTableDataListDomain DROP CONSTRAINT ' +  name
							FROM sys.foreign_keys
							WHERE OBJECT_NAME(referenced_object_id) = 'ListDomain'
							AND OBJECT_NAME(parent_object_id) = 'VirtualTableDataListDomain'

			EXECUTE sp_executesql @SQL
	
			IF OBJECT_ID('tmp_NewDomainTableList_VT') IS NOT NULL
			BEGIN
				DROP TABLE tmp_NewDomainTableList_VT
			END

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 4, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	PRINT CHAR(10) + 'Suspected Failed SQL Statement: ' + CHAR(10) + CHAR(10) + @SQL + CHAR(10)
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

--5_Create_NewListDomainTables.sql
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640205 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 4
		BEGIN
			/*

			This script takes the ListDomain data for all tables referencing the ListDomain table and seperates them
			into new tables prefixed with 'GLD_' for shared data or 'LD_' for non-shared data. 

			This script also 
			1) Takes the ListDomain data in the Category and CategoryDataListDomainXRef tables, breaks it up into smaller tables 
			with names prefixed by 'LD_', then drops the Category and CategoryDataListDomainXRef tables. 
			2) Modifies the ActionItemPropDCXRef table by adding columns referencing the newly created LisDomain tables.
			3) Drops the ListDomain, DomainCatalog, and DomainCatalogColXRef tables

			This script must be executed on the target database

			*/
			DECLARE @FKConstraintName NVARCHAR(100);
			DECLARE @NewTableName NVARCHAR(100);
			DECLARE @TableName NVARCHAR(100);
			DECLARE @ColumnName NVARCHAR(100);
			DECLARE @SQL NVARCHAR(MAX);
			DECLARE @StageDB NVARCHAR(100);
			DECLARE @ConfigDB NVARCHAR(100);
			DECLARE @Count INT
			DECLARE @DomainCatalogId INT;
			DECLARE @ListDomainId INT
			DECLARE @CategoryId INT;
			DECLARE @DomainDescr NVARCHAR(200);
			DECLARE @ErrorMessage NVARCHAR(MAX)
			DECLARE @ForeignKeyCount INT 
			DECLARE @flag INT
			DECLARE @NewLine NVARCHAR(100) = CHAR(10) + CHAR(9) + CHAR(9) + CHAR(9) + CHAR(9);

			--------------------------- Create Tables for Processing data -----------------------------

			-- Check that Listdomain, DomainCatalog and DomainCatalogColXRef tables exists
			IF (SELECT COUNT(*) FROM sys.tables WHERE name IN ('ListDomain', 'DomainCatalog', 'DomainCatalogColXRef')) <>  3
			BEGIN
				RAISERROR('The DomainCatalog, DomainCatalog, and or DomainCatalogColXRef tables are missing ', 11, 0)
			END

			IF OBJECT_ID('tmp_ListDomainInfo' ) IS NOT NULL
			BEGIN
				DROP TABLE tmp_ListDomainInfo
			END

			IF OBJECT_ID('tmp_ListDomainInfo' ) IS NULL
			BEGIN
				CREATE TABLE tmp_ListDomainInfo ( Id INT, 
												DomainCatalogId INT,
												DomainDescr NVARCHAR(100),
												Code NVARCHAR(60),  
												Descr NVARCHAR(255));

			END
			
			IF OBJECT_ID('tmp_NewDomainTableList') IS NOT NULL
			BEGIN
				DROP TABLE tmp_NewDomainTableList;

			END;

			/*
				Generates a list of all child tables with a foreign key constraint referencing the 
				ListDomain table and store the results in a temporary table
			*/

			IF OBJECT_ID ('tmp_NewDomainTableList' ) IS NULL 
			BEGIN
				CREATE TABLE tmp_NewDomainTableList (Id INT IDENTITY(1,1),
												FKConstraint NVARCHAR(100),
												TableName NVARCHAR(100),
												ColumnName NVARCHAR(100),
												LDTableName NVARCHAR(100),
												DomainCatalogId INT,
												DomainDescr NVARCHAR(MAX),
												flag BIT
												);
			END

			-- Generate list of LD tables that will be created (Only tables with foreign key referencing ListDomain table)
			INSERT INTO tmp_NewDomainTableList (FKConstraint, TableName, ColumnName)
			SELECT OBJECT_NAME(fkc.constraint_object_id),
					OBJECT_NAME(fkc.parent_object_id) AS fk_table,
					COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS fk_column
			FROM sys.foreign_key_columns fkc
			JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
				ON kcu.constraint_name = OBJECT_NAME(fkc.constraint_object_id)
				AND kcu.column_name = COL_NAME(fkc.parent_object_id, fkc.parent_column_id)
			JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
			JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id
			WHERE OBJECT_NAME(fkc.referenced_object_id) LIKE 'ListDomain'
			AND OBJECT_NAME(fkc.parent_object_id) NOT IN ('RememberedListDomainValues', 'VirtualTableDataListDomain', 'ActionItemPropDCXRef', 'CategoryDataListDomainXRef')


			-- Get the DomainCatalogId from the DomainCatalogColXRef table
			UPDATE tmp_NewDomainTableList
			SET DomainCatalogId = dcxr.DomainCatalogId,
				DomainDescr = dc.DomainDescr
			FROM tmp_NewDomainTableList nld
			JOIN DomainCatalogColXRef dcxr
			ON nld.TableName = dcxr.TableName
			AND nld.ColumnName = dcxr.ColumnName
			JOIN DomainCatalog dc ON dc.Id = dcxr.DomainCatalogId
									
			-- Add missing LD table names to the copy of ListDomain table
			SET @SQL = 'UPDATE Temp_ListDomain
			SET LDTableName = ldti.LDTableName
			FROM Temp_ListDomain tmp
			JOIN DRASSQL2019.DrasInternal.dbo.ListDomainTableInfo ldti
				ON ldti.DomainDescr = tmp.DomainDescr collate SQL_Latin1_General_CP1_CI_AS
			WHERE tmp.LDTableName is NULL'

			EXECUTE (@SQL)

			---------------------------- Tables that are included as exceptions ----------------------------

			-- Tables that are missing a foreign key reference to the ListDomain table
			INSERT INTO tmp_NewDomainTableList (FKConstraint, TableName, ColumnName)
			VALUES ('FK_POECompLookup_MetalLossTypeDomain', 'POECompanyLookUp', 'MetalLossTypeDomainId')

			INSERT INTO tmp_NewDomainTableList (FKConstraint, TableName, ColumnName)
			VALUES ('FK_POECompLookup_ToolTypeDomain', 'POECompanyLookUp', 'ToolTypeDomainId')

			INSERT INTO tmp_NewDomainTableList(FKConstraint, TableName, ColumnName)
			VALUES ('FK_StgILICA_ILICADepthDomain', 'Stg_ILICrackAnomaly', 'ILICADepthDomainId')

			-- LD tables that will not have a foreign key referencing them but are necessary for App function
			INSERT INTO tmp_NewDomainTableList(DomainDescr, DomainCatalogId, LDTableName)
			SELECT DISTINCT dc.DomainDescr, 
					dc.Id,
					ldi.LDTableName
			FROM DRASSQL2019.DrasInternal.dbo.ListDomainTableInfo ldi
			LEFT JOIN DomainCatalog dc
			ON ldi.DomainDescr = dc.DomainDescr Collate SQL_Latin1_General_CP1_CI_AS
			WHERE dc.DomainDescr LIKE '%PMM%'
			OR LDTableName IN ('LD_ActionItemCategory', 'LD_ActionItemStatus')

			-------------- Get the New ListDomain table names from the ListDomainTableInfo table -----------------------------------------------------
				
			-- Get the new ListDomain table name for each table based on table and column matching from DRASSQL2019.DrasInternal.dbo.ListDomainTableInfo 
			UPDATE tmp_NewDomainTableList
			SET LDTableName = ldti.LDTableName collate SQL_Latin1_General_CP1_CI_AS
			FROM tmp_NewDomainTableList nld
			JOIN DRASSQL2019.DrasInternal.dbo.ListDomainTableInfo ldti
				ON ldti.ColumnName = nld.ColumnName collate SQL_Latin1_General_CP1_CI_AS
			WHERE nld.LDTableName IS NULL

			-- Get the DomainDescr, DomainCatalogId and new ListDomain table name for each table based on column matching from DRASSQL2019.DrasInternal.dbo.ListDomainTableInfo 
			UPDATE tmp_NewDomainTableList
			SET DomainDescr = ldti.DomainDescr collate SQL_Latin1_General_CP1_CI_AS,
				DomainCatalogId = dc.Id
			FROM tmp_NewDomainTableList nld
			JOIN DRASSQL2019.DrasInternal.dbo.ListDomainTableInfo ldti
				ON ldti.ColumnName = nld.ColumnName collate SQL_Latin1_General_CP1_CI_AS
				AND ldti.DomainDescr IS NOT NULL
			LEFT JOIN DomainCatalog dc
				ON dc.DomainDescr = ldti.DomainDescr collate SQL_Latin1_General_CP1_CI_AS
			WHERE nld.DomainDescr IS NULL
	
			-- Update the DomainDescr and DomainCatalogId info using the DomainCatalogColXRef table
			UPDATE tmp_NewDomainTableList
			SET DomainDescr = dc.DomainDescr,
				DomainCatalogId = dc.Id 
			FROM tmp_NewDomainTableList tmp
			JOIN DomainCatalogColXRef dxref ON tmp.TableName = dxref.TableName
			AND tmp.ColumnName = dxref.ColumnName
			JOIN DomainCatalog dc ON dc.Id = dxref.DomainCatalogId

			-- Update the DomainDescr and DomainCatalogId (if missing) using similarly-named columns
			UPDATE tab1 
			SET DomainDescr = tab2.DomainDescr,
				DomainCatalogId = tab2.DomainCatalogId
			FROM tmp_NewDomainTableList tab1
			JOIN tmp_NewDomainTableList tab2
			ON (tab1.ColumnName = tab2.ColumnName
			OR tab1.LDTableName = tab2.LDTableName)
			AND tab2.DomainCatalogId IS NOT NULL
			WHERE tab1.DomainDescr IS NULL OR tab1.DomainCatalogId  IS NULL

			/*
				Check that all LD tables except ones referenced by Field_#_DomainId column of IRASCustom tables have a 
				DomainDescr and DomainCatalogId
			*/
			SELECT @flag = COUNT(*) FROM tmp_NewDomainTableList 
			WHERE (DomainDescr IS NULL OR DomainCatalogId IS NULL)
			AND TableName NOT LIKE 'IRASCustom%'
			AND TableName <> 'VirtualTableData'

			IF @flag <> 0
			BEGIN
				SELECT LDTableName, 
					   TableName, 
					   ColumnName, 
					   DomainDescr,
					   'IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = ''' + DomainDescr + ''')
					   BEGIN
					   INSERT INTO DomainCatalog(Id, DomainDescr) ' 
					   + 'SELECT MAX(Id) + 1,''' + DomainDescr + ''' FROM DomainCatalog
					   END' [Add Missing DomainCatalog]
				FROM tmp_NewDomainTableList
				WHERE (DomainDescr IS NULL OR DomainCatalogId IS NULL)
				AND TableName NOT LIKE 'IRASCustom%'
				AND TableName <> 'VirtualTableData'

				SET @SQL = NULL

				SET @ErrorMessage = 'The tables listed in the Results tab are MISSING A DOMAIN CATALOG REFERENCE.'
				+ CHAR(10) + 'To resolve this issue, add a domain catalog entry in the DomainCatalog and/or DomainCatalogColXRef tables.' + CHAR(10);

				THROW 51001, @ErrorMessage, 1
			END
							   			
			--Generate an LD table name for tables that could not be matched with an LD table name in the DRASSQL2019.DrasInternal.dbo.ListDomainTableInfo database
			UPDATE tmp_NewDomainTableList
			SET LDTableName = CASE WHEN LDTableName IS NULL THEN (CASE WHEN PATINDEX('%_DomainId', ColumnName) > 0
																THEN 'LD_' + REPLACE(REPLACE(ColumnName, '_DomainId', ''), 'DomainId', '') 
															WHEN PATINDEX('%Ld', ColumnName) > 0
																THEN 'LD_' + REPLACE(ColumnName, 'Ld', '')
															ELSE 'LD_' + ColumnName
														END)
							ELSE LDTableName
							END,
				DomainCatalogId = CASE WHEN DomainCatalogId IS NULL THEN dc.Id ELSE DomainCatalogId END
			FROM tmp_NewDomainTableList tld
			LEFT JOIN DomainCatalog dc ON tld.DomainDescr = dc.DomainDescr
			WHERE LDTableName IS NULL OR DomainCatalogId IS NULL

			------------------------ Move PK to Id column for relevant tables ---------------------

			-- Recreate primary key on the 'Id' column in tables that reference the ListDomain table but do not have an 'Id' column
			DECLARE MovePKCursor CURSOR FOR
			SELECT DISTINCT 'ALTER TABLE ' + table_name + ' DROP CONSTRAINT ' + ind.name + CHAR(10)
							+ 'ALTER TABLE ' + table_name + ' ADD Id INT IDENTITY (1,1) CONSTRAINT PK_' + table_name + ' PRIMARY KEY'
			FROM INFORMATION_SCHEMA.COLUMNS  tab1
			JOIN sys.indexes ind
			ON tab1.table_name = OBJECT_NAME(ind.object_id)
			AND is_primary_key = 1
			WHERE table_name NOT IN (SELECT DISTINCT table_name 
									 FROM INFORMATION_SCHEMA.columns tab2 
									 WHERE column_name = 'id')
			AND table_name IN (SELECT OBJECT_NAME(parent_object_id)
								FROM sys.foreign_keys WHERE OBJECT_NAME(referenced_object_id) = 'ListDomain')
			AND NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE OBJECT_NAME(referenced_object_id) = tab1.table_name)

			OPEN MovePKCursor
			FETCH NEXT FROM MovePKCursor INTO @SQL

			WHILE @@FETCH_STATUS = 0
			BEGIN
				EXECUTE (@SQL)
				FETCH NEXT FROM MovePKCursor INTO @SQL
			END

			CLOSE MovePKCursor
			DEALLOCATE MovePKCursor

		
			/*************************************************************************************************
								CREATE New Listdomain tables & Populate the new tables with Data
			**************************************************************************************************/
			
			DECLARE LDTables_Cursor CURSOR FOR 
			SELECT TableName,
					ColumnName,
					REPLACE(LDTableName, CHAR(32), ''),
					DomainCatalogId, 
					DomainDescr,
					FKConstraint
			FROM tmp_NewDomainTableList
			
			OPEN LDTables_Cursor
			FETCH NEXT FROM LDTables_Cursor INTO @TableName, @ColumnName, @NewTableName, @DomainCatalogId, @DomainDescr, @FKConstraintName

			WHILE @@FETCH_STATUS = 0
			BEGIN

			--------------------- 1) ListDomain source-table columns that can be found in DomainCAtalogXRef table
				
				-- Store all ListDomain table entries for each table and column combination in the current loop iteration in a temporary table
				SET @SQL = 'TRUNCATE TABLE tmp_ListDomainInfo'  + '

							INSERT INTO tmp_ListDomainInfo'  + ' (Id, DomainCatalogId, DomainDescr, Code, Descr)
							SELECT Id,
									DomainCatalogId,
									(SELECT DomainDescr FROM DomainCatalog WHERE Id = ld.DomainCatalogId),
									Code,
									Descr 
							FROM ListDomain ld
							WHERE Id IN (SELECT DISTINCT ' + @ColumnName + ' FROM ' + @TableName+ ')'

				EXECUTE (@SQL)	
			

				SELECT @DomainCatalogId = DomainCatalogId 
				FROM DomainCatalogColXRef 
				WHERE TableName = @TableName AND ColumnName = @ColumnName 
			
				SELECT @Count = COUNT(DISTINCT DomainCatalogId) FROM tmp_ListDomainInfo
				WHERE DomainCatalogId <> -1	
			
				/*
					if the table and column in the current iteration has no entry in the DomainCatalogColXRef 
					table and there are more than 1 distinct DomainCatalogIds in it's entries in the ListDomain table, 
					then throw an error to force user to manually fix the issue
				*/
				IF (@DomainCatalogId IS NULL) AND @Count >= 2
				BEGIN
					
					SET @ErrorMessage = 'More than 1 distinct DomainCatalogId was found in the Listdomain table for Column ---> '  
									+ @ColumnName + CHAR(10) + 'of the ''' + @TableName + ''' table'
									+ '. ONLY 1 distinct DomainCatalogId is allowed. A manual fix is required for the script to continue'
									+ CHAR(10) + 'The query below shows all the ListDomain table entries for the table-column combination mentioned' + CHAR(10)
		
					SET @ErrorMessage += CHAR(10) + 'QUERY: SELECT Id, DomainCatalogId, Code,	Descr, LastModByUserId, LastModDateTime, SourceDomainId' + CHAR(10) + CHAR(9) + CHAR(9) +
							'FROM ListDomain' + CHAR(10) + CHAR(9) + CHAR(9) +
							'WHERE Id IN (SELECT DISTINCT ' + @ColumnName + ' FROM ' + @TableName+ ')' + CHAR(10)

					SET @ErrorMessage += CHAR(10) + 'SOLUTION: A reference may not have been found in the DomainCatalogColXRef table for column ''' + @ColumnName + ''''
						+  'of table ''' + @TableName + '''. '
						+ 'Talk to the BA assigned to the client for this database and assign an appropriate DomainCatalog' 
						+ CHAR(10) + 'You may need to set some values in ''' + @ColumnName+ ''' column of ''' + @TableName + ''' table to NULL' + CHAR(10)		

					SET @SQL = NULL
					DEALLOCATE LDTables_Cursor;
					THROW 51001, @ErrorMessage, 1

				END
		
			/*****************************************************************************************
								Create and Populate New List Domain Tables 
			**********************************************************************************************/
	
			-------------------------------------- CREATE New ListDomain tables ---------------------------------------
				-- Create LD tables
				IF OBJECT_ID(@NewTableName, 'U') IS NULL
				BEGIN
					SET @SQL = 'CREATE TABLE [dbo].' +QUOTENAME( @NewTableName) + '(
					[Id] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
					[Code] varchar(60) NOT NULL,
					[Descr] varchar(255) NOT NULL,
					[EffectiveEndDate] Datetime,
					[CreatedUser] varchar(45) DEFAULT (suser_sname()) NOT NULL,
					[CreatedDate] datetime DEFAULT (getdate()) NOT NULL,
					[LastModByUserId] varchar(45) DEFAULT (suser_sname()) NOT NULL,
					[LastModDateTime] datetime DEFAULT (getdate()) NOT NULL
					)';

					EXECUTE sp_executesql @SQL
			
					-- Recreate update trigger on LD table
					SET @SQL = 'IF NOT EXISTS (SELECT * FROM sys.triggers WHERE name = ''tu_' + @NewTableName + ''')
					BEGIN
						EXECUTE(''CREATE TRIGGER [dbo].[tu_' + @NewTableName + '] ON [dbo].[' + @NewTableName + '] FOR UPDATE AS 
						IF EXISTS(SELECT * FROM DELETED)
						BEGIN
							UPDATE dbo.' + @NewTableName + '
							SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
							FROM dbo.' + @NewTableName + ' as t, DELETED as d
							WHERE t.Id=d.Id;
						END'')
					END'

					EXECUTE sp_executesql @SQL

				END; -- End create new list domain table

			----------------------------- REMOVE FOREIGN KEYS FROM TABLES REFERENCING LISTDOMAIN TABLE -------------------------------
		
				-- Drop the foreign key on the domain child table if it references the ListDomain table
				SELECT @SQL = 'ALTER TABLE ' + @TableName + ' DROP CONSTRAINT ' + @FKConstraintName
				FROM sys.foreign_key_columns
				WHERE OBJECT_NAME(constraint_object_id) = @FKConstraintName
				AND OBJECT_NAME(referenced_object_id) = 'ListDomain'

				EXECUTE sp_executesql @SQL;	
				 
			------------------------ Populate LD tables and Clean data ----------------------------------
			
			/*
				Insert into Temporary ListDomain table orphaned child table entries that are missing a parent entry from the ListDomain table.
				This data will be assigned a code and descr of 'UnKnown' and an expired end date
			*/
				SET @SQL = 'INSERT INTO Temp_ListDomain (Old_Id, Code, Descr, LDTableName, DomainCatalogId, DomainDescr, LastModDateTime, LastModByUserId)
				SELECT DISTINCT ' + @ColumnName + ', 			
						CASE WHEN Code IS NULL THEN ''Unknown'' ELSE Code END, 
						CASE WHEN Descr IS NULL THEN ''Unknown'' ELSE Descr END, 
						''' + @NewTableName + ''',
						' + CAST(@DomainCatalogId AS NVARCHAR) + ', 
						''' + @DomainDescr + ''',
						GETDATE(), 
						SUSER_SNAME()
				FROM ' + @TableName + ' tab
				LEFT JOIN Temp_ListDomain ld
				ON tab.' + @ColumnName + ' = ld.Old_Id
				WHERE  ' + @ColumnName + ' NOT IN (SELECT Old_Id FROM Temp_ListDomain)'

				EXECUTE (@SQL)
								
				--- Assign correct LD table and DomainDescr ListDomain entries that don't match assigned values from tmp_NewDomainTableList
				SET @SQL = 'UPDATE Temp_ListDomain
							SET LDTableName = ''' + @NewTableName + '''
							--DomainDescr = ''' + @DomainDescr + '''
							FROM Temp_ListDomain ld
							JOIN ' + @TableName + ' tab
							ON ld.Old_Id = tab.' + @ColumnName + '
							WHERE ld.LDTableName <> ''' + @NewTableName + '''
							OR ld.LDTableName IS NULL'

				EXECUTE (@SQL)

				-- Copy data from the ListDomain table to the LD tables and remove duplicate code and descr entries
				SET @SQL = 'SET IDENTITY_INSERT ' + @NewTableName + ' ON;

				WITH CTE AS 
				(SELECT DISTINCT ld.Old_Id AS Id, 
						LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(ld.Code, CHAR(10), '' ''), CHAR(9), '' ''), CHAR(13), '' '')))  AS Code,
						LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(ld.Descr, CHAR(10), '' ''), CHAR(9), '' ''), CHAR(13), '' '')))  AS Descr
				 FROM Temp_ListDomain ld
				 WHERE LDTableName = ''' + @NewTableName + '''
				)
				INSERT INTO ' + @NewTableName  + ' (Id, Code, Descr, EffectiveEndDate)
				SELECT Id, 
					   Code, 
					   Descr, 	
					   NULL
				FROM CTE
				WHERE NOT EXISTS (SELECT * FROM ' + @NewTableName  + ' nt2 
									WHERE cte.Id = nt2.Id)
				ORDER BY Code, Id
				  
				SET IDENTITY_INSERT ' + @NewTableName + ' OFF'
					
				EXECUTE (@SQL)

				-- Insert missing entries or entries with 'DELETED' DomainDescr that are still being referenced by child tables into LD tables
				SET @SQL = 'SET IDENTITY_INSERT ' + @NewTableName + ' ON;

							WITH CTE AS
							(SELECT DISTINCT ld.Old_Id AS Id, 
											 LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(ld.Code, CHAR(10), '' ''), CHAR(9), '' ''), CHAR(13), '' '')))  AS Code,
											 LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(ld.Descr, CHAR(10), '' ''), CHAR(9), '' ''), CHAR(13), '' '')))  AS Descr,
											 DomainCatalogId
							FROM Temp_ListDomain ld
							LEFT JOIN ' + @NewTableName + ' nt
							ON nt.code = ld.code
							AND nt.Descr = ld.Descr
							WHERE old_id IN (SELECT DISTINCT ' + @ColumnName + ' FROM  ' + @TableName + ')
							AND nt.Id IS NULL
							)
							INSERT INTO ' + @NewTableName + ' (Id, Code, Descr, EffectiveEndDate)
							SELECT Id,
								Code,
								Descr,
								NULL
							FROM CTE
							WHERE Id NOT IN (SELECT Id FROM ' + @NewTableName  + ')
							ORDER BY Code, Id
							
							SET IDENTITY_INSERT ' + @NewTableName + ' OFF'
				
				EXECUTE (@SQL)
		
				-- Expire Duplicate codes
				SET @SQL = 'WITH CTE AS 
							(SELECT Id, 
							        Code,
								    CASE 
										WHEN DomainCatalogId = -1 AND EXISTS (SELECT Code, Descr, COUNT(*) 
																				FROM Temp_ListDomain tmp
																				WHERE tmp.Code = subq.Code 
																				GROUP BY Code, Descr HAVING COUNT(*) = 1) THEN GETDATE()
										WHEN dup_code = 1 THEN NULL
										ELSE GETDATE()
								   END  AS EffectiveEndDate
							 FROM (SELECT ROW_NUMBER() OVER (PARTITION BY nt.Code, nt.Descr ORDER BY nt.Code, nt.Id) dup_code, 
									nt.Id,
									nt.Code,
									nt.Descr,
									ld.DomainCatalogId
							FROM ' + @NewTableName + ' nt
							JOIN Temp_ListDomain ld 
							ON nt.Id = ld.Old_Id) subq
							)
							UPDATE ' + @NewTableName + '
							SET EffectiveEndDate = cte.EffectiveEndDate
							FROM ' + @NewTableName + ' nt
							JOIN CTE ON nt.Id = cte.Id'
							
				EXECUTE (@SQL)

				--Update the New_Id column in Temp_ListDomain table
				SET @SQL = 'UPDATE Temp_ListDomain
							SET New_Id = CASE WHEN EXISTS (SELECT Code, Descr, COUNT(*) FROM ' + @NewTableName +' tmp 
																			WHERE tmp.Code = nt.Code AND tmp.Descr = nt.Descr 
																			GROUP BY Code, Descr HAVING COUNT(*) > 1) 
																		THEN CASE WHEN ld.Old_Id <> (SELECT Id FROM ' + @NewTableName +' tmp WHERE tmp.Code = nt.Code AND tmp.Descr = nt.Descr
																					AND EffectiveEndDate IS NULL)
																					THEN (SELECT Id FROM ' + @NewTableName +' tmp WHERE tmp.Code = nt.Code AND tmp.Descr = nt.Descr
																							AND EffectiveEndDate IS NULL)
																				ELSE NULL
																			END
																	ELSE NULL
															END,
								LDTableName = ''' + @NewTableName + '''
							FROM Temp_ListDomain ld
							JOIN ' + @NewTableName + ' nt
							ON nt.Code = ld.Code
							AND nt.Descr = ld.Descr
							 WHERE ld.LDTableName = ''' + @NewTableName + ''''
							 
				EXECUTE (@SQL)

								
				-- Update the new ListDomain Id column in Temp_VirtualTableDataListDomain
				SET @SQL = 'UPDATE Temp_VirtualTableDataListDomain
							SET New_DataFieldValueDomainId = CASE WHEN EXISTS (SELECT Code, Descr, COUNT(*) FROM ' + @NewTableName +' tmp 
																			WHERE tmp.Code = nt.Code AND tmp.Descr = nt.Descr 
																			GROUP BY Code, Descr HAVING COUNT(*) > 1) 
																		THEN (SELECT DISTINCT Id FROM ' + @NewTableName +' tmp WHERE tmp.Code = nt.Code AND tmp.Descr = nt.Descr
																		     AND EffectiveEndDate IS NULL)
																	ELSE NULL
															END
							FROM Temp_VirtualTableDataListDomain ld
							JOIN ' + @NewTableName +' nt
							ON nt.Code = ld.Code
							AND nt.Descr = ld.Descr
							WHERE LDTableName = ''' + @NewTableName +''''

				EXECUTE (@SQL)
				
				-- Change value in ListDomain child tables to match new Id values in LD table
				SET @SQL = 'UPDATE ' + @TableName + '
							SET ' + @ColumnName + ' = CASE WHEN EXISTS (SELECT Code, Descr, COUNT(*) FROM ' + @NewTableName +' tmp 
																			WHERE tmp.Code = nt.Code AND tmp.Descr = nt.Descr 
																			GROUP BY Code, Descr HAVING COUNT(*) > 1) 
																		THEN (SELECT Id FROM ' + @NewTableName +' tmp WHERE tmp.Code = nt.Code AND tmp.Descr = nt.Descr
																		     AND EffectiveEndDate IS NULL)
																	ELSE nt.Id
															END
							FROM Temp_ListDomain ld
							JOIN ' + @TableName + ' tab
								ON ld.Old_Id = tab.' + @ColumnName + '
							JOIN ' + @NewTableName + ' nt
								ON nt.Code = ld.Code
								AND nt.Descr = ld.Descr'

				EXECUTE (@SQL)

				-------------------------------- UPDATE TempListDomainTable  ---------------------------------------

				-- Create TempListDomainTable table in Config database if it doesn't already exist
				IF OBJECT_ID('TempListDomainTable', 'U') IS NULL
				BEGIN
					CREATE TABLE dbo.TempListDomainTable (TableType VARCHAR(50),
																			LDTableName VARCHAR(100),
																			TableName VARCHAR(50),
																			ColumnName VARCHAR(50),
																			DomainCatalogId INT,
																			DomainDescr VARCHAR(255),
																			HasData VARCHAR(3),
																			ListDomainDataCountMatches VARCHAR(3)
																			)
				END

				-- Insert entries for table and column in current loop iteration into TempListDomainTable
				IF (@ColumnName IS NOT NULL)
				BEGIN 
			
					INSERT INTO TempListDomainTable (TableType, LDTableName, TableName, ColumnName, DomainCatalogId, DomainDescr)
					SELECT 'Real',
							@NewTableName,
							@TableName,
							@ColumnName,
							@DomainCatalogId,
							@DomainDescr
					WHERE NOT EXISTS (SELECT * FROM TempListDomainTable 
										WHERE TableType = 'Real' AND TableName = @TableName 
										AND ColumnName = @ColumnName	AND LDTableName = @NewTableName)
				END
				ELSE
				BEGIN			
					INSERT INTO TempListDomainTable (TableType, LDTableName, TableName, ColumnName, DomainCatalogId, DomainDescr)
					SELECT 'Real',
							@NewTableName,
							NULL,
							NULL,
							@DomainCatalogId,
							@DomainDescr
					WHERE NOT EXISTS (SELECT 1 FROM TempListDomainTable 
										WHERE TableType = 'Real' 
										AND LDTableName = @NewTableName)
				END

				--------------------------- Track Data in LD tables ------------------------------------

				-- Check if the LD table has data and if the data matches what's in the ListDomain table
				SET  @SQL = 'UPDATE TempListDomainTable
							SET ListDomainDataCountMatches = (SELECT CASE WHEN COUNT(*) = 0 THEN ''YES''
																		ELSE ''NO''
																	 END	
																FROM Temp_ListDomain ld
																	WHERE NOT EXISTS (SELECT * FROM ' + @NewTableName + ' nt
																					  WHERE nt.Id = ld.Old_Id)
																	AND LDTableName = '''+ @NewTableName +'''
															  ),
								 HasData = (SELECT CASE WHEN COUNT(*) > 0 THEN ''YES''
														ELSE ''NO''
													END
											FROM ' + @NewTableName + ')
							FROM TempListDomainTable tld
							WHERE LDTableName = ''' + @NewTableName + '''
							AND TableName = ''' + @TableName + '''
							AND ColumnName = ''' + @ColumnName + ''''

				EXECUTE (@SQL)
			
				FETCH NEXT FROM LDTables_Cursor INTO @TableName, @ColumnName, @NewTableName, @DomainCatalogId, @DomainDescr, @FKConstraintName

			END

			CLOSE LDTables_Cursor
			DEALLOCATE LDTables_Cursor;

			-- Make sure DomainDescr and DomainCatalogId in TempListdomaintable and Temp_VirtualTableDataListDomain match the DomainCatalog table
			UPDATE tld 
			SET DomainCatalogId = dc.Id,
				LDTableSchema = (SELECT table_schema FROM INFORMATION_SCHEMA.tables WHERE table_name = tld.LDTableName),
				TableSchema = (SELECT table_schema FROM INFORMATION_SCHEMA.columns WHERE table_name = tld.TableName AND column_name = tld.ColumnName)
			FROM TempListdomaintable tld
			JOIN DomainCatalog dc ON tld.DomainDescr = dc.DomainDescr 
			 
			UPDATE Temp_VirtualTableDataListDomain
			SET DomainCatalogId = dc.Id
			FROM Temp_VirtualTableDataListDomain vtld
			JOIN DomainCatalog dc ON vtld.DomainDescr = dc.DomainDescr 
			WHERE dc.Id <> vtld.DomainCatalogId 

			--------------- Add primary key to LD tables and add foreign keys to child tables ---------------

			DECLARE AddPKandFK_Cursor CURSOR FOR
			SELECT tld.TableName,
			tld.ColumnName,
			tld.LDTableName,
			nld.FKConstraint
			FROM TempListDomainTable tld
			LEFT JOIN tmp_NewDomainTableList nld
			ON nld.TableName = tld.TableName
			AND nld.ColumnName = tld.ColumnName

			OPEN AddPKandFK_Cursor
			FETCH NEXT FROM AddPKandFK_Cursor INTO @TableName, @ColumnName, @NewTableName, @FKConstraintName

			WHILE @@FETCH_STATUS = 0
			BEGIN
				-- Add primary key
				IF OBJECT_ID('PK_' + @NewTableName , 'PK') IS NULL
				BEGIN
					SET @SQL = 'ALTER TABLE ' + @NewTableName + ' ADD CONSTRAINT PK_' + @NewTableName + ' PRIMARY KEY(Id)'
					
					EXECUTE (@SQL)
				END
					
				FETCH NEXT FROM AddPKandFK_Cursor INTO @TableName, @ColumnName, @NewTableName, @FKConstraintName
			END

			CLOSE AddPKandFK_Cursor
			DEALLOCATE AddPKandFK_Cursor

			-- Save a copy of SystemPreferences table
			IF OBJECT_ID('SystemPreferences_BKP') IS NULL
			BEGIN
				SELECT * INTO SystemPreferences_BKP 
				FROM SystemPreferences
			END

			-- Update ListDomain Ids in SystemPreferences table
			SET @SQL = 'UPDATE SystemPreferences 
			SET value = CASE WHEN New_Id IS NULL THEN Old_Id ELSE New_Id END
			FROM SystemPreferences sp
			JOIN Temp_ListDomain ld ON CAST(sp.value AS INT) = Old_Id
			WHERE ParameterName LIKE ''Default%''
			AND value LIKE ''[0-9]%[0-9]'''

			EXECUTE (@SQL)

			/****************************************************************************************************************
											Script Sanity Checks
			****************************************************************************************************************/

			------------------------ Check that all LD tables are created -------------------------
			
			SELECT @flag = COUNT(*) 
			FROM TempListDomainTable
			WHERE LDTableName NOT IN (SELECT name FROM sys.tables)

			IF @flag <> 0 
			BEGIN
				SELECT LDTableName FROM TempListDomainTable
				WHERE LDTableName NOT IN (SELECT name FROM sys.tables);
				
				SET @ErrorMessage = 'The LD tables listed in the Results tab were not created. All tables listed in TempListDomainTable must be created' + CHAR(10);
				SET @SQL = NULL;
				THROW 51001, @ErrorMessage, 1;
			
			END

			---------------------------------------- QC data in LD tables ---------------------------------------

			-- Check that data in LD tables match data in ListDomain table
			SELECT @flag = COUNT(*) 
			FROM TempListDomainTable 
			WHERE ListDomainDataCountMatches = 'NO';


			IF @flag <> 0
			BEGIN
				SELECT * FROM TempListDomainTable WHERE ListDomainDataCountMatches = 'NO';
				SET @ErrorMessage = 'The data in the LD tables listed in the Results tab do not match the data in the ListDomain table'
				SET @SQL = NULL;
				THROW 51001, @ErrorMessage, 1;
			END
	
			/*
				Check that the LDTableName, DomainCatalogId and DomainDescr are conistent in
				Temp_VirtualTableDataListDomain, Temp_ListDomain and TempListDomainTable tables
			*/

			SELECT @flag = COUNT(*)
			FROM Temp_VirtualTableDataListDomain vtld
			JOIN Temp_ListDomain ld
			ON ld.Old_Id = vtld.Old_DataFieldValueDomainId
			JOIN TempListDomainTable tmp
			ON vtld.VirtualTableName = tmp.TableName
			AND vtld.VirtualColumnName = tmp.ColumnName
			WHERE ld.New_Id <> vtld.New_DataFieldValueDomainId OR
				vtld.LDTableName <> ld.LDTableName OR vtld.LDTableName <> tmp.LDTableName
				OR ld.LDTableName <> tmp.LDTableName OR vtld.LDTableName IS NULL
				OR ld.LDTableName IS NULL OR tmp.LDTableName IS NULL
				OR vtld.DomainDescr <> ld.DomainDescr OR vtld.Domaindescr <> tmp.DomainDescr
				OR ld.DomainDescr <> tmp.DomainDescr 
				OR (vtld.DomainDescr IS NULL OR ld.DomainDescr IS NULL OR tmp.DomainDescr IS NULL AND TableName NOT LIKE 'IRASCustom%')
				OR vtld.DomainCatalogId <> ld.DomainCatalogId OR vtld.DomainCatalogId <> tmp.DomainCatalogId
				OR ld.DomainCatalogId <> tmp.DomainCatalogId 
				OR (vtld.DomainCatalogId IS NULL OR ld.DomainCatalogId IS NULL OR tmp.DomainCatalogId IS NULL AND TableName NOT LIKE 'IRASCustom%')
				 

			IF @Flag <> 0
			BEGIN
				SELECT  DISTINCT VirtualTableName, 
						VirtualColumnName, 
						vtld.Old_DataFieldValueDomainId
						,ld.Old_Id
						,vtld.New_DataFieldValueDomainId
						,ld.New_Id
						,vtld.LDTableName VirtualTableDataListDomain_TableName
						,ld.LDTableName ListDomain_LDTableName
						,tmp.LDTableName TempListDomainTable_TableName
						,vtld.DomainDescr VirtualTableDataListDomain_DomainDescr
						,ld.DomainDescr ListDomain_DomainDescr
						,tmp.DomainDescr TempListDomainTable_DomainDescr
				FROM Temp_VirtualTableDataListDomain vtld
				JOIN Temp_ListDomain ld
				ON ld.Old_Id = vtld.Old_DataFieldValueDomainId
				JOIN TempListDomainTable tmp
				ON vtld.VirtualTableName = tmp.TableName
				AND vtld.VirtualColumnName = tmp.ColumnName
				WHERE ld.New_Id <> vtld.New_DataFieldValueDomainId OR
					vtld.LDTableName <> ld.LDTableName OR vtld.LDTableName <> tmp.LDTableName
					OR ld.LDTableName <> tmp.LDTableName OR vtld.LDTableName IS NULL
					OR ld.LDTableName IS NULL OR tmp.LDTableName IS NULL
					OR vtld.DomainDescr <> ld.DomainDescr OR vtld.Domaindescr <> tmp.DomainDescr
					OR ld.DomainDescr <> tmp.DomainDescr 
					OR (vtld.DomainDescr IS NULL OR ld.DomainDescr IS NULL OR tmp.DomainDescr IS NULL AND TableName NOT LIKE 'IRASCustom%')
					OR vtld.DomainCatalogId <> ld.DomainCatalogId OR vtld.DomainCatalogId <> tmp.DomainCatalogId
					OR ld.DomainCatalogId <> tmp.DomainCatalogId 
					OR (vtld.DomainCatalogId IS NULL OR ld.DomainCatalogId IS NULL OR tmp.DomainCatalogId IS NULL AND TableName NOT LIKE 'IRASCustom%')
				ORDER BY 1, 2

				SET @ErrorMessage = N'The New LD table name, DomainCatalogId, and/or new ListDomain Ids are inconistent in the following tables: '
				+CHAR(10) + 'Temp_VirtualTableDataListDomain, Temp_ListDomain, TempListDomainTable' + CHAR(10) + CHAR(10)
				+ 'These columns must match across these tables. ' + CHAR(10)+ CHAR(10) +'The inconsistent rows are in the Results tab' + CHAR(10);
	
				THROW 51001, @ErrorMessage, 1
			END
                    
			/*************************************************************************************************
								CREATE New Tables for CategoryDataListDomainXRef Table
			**************************************************************************************************/

			IF COL_LENGTH('CategoryDataListDomainXRef', 'ListDomainTableName') IS NULL 
				AND OBJECT_ID('CategoryDataListDomainXRef') IS NOT NULL
			BEGIN
				--Save the data 
				IF OBJECT_ID('tmp_CategoryDataListDomainXRef', 'U' ) IS NOT NULL
				BEGIN
					DROP TABLE tmp_CategoryDataListDomainXRef;
				END

				IF OBJECT_ID('CategoryDataListDomainXRef_BKP', 'U' ) IS NOT NULL
				BEGIN
					DROP TABLE CategoryDataListDomainXRef_BKP;
				END

				SET @SQL = 'SELECT cdl.Id,
								   (SELECT table_schema FROM INFORMATION_SCHEMA.tables 
								   WHERE table_name = ld.LDTableName) AS ListDomainTableSchema,
								   ld.LDTableName AS ListDomainTableName,
								   ld.DomainCatalogid,
								   ld.New_Id,
								   cdl.CategoryId,
								   NULL CreatedUser,
								   GetDate() CreatedDate,
								   cdl.LastModBYUserId,
								   cdl.LastModDateTime
				INTO tmp_CategoryDataListDomainXRef
				FROM CategoryDataListDomainXRef cdl
				JOIN Temp_ListDomain ld
				ON ld.Old_Id = cdl.ValueDomainId
				ORDER BY 1'

				EXECUTE (@SQL)
				
				-- Delete all foreign key constraints on the CategoryDataListDomainXRef table
				SELECT @SQL = STUFF(
									(SELECT '  ALTER TABLE ' + OBJECT_NAME(parent_object_id) 
										+ ' DROP CONSTRAINT ' + name, CHAR(10)
									FROM sys.foreign_keys
									WHERE OBJECT_NAME(referenced_object_id) = 'CategoryDataListDomainXRef'
									ORDER BY name
									FOR XML PATH(N''), TYPE
									).value(N'.[1]', N'nvarchar(max)'), 1, 2, N''
				)
				
				EXECUTE sp_executesql @SQL

				-- Save old CategoryDataListDomainXRef table 
				SELECT * INTO CategoryDataListDomainXRef_BKP FROM CategoryDataListDomainXRef

				IF OBJECT_ID('CategoryDataListDomainXRef', 'U') IS NOT NULL
				BEGIN
					DROP TABLE CategoryDataListDomainXRef
				END

				IF OBJECT_ID('CategoryDataListDomainXRef', 'U') IS NULL
				BEGIN
					SELECT * INTO CategoryDataListDomainXRef FROM tmp_CategoryDataListDomainXRef

					ALTER TABLE [dbo].[CategoryDataListDomainXRef] ADD  DEFAULT (SUSER_SNAME()) FOR [CreatedUser]
					ALTER TABLE [dbo].[CategoryDataListDomainXRef] ADD  DEFAULT (GETDATE()) FOR [CreatedDate]
					ALTER TABLE [dbo].[CategoryDataListDomainXRef] ADD  DEFAULT (SUSER_SNAME()) FOR [LastModByUserId]
					ALTER TABLE [dbo].[CategoryDataListDomainXRef] ADD  DEFAULT (GETDATE()) FOR [LastModDateTime]
					
					--Add foreign key referencing Category table
					ALTER TABLE CategoryDataListDomainXRef WITH CHECK 
					ADD CONSTRAINT FK_CDLDXCategoryId FOREIGN KEY (CategoryId)
					REFERENCES Category(Id)
				END 
							
				-- Add a primary key
				IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE OBJECT_NAME(object_id) = 'CategoryDataListDomainXRef' AND is_primary_key = 1)
				BEGIN
					ALTER TABLE CategoryDataListDomainXRef 
					ADD CONSTRAINT PK_CategoryDataListDomainXRef PRIMARY KEY (Id)
				END 

				-- Recreate update trigger on RememberedListDomainValues table
				IF OBJECT_ID ('tu_CategoryDataListDomainXRef', 'TR') IS NULL AND OBJECT_ID('CategoryDataListDomainXRef', 'U') IS NOT NULL
				BEGIN
					SET @SQL = 'CREATE TRIGGER [dbo].[tu_CategoryDataListDomainXRef] ON [dbo].[CategoryDataListDomainXRef] FOR UPDATE AS 
					IF EXISTS(SELECT * FROM DELETED)
					BEGIN
						UPDATE dbo.CategoryDataListDomainXRef
						SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
						FROM dbo.CategoryDataListDomainXRef as t, DELETED as d
						WHERE t.Id=d.Id;
					END'

					EXECUTE sp_executesql @SQL
				END

			END

			/*****************************************************************************************
			                 Modify RememberedListDomainValues and ActionItemPropDCXRef tables
			**********************************************************************************************/

			----------------------------- MODIFY RememberedListDomainValues TABLE ------------------------------

			IF COL_LENGTH('RememberedListDomainValues', 'ListDomainTableName') IS NULL 
				AND OBJECT_ID('RememberedListDomainValues') IS NOT NULL
			BEGIN

				IF OBJECT_ID('tmp_RememberedListDomainValues' ) IS NOT NULL
				BEGIN
					DROP TABLE tmp_RememberedListDomainValues;
				END

				IF OBJECT_ID('RememberedListDomainValues_BKP' ) IS NOT NULL
				BEGIN
					DROP TABLE RememberedListDomainValues_BKP;
				END

				-- Copy data from RememberedListDomainValues into temporary table
				SET @SQL = 'SELECT rldv.Id, 
						rldv.DomainValue,
						tmp.New_Id,
						(SELECT table_schema FROM INFORMATION_SCHEMA.tables 
						WHERE table_name = tmp.LDTableName) AS ListDomainTableSchema,
						tmp.LDTableName AS ListDomainTableName,
						rldv.CreatedUser,
						rldv.CreatedDate,
						rldv.LastModByUserId,
						rldv.LastModDateTime
				INTO tmp_RememberedListDomainValues
				FROM RememberedListDomainValues rldv
				LEFT JOIN Temp_ListDomain tmp
				ON tmp.Old_Id = rldv.ListDomainId
				AND rldv.ListDomainId IS NOT NULL
				ORDER BY 1'

				EXECUTE (@SQL)

				-- Drop the foreign keys referencing the RememberedListDomainValues table 
				SELECT @SQL = STUFF(
									(SELECT '  ALTER TABLE ' + OBJECT_NAME(parent_object_id) 
										+ ' DROP CONSTRAINT ' + name, CHAR(10)
									FROM sys.foreign_keys
									WHERE OBJECT_NAME(referenced_object_id) = 'RememberedListDomainValues'					
									ORDER BY name
									FOR XML PATH(N''), TYPE
									).value(N'.[1]', N'nvarchar(max)'), 1, 2, N''
				)

				EXECUTE sp_executesql @SQL

				-- Save the RememberedListDomainValues table
				SELECT * INTO RememberedListDomainValues_BKP FROM RememberedListDomainValues

				IF OBJECT_ID('RememberedListDomainValues', 'U') IS NOT NULL
				BEGIN
					DROP TABLE RememberedListDomainValues
				END

				-- Recreate the RememberedListDomainValues table
				IF OBJECT_ID('RememberedListDomainValues','U') IS NULL
				BEGIN
					SELECT * INTO RememberedListDomainValues
					FROM tmp_RememberedListDomainValues
					ORDER BY 1

					ALTER TABLE [dbo].[RememberedListDomainValues] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]
					ALTER TABLE [dbo].[RememberedListDomainValues] ADD  DEFAULT (getdate()) FOR [CreatedDate]
					ALTER TABLE [dbo].[RememberedListDomainValues] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]
					ALTER TABLE [dbo].[RememberedListDomainValues] ADD  DEFAULT (getdate()) FOR [LastModDateTime]
				END

				-- Add primary key
				IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE OBJECT_NAME(object_id) = 'RememberedListDomainValues' AND is_primary_key = 1)
				BEGIN
					ALTER TABLE RememberedListDomainValues ADD CONSTRAINT PK_RememberedListDomainValues PRIMARY KEY (Id)
				END 

				-- Recreate update trigger on RememberedListDomainValues table
				IF OBJECT_ID ('tu_RememberedListDomainValues', 'TR') IS NULL AND OBJECT_ID('RememberedListDomainValues', 'U') IS NOT NULL
				BEGIN
					SET @SQL = 'CREATE TRIGGER [dbo].[tu_RememberedListDomainValues] ON [dbo].[RememberedListDomainValues] FOR UPDATE AS 
					IF EXISTS(SELECT * FROM DELETED)
					BEGIN
						UPDATE dbo.RememberedListDomainValues
						SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
						FROM dbo.RememberedListDomainValues as t, DELETED as d
						WHERE t.Id=d.Id;
					END'

					EXECUTE sp_executesql @SQL
				END

			END

			-------------------------------- MODIFY ActionItemPropDCXRef TABLE --------------------------------

			IF COL_LENGTH('ActionItemPropDCXRef', 'ListDomainTableName') IS NULL 
				AND OBJECT_ID('ActionItemPropDCXRef') IS NOT NULL
			BEGIN

				IF OBJECT_ID ('tmp_ActionItemPropDCXRef' , 'U') IS NOT NULL 
				BEGIN
					DROP TABLE tmp_ActionItemPropDCXRef
				END

				IF OBJECT_ID ('ActionItemPropDCXRef_BKP' , 'U') IS NOT NULL 
				BEGIN
					DROP TABLE ActionItemPropDCXRef_BKP
				END

				-- Store data from ActionItemPropDCXRef into temporary table 
				SET @SQL = 'SELECT DISTINCT aip.ActionItemPropertyId,
								   aip.DomainCatalogId,
								   (SELECT table_schema FROM INFORMATION_SCHEMA.tables 
								   WHERE table_name = tmp.LDTableName) AS ListDomainTableSchema,
								   tmp.LDTableName AS ListDomainTableName,
								   aip.CreatedUser,
								   aip.CreatedDate,
								   aip.LastModByUserId,
								   aip.LastModDateTime
							INTO tmp_ActionItemPropDCXRef
							FROM ActionItemPropDCXRef aip
							JOIN Temp_ListDomain tmp
							ON aip.DomainCatalogId = tmp.DomainCatalogId'

				EXECUTE (@SQL)

				-- Drop foreign keys referencing the ActionItemPropDCXRef table
				SELECT @SQL = STUFF(
						(SELECT '  ALTER TABLE ' + OBJECT_NAME(parent_object_id) 
							+ ' DROP CONSTRAINT ' + name, CHAR(10)
						FROM sys.foreign_keys
						WHERE OBJECT_NAME(referenced_object_id) = 'ActionItemPropDCXRef'
						ORDER BY name
						FOR XML PATH(N''), TYPE
						).value(N'.[1]', N'nvarchar(max)'), 1, 2, N''
				)

				EXECUTE(@SQL)

				-- Save the ActionItemPropDCXRef table
				SELECT * INTO ActionItemPropDCXRef_BKP FROM ActionItemPropDCXRef

				IF OBJECT_ID('ActionItemPropDCXRef', 'U') IS NOT NULL
				BEGIN
					DROP TABLE ActionItemPropDCXRef
				END

				-- Recreate the ActionItemPropDCXRef table
				IF OBJECT_ID('ActionItemPropDCXRef', 'U') IS NULL
				BEGIN
					SELECT * INTO ActionItemPropDCXRef
					FROM tmp_ActionItemPropDCXRef
					ORDER BY 1

					ALTER TABLE [dbo].[ActionItemPropDCXRef] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]
					ALTER TABLE [dbo].[ActionItemPropDCXRef] ADD  DEFAULT (getdate()) FOR [CreatedDate]
					ALTER TABLE [dbo].[ActionItemPropDCXRef] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]
					ALTER TABLE [dbo].[ActionItemPropDCXRef] ADD  DEFAULT (getdate()) FOR [LastModDateTime]
				END

				-- Recreate update trigger on ActionItemPropDCXRef
				IF OBJECT_ID ('tu_ActionItemPropDCXRef', 'TR') IS NULL 
				BEGIN
					SET @SQL = 'CREATE TRIGGER [dbo].[tu_ActionItemPropDCXRef] ON [dbo].[ActionItemPropDCXRef] FOR UPDATE AS 
					IF EXISTS(SELECT * FROM DELETED)
					BEGIN
						UPDATE dbo.ActionItemPropDCXRef
						SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
				 		FROM dbo.ActionItemPropDCXRef as t, DELETED as d
						WHERE t.ActionItemPropertyId=d.ActionItemPropertyId;
					END'

					EXECUTE sp_executesql @SQL
				END

				-- Recreate Foreign key referencing the ActionItemProperty table
				IF NOT EXISTS (SELECT 1 FROM sys.foreign_key_columns WHERE OBJECT_NAME(parent_object_id) = 'ActionItemPropDCXRef'
								AND OBJECT_NAME(referenced_object_id) = 'ActionItemProperty')
				BEGIN
					ALTER TABLE ActionItemPropDCXRef ADD CONSTRAINT FK_AtnItmPropDCXRef_AtnItmPrp 
					FOREIGN KEY (ActionItemPropertyId) REFERENCES ActionItemProperty (Id)
				END

			END
			
			-- Rename New_Id column if it exists 
			IF COL_LENGTH('RememberedListDomainValues', 'New_Id') IS NOT NULL
			BEGIN
				EXEC sp_rename 'RememberedListDomainValues.New_Id', 'ListDomainID'
			END

			--------------- Check count for ActionItemPropDCXRef, RememberedListDomainValues,  CategoryDataListDomainXRef -------------

			SET @SQL = NULL

			SELECT @SQL = COALESCE(@SQL + ' + ', '' ) + '((SELECT COUNT(*) FROM ' + name + ') - (SELECT COUNT(*) FROM ' + name + '_BKP))'
			FROM sys.tables  WHERE name IN ('ActionItemPropDCXRef', 'RememberedListDomainValues', 'CategoryDataListDomainXRef')

			SET @SQL = 'SELECT @Result = ' + @SQL

			EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @flag OUTPUT

			IF @flag <> 0
			BEGIN

				PRINT @SQL
				SET @SQL = NULL;
				SET @ErrorMessage =  N'Some data is missing or had been added to the modified ActionItemPropDCXRef, RememberedListDomainValues or CategoryDataListDomainXRef tables' + CHAR(10);
				THROW 51001, @ErrorMessage, 1;
			END
	
			---- Check that LD table schema and tables names are added to RememberedListDomainValues, ActionItemPropDCXRef, CategoryDataListDomainXRef ---

			SELECT @Count = COUNT(*)
			FROM INFORMATION_SCHEMA.tables WHERE table_name IN ('RememberedListDomainValues', 'ActionItemPropDCXRef', 'CategoryDataListDomainXRef')
			
			SELECT @flag = COUNT(*)/(SELECT COUNT(*) FROM INFORMATION_SCHEMA.tables WHERE table_name IN ('RememberedListDomainValues', 'ActionItemPropDCXRef', 'CategoryDataListDomainXRef')) 
			FROM INFORMATION_SCHEMA.columns 
			WHERE table_name IN  ('RememberedListDomainValues', 'ActionItemPropDCXRef', 'CategoryDataListDomainXRef')
			AND column_name IN ('ListDomainTableSchema', 'LIstDomainTableName', 'ListDomainID')

			IF @flag < 2
			BEGIN
				SELECT * FROM INFORMATION_SCHEMA.columns WHERE table_name IN ('RememberedListDomainValues', 'ActionItemPropDCXRef', 'CategoryDataListDomainXRef')
				AND column_name IN ('ListDomainTableSchema', 'LIstDomainTableName', 'ListDomainID')
				ORDER BY table_name
				
				SET @SQL = NULL;
				SET @ErrorMessage = N'The ListDomainTableSchema, LIstDomainTableName, and/or ListDomainID are missing from ActionItemPropDCXRef, RememberedListDomainValues or CategoryDataListDomainXRef' + CHAR(10);
				THROW 51001, @ErrorMessage, 1
			END
			
			SET @SQL = NULL

			-- Delete Script table 	
			SELECT @SQL = COALESCE(@SQL, '') + 'DROP TABLE ' + table_name + CHAR(10)
			FROM INFORMATION_SCHEMA.tables 
			WHERE table_name IN ('tmp_NewDomainTableList', 'tmp_ListDomainInfo', 
			'tmp_RememberedListDomainValues', 'tmp_ActionItemPropDCXRef', 'tmp_CategoryDataListDomainXRef')

			EXECUTE (@SQL)


			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 5, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	PRINT CHAR(10) + 'Suspected Failed SQL Statement: ' + CHAR(10) + CHAR(10) + @SQL + CHAR(10)
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


-- ChangeOrientaionFieldTypeToAddDeciamalPrecisionsForDigImport.sql
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640205 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 5
		BEGIN
			-- ChangeOrientaionFieldTypeToAddDeciamalPrecisionsForDigImport.sql
			ALTER TABLE MetalLoss
			ALTER COLUMN MetalLossOrientation NUMERIC(6,3);

			ALTER TABLE MechanicalDamage
			ALTER COLUMN MechDmgOrientation NUMERIC(6,3);

			ALTER TABLE ExcavationSiteCrackAnomaly
			ALTER COLUMN ESCAOrientation NUMERIC(6,3);

			ALTER TABLE PipeSoilPotentialPipe
			ALTER COLUMN PSPPipeOrientation NUMERIC(6,3);

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 6, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640205 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 6
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 01
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650001', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 0, Updates 01'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


-- Drop ListDomain table and create Temp_ListDomain table 
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650001 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN


			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650001 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 02
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650002', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 0, Updates 02', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


-- POC_Rename_HCAType_Descr_Column.sql, Rename the RCHCAReasonType.Description column to Descr. 
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650002 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- POC_Rename_HCAType_Descr_Column.sql
			-- Rename the RCHCAReasonType.Description column to Descr. 
			IF EXISTS (
				SELECT 1
				FROM INFORMATION_SCHEMA.COLUMNS
				WHERE TABLE_NAME = 'RCHCAReasonType' AND COLUMN_NAME = 'Description'
			)
			BEGIN
				EXEC sp_rename 'RCHCAReasonType.Description', 'Descr', 'COLUMN';
			END

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650002 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 03
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650003', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 0, Updates 03', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

-- ADD CreatedDate, CreatedUser, LastModByUserId, and LastModDateTime columns
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650003 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @ColumnName NVARCHAR(100);
			DECLARE @TableName NVARCHAR(100);
			DECLARE @Schema NVARCHAR(100);
			DECLARE @ConstraintName NVARCHAR(100);
			DECLARE @SQL NVARCHAR(MAX);
			DECLARE @OldColumn NVARCHAR(100);

			---------------------------------- ADD MISSING COLUMNS --------------------------------------

			DECLARE AddColumnList CURSOR FOR
			SELECT table_schema, table_name
			FROM INFORMATION_SCHEMA.columns  
			WHERE (column_name LIKE 'Create%' OR column_name LIKE 'LastMod%')
			AND column_name NOT IN ('CreatedDate', 'CreatedUser', 'LastModDateTime', 'LastModByUserId')

			OPEN AddColumnList
			FETCH NEXT FROM AddColumnList INTO @Schema, @TableName

			WHILE @@FETCH_STATUS = 0 
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName AND Column_name ='CreatedDate')
				BEGIN
					SET @SQL = 'ALTER TABLE ' + QUOTENAME(@Schema) + '.' + QUOTENAME(@TableName) + ' ADD CreatedDate DATETIME DEFAULT GETDATE() NOT NULL'
					EXECUTE (@SQL)
				END

				IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName AND Column_name = 'LastModDateTime')
				BEGIN
					SET @SQL = 'ALTER TABLE ' + QUOTENAME(@Schema) + '.' + QUOTENAME(@TableName) + ' ADD LastModDateTime DATETIME DEFAULT GETDATE() NOT NULL'
					EXECUTE (@SQL)
				END

				IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName AND Column_name = 'CreatedUser')
				BEGIN
					SET @SQL = 'ALTER TABLE ' + QUOTENAME(@Schema) + '.' + QUOTENAME(@TableName) + ' ADD CreatedUser NVARCHAR(45) DEFAULT SUSER_SNAME() NOT NULL'					
					EXECUTE (@SQL)
				END

				IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName AND Column_name = 'LastModByUserId')
				BEGIN
					SET @SQL = 'ALTER TABLE ' + QUOTENAME(@Schema) + '.' + QUOTENAME(@TableName) + ' ADD LastModByUserId NVARCHAR(45) DEFAULT SUSER_SNAME() NOT NULL'
					EXECUTE (@SQL)
				END

				---------------------------------- Populate new columns with data from old column ------------------------------------------------

				IF (SELECT COUNT(*) FROM INFORMATION_SCHEMA.columns WHERE column_name LIKE 'Create%Date%' AND table_name = @TableName AND table_name NOT LIKE 'PreETL%') > 1
				BEGIN
					SELECT TOP 1 @OldColumn = column_name FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName
					AND column_name <> 'CreatedDate' AND column_name LIKE 'Create%' AND column_name LIKE '%date%'

					SET @SQL = 'UPDATE ' + @TableName + ' SET CreatedDate = ' + @OldColumn
					EXECUTE (@SQL)

				END

				IF (SELECT COUNT(*) FROM INFORMATION_SCHEMA.columns WHERE column_name LIKE 'LastMod%Date%' AND table_name = @TableName AND table_name NOT LIKE 'PreETL%') > 1
				BEGIN
					SELECT TOP 1 @OldColumn = column_name FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName
					AND column_name <> 'LastModDateTime' AND column_name LIKE 'LastMod%' AND column_name LIKE '%date%'

					SET @SQL = 'UPDATE ' + @TableName + ' SET LastModDateTime = ' + @OldColumn
					EXECUTE (@SQL)

				END
				
				IF (SELECT COUNT(*) FROM INFORMATION_SCHEMA.columns WHERE column_name LIKE 'Create%User%' AND table_name = @TableName AND table_name NOT LIKE 'PreETL%') > 1
				BEGIN
					SELECT TOP 1 @OldColumn = column_name FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName
					AND column_name <> 'CreatedUser' AND column_name LIKE 'Create%' AND column_name LIKE '%User%'

					SET @SQL = 'UPDATE ' + @TableName + ' SET CreatedUser = ' + @OldColumn
					EXECUTE (@SQL)

				END

				IF (SELECT COUNT(*) FROM INFORMATION_SCHEMA.columns WHERE column_name LIKE 'LastMod%User%' AND table_name = @TableName AND table_name NOT LIKE 'PreETL%') > 1
				BEGIN
					SELECT TOP 1 @OldColumn = column_name FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName
					AND column_name <> 'LastModByUserId' AND column_name LIKE 'LastMod%' AND column_name LIKE '%User%'

					SET @SQL = 'UPDATE ' + @TableName + ' SET LastModByUserId = ' + @OldColumn
					EXECUTE (@SQL)

				END

				------------------------------------------- Recreate Update Triggers on table -----------------------------------------------
				
				IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName AND column_name LIKE 'LastMod%' 
							AND column_name NOT IN ('LastModByUserId', 'LastModDateTime') AND table_name NOT LIKE 'PreETL%')
				BEGIN

					SELECT @SQL =  COALESCE (@SQL + ',', '') + (CASE WHEN column_name LIKE '%User%' THEN column_name + ' SUSER_SNAME()'
								ELSE column_name + ' GETDATE() '
						   END)
					FROM INFORMATION_SCHEMA.columns 
					WHERE table_name = @TableName AND column_name LIKE 'LastMod%'

					IF OBJECT_ID('tu_' + @TableName , 'TR') IS NOT NULL
					BEGIN
						SET @SQL = 'DROP TRIGGER tu_' + @TableName 

						EXECUTE (@SQL)

						SET @SQL = 'CREATE TRIGGER dbo.tu_' + @TableName + ' ON dbo.[' + @TableName+ '] FOR UPDATE AS 
						IF EXISTS(SELECT * FROM DELETED)
						BEGIN
							UPDATE dbo.' + @TableName + '
							SET ' + @SQL + '
							FROM dbo.' + @TableName + ' AS t, DELETED AS d
							WHERE t.Id=d.Id;
						END'

						EXECUTE (@SQL)
					END
		
				END
 
				FETCH NEXT FROM AddColumnList INTO @Schema, @TableName
			END

			CLOSE AddColumnList 
			DEALLOCATE AddColumnList
		
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650003 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 04
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650004', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 0, Updates 04', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


-- Modify defective trigger definitions and create triggers 
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650004 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @sql nvarchar(max)

			DECLARE t_cursor CURSOR FOR
				SELECT Replace(Replace(Triggerdefinition, 'Create Trigger', 'ALTER TRIGGER'), replaceText, '')  FROM (
				SELECT tt.*, 'ALTER TABLE dbo.' + o.name + ' ENABLE TRIGGER TU_' + o.name  as replaceText FROM (
				SELECT name, object_definition(object_id(name)) AS Triggerdefinition, parent_id   FROM sys.triggers t) tt
				INNER JOIN sys.objects o ON o.Object_Id = tt.parent_id
				WHERE Triggerdefinition LIKE '%enable%'
				) temp

			OPEN t_cursor

				FETCH NEXT FROM t_cursor INTO @sql

				WHILE @@FETCH_STATUS = 0
				BEGIN
					EXEC sp_executesql @sql
					FETCH NEXT FROM t_cursor INTO @sql
				END

			CLOSE t_cursor
			DEALLOCATE t_cursor
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	PRINT CHAR(10) + 'Suspected Failed SQL Statement: ' + CHAR(10) + CHAR(10) + @SQL + CHAR(10)
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650004 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 05
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650005', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 0, Updates 05', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


-- Create conversion lookup tale
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650005 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @sql nvarchar(max)

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE Table_Name = 'ConversionLookup')
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[ConversionLookup](
								[Id] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
								[TableName] [varchar](50) NOT NULL,
								[ColumnName] [varchar](50) NOT NULL,
								[FromUnit] [varchar](50) NOT NULL,
								[ToUnit] [varchar](50) NOT NULL,
								[Precision] [varchar](10) NOT NULL,
								[Scale] [varchar](10) NOT NULL,
								[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
								[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
								[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
								[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL
							)'
				EXEC sp_executesql @sql
			END

			IF object_id('tu_ConversionLookup') IS NULL
			BEGIN
				SET @sql = 'CREATE TRIGGER [dbo].[tu_ConversionLookup] ON [dbo].[ConversionLookup] FOR UPDATE AS 
							IF EXISTS(SELECT * FROM DELETED)
							BEGIN
								UPDATE dbo.ConversionLookup
								SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
								FROM dbo.ConversionLookup as t, DELETED as d
								WHERE t.Id=d.Id;
							END'
				EXEC sp_executesql @sql
			END
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	PRINT CHAR(10) + 'Suspected Failed SQL Statement: ' + CHAR(10) + CHAR(10) + @SQL + CHAR(10)
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650005 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'PipeSegment', 'PipeOutsideDiameter','Inch','Inch',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'PipeSegment' And ColumnName = 'PipeOutsideDiameter')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'PipeSegment', 'PipeWallThickness','Inch','Millimeter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'PipeSegment' And ColumnName = 'PipeWallThickness')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'PipeSegment', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'PipeSegment' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'PipeSegment', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'PipeSegment' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Area', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Area' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Area', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Area' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Bend', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Bend' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Bend', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Bend' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Bend', 'StationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Bend' And ColumnName = 'StationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Casing', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Casing' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Casing', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Casing' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Casing', 'CasingWallThickness','inch','millimeter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Casing' And ColumnName = 'CasingWallThickness')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'ClassArea', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'ClassArea' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'ClassArea', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'ClassArea' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Coating', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Coating' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Coating', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Coating' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Coupon', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Coupon' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Coupon', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Coupon' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Coupon', 'StationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Coupon' And ColumnName = 'StationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'CoverDepth', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'CoverDepth' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'CoverDepth', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'CoverDepth' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'CoverDepth', 'CoverDepth','inch','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'CoverDepth' And ColumnName = 'CoverDepth')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'CoverDepthProfile', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'CoverDepthProfile' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'CoverDepthProfile', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'CoverDepthProfile' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'CoverDepthProfile', 'CoverDepthReading','inch','meter',38,4 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'CoverDepthProfile' And ColumnName = 'CoverDepthReading')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'CoverDepthProfile', 'StationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'CoverDepthProfile' And ColumnName = 'StationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'CPSurveyRange', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'CPSurveyRange' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'CPSurveyRange', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'CPSurveyRange' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'CPSurveyReading', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'CPSurveyReading' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'CPSurveyReading', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'CPSurveyReading' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'CPSurveyReading', 'StationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'CPSurveyReading' And ColumnName = 'StationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'CPSurveyReading', 'CPSurveyReadingOn','Volt','MilliVolt',38,0 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'CPSurveyReading' And ColumnName = 'CPSurveyReadingOn')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'CPSurveyReading', 'CPSurveyReadingOff','Volt','MilliVolt',38,0 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'CPSurveyReading' And ColumnName = 'CPSurveyReadingOff')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Crossing', 'CrossingWidth','feet','meter',38,3 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Crossing' And ColumnName = 'CrossingWidth')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'CrossingLocn', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'CrossingLocn' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'CrossingLocn', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'CrossingLocn' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'CrossingLocn', 'StationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'CrossingLocn' And ColumnName = 'StationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'DamagePrevention', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'DamagePrevention' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'DamagePrevention', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'DamagePrevention' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'DesignClass', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'DesignClass' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'DesignClass', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'DesignClass' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'DistrictDivision', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'DistrictDivision' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'DistrictDivision', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'DistrictDivision' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'EarthQuakeArea', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'EarthQuakeArea' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'EarthQuakeArea', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'EarthQuakeArea' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Elbow', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Elbow' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Elbow', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Elbow' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Elbow', 'ElbowOutletGrade','PSI','Megapascal',38,0 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Elbow' And ColumnName = 'ElbowOutletGrade')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Elbow', 'ElbowInletGrade','PSI','Megapascal',38,0 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Elbow' And ColumnName = 'ElbowInletGrade')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Elbow', 'ElbowOutletWallthickness','Inch','Millimeter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Elbow' And ColumnName = 'ElbowOutletWallthickness')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Elbow', 'ElbowInletWallThickness','Inch','Millimeter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Elbow' And ColumnName = 'ElbowInletWallThickness')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'ElevationProfile', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'ElevationProfile' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'ElevationProfile', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'ElevationProfile' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'ElevationProfile', 'StationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'ElevationProfile' And ColumnName = 'StationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'ElevationProfile', 'Elevation','feet','meter',38,2 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'ElevationProfile' And ColumnName = 'Elevation')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'ExcavationSite', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'ExcavationSite' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'ExcavationSite', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'ExcavationSite' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'ExcavationSiteCrackAnomaly', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'ExcavationSiteCrackAnomaly' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'ExcavationSiteCrackAnomaly', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'ExcavationSiteCrackAnomaly' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'ExcavationSiteCrackAnomaly', 'StationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'ExcavationSiteCrackAnomaly' And ColumnName = 'StationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'ExposedPipe', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'ExposedPipe' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'ExposedPipe', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'ExposedPipe' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Extrusion', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Extrusion' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Extrusion', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Extrusion' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Flange', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Flange' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Flange', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Flange' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'FloodArea', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'FloodArea' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'FloodArea', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'FloodArea' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'GirthWeld', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'GirthWeld' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'GirthWeld', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'GirthWeld' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'GirthWeld', 'StationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'GirthWeld' And ColumnName = 'StationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'HCACFR', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'HCACFR' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'HCACFR', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'HCACFR' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'HCACFRSeg', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'HCACFRSeg' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'HCACFRSeg', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'HCACFRSeg' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'HCACFRSeg', 'RCHCACALCSEGPIR','feet','meter',38,3 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'HCACFRSeg' And ColumnName = 'RCHCACALCSEGPIR')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'HCAPipeGasConstantFactor', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'HCAPipeGasConstantFactor' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'HCAPipeGasConstantFactor', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'HCAPipeGasConstantFactor' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'HCAPipePIRBuffer', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'HCAPipePIRBuffer' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'HCAPipePIRBuffer', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'HCAPipePIRBuffer' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'HydroTestRange', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'HydroTestRange' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'HydroTestRange', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'HydroTestRange' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'HydroTestRngMinimumPressure', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'HydroTestRngMinimumPressure' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'HydroTestRngMinimumPressure', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'HydroTestRngMinimumPressure' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'HydroTestRngMinimumPressure', 'HydroTestRngMinimumPressure','PSI','Kilopascal',38,4 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'HydroTestRngMinimumPressure' And ColumnName = 'HydroTestRngMinimumPressure')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Incident', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Incident' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Incident', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Incident' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Incident', 'StationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Incident' And ColumnName = 'StationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'IncidentHistory', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'IncidentHistory' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'IncidentHistory', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'IncidentHistory' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionCrackAnomaly', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionCrackAnomaly' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionCrackAnomaly', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionCrackAnomaly' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionCrackAnomaly', 'StationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionCrackAnomaly' And ColumnName = 'StationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionCrackAnomaly', 'ILICADistanceFromGirthWeldDS','feet','meter',38,3 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionCrackAnomaly' And ColumnName = 'ILICADistanceFromGirthWeldDS')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionCrackAnomaly', 'ILICAOdometer','feet','meter',38,3 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionCrackAnomaly' And ColumnName = 'ILICAOdometer')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionCrackAnomaly', 'ILICADistanceFromGirthWeld','feet','meter',38,3 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionCrackAnomaly' And ColumnName = 'ILICADistanceFromGirthWeld')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionCrackAnomaly', 'ILICALength','inch','millimeter',38,3 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionCrackAnomaly' And ColumnName = 'ILICALength')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionCrackAnomaly', 'ILICAWidth','inch','millimeter',38,3 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionCrackAnomaly' And ColumnName = 'ILICAWidth')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionFacility', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionFacility' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionFacility', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionFacility' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionFacility', 'StationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionFacility' And ColumnName = 'StationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionFacility', 'ILIFacOdometer','feet','meter',38,3 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionFacility' And ColumnName = 'ILIFacOdometer')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionFacility', 'ILIFacDistanceFromGirthWeld','feet','meter',38,3 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionFacility' And ColumnName = 'ILIFacDistanceFromGirthWeld')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionFeature', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionFeature' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionFeature', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionFeature' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionFeature', 'StationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionFeature' And ColumnName = 'StationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionFeature', 'ILIFOdometer','feet','meter',38,3 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionFeature' And ColumnName = 'ILIFOdometer')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionFeature', 'ILIFDistanceFromGirthWeld','feet','meter',38,3 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionFeature' And ColumnName = 'ILIFDistanceFromGirthWeld')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionFeature', 'ILIFLength','inch','millimeter',38,3 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionFeature' And ColumnName = 'ILIFLength')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionFeature', 'ILIFWidth','inch','millimeter',38,3 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionFeature' And ColumnName = 'ILIFWidth')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionFeature', 'ILIFDistanceFromGirthWeldDS','feet','meter',38,3 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionFeature' And ColumnName = 'ILIFDistanceFromGirthWeldDS')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionJoint', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionJoint' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionJoint', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionJoint' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionJoint', 'StationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionJoint' And ColumnName = 'StationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionJoint', 'ILIJointGirthWeldOdometer','feet','meter',38,3 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionJoint' And ColumnName = 'ILIJointGirthWeldOdometer')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionJoint', 'ILIJointSpoolLength','feet','meter',38,3 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionJoint' And ColumnName = 'ILIJointSpoolLength')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionJoint', 'ILIJointDiameter','inch','millimeter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionJoint' And ColumnName = 'ILIJointDiameter')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionJoint', 'ILIJointWallThickness','inch','millimeter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionJoint' And ColumnName = 'ILIJointWallThickness')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionJoint', 'ILIJointGrade','PSI','Megapascal',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionJoint' And ColumnName = 'ILIJointGrade')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionNonCrsnDfct', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionNonCrsnDfct' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionNonCrsnDfct', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionNonCrsnDfct' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionNonCrsnDfct', 'StationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionNonCrsnDfct' And ColumnName = 'StationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionNonCrsnDfct', 'ILINCDOdometer','feet','meter',38,3 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionNonCrsnDfct' And ColumnName = 'ILINCDOdometer')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionNonCrsnDfct', 'ILINCDDistanceFromGirthWeld','feet','meter',38,3 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionNonCrsnDfct' And ColumnName = 'ILINCDDistanceFromGirthWeld')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionNonCrsnDfct', 'ILINCDLength','inch','millimeter',38,3 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionNonCrsnDfct' And ColumnName = 'ILINCDLength')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionNonCrsnDfct', 'ILINCDWidth','inch','millimeter',38,3 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionNonCrsnDfct' And ColumnName = 'ILINCDWidth')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionNonCrsnDfct', 'ILINCDDistanceFromGirthWeldDS','feet','meter',38,3 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionNonCrsnDfct' And ColumnName = 'ILINCDDistanceFromGirthWeldDS')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionRange', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionRange' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionRange', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionRange' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionRange', 'ILIRStartOdometer','feet','meter',38,3 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionRange' And ColumnName = 'ILIRStartOdometer')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InlineInspectionRange', 'ILIREndOdometer','feet','meter',38,3 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InlineInspectionRange' And ColumnName = 'ILIREndOdometer')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InternalCoating', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InternalCoating' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'InternalCoating', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'InternalCoating' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'IRASCustomData1', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'IRASCustomData1' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'IRASCustomData1', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'IRASCustomData1' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'IRASCustomData2', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'IRASCustomData2' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'IRASCustomData2', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'IRASCustomData2' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'IRASCustomData3', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'IRASCustomData3' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'IRASCustomData3', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'IRASCustomData3' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'IRASCustomData4', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'IRASCustomData4' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'IRASCustomData4', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'IRASCustomData4' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'IRASCustomData5', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'IRASCustomData5' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'IRASCustomData5', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'IRASCustomData5' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'IRASCustomData6', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'IRASCustomData6' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'IRASCustomData6', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'IRASCustomData6' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'IRASCustomData7', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'IRASCustomData7' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'IRASCustomData7', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'IRASCustomData7' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'IRASCustomData8', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'IRASCustomData8' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'IRASCustomData8', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'IRASCustomData8' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'IRASCustomData9', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'IRASCustomData9' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'IRASCustomData9', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'IRASCustomData9' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'IRASCustomData11', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'IRASCustomData11' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'IRASCustomData11', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'IRASCustomData11' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'JointCoating', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'JointCoating' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'JointCoating', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'JointCoating' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'LandSlideArea', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'LandSlideArea' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'LandSlideArea', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'LandSlideArea' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'LandUse', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'LandUse' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'LandUse', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'LandUse' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'MAOP', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'MAOP' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'MAOP', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'MAOP' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'MAOP', 'MaxAllowablePressure','PSI','Kilopascal',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'MAOP' And ColumnName = 'MaxAllowablePressure')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Marker', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Marker' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Marker', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Marker' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Marker', 'StationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Marker' And ColumnName = 'StationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'MetalLoss', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'MetalLoss' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'MetalLoss', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'MetalLoss' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'MetalLoss', 'StationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'MetalLoss' And ColumnName = 'StationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'MetalLoss', 'MetalLossDistanceFromGirthWeld','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'MetalLoss' And ColumnName = 'MetalLossDistanceFromGirthWeld')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'MetalLoss', 'MetalLossLength','Inch','Millimeter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'MetalLoss' And ColumnName = 'MetalLossLength')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'MetalLoss', 'MetalLossWidth','Inch','Millimeter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'MetalLoss' And ColumnName = 'MetalLossWidth')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'MLVSection', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'MLVSection' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'MLVSection', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'MLVSection' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'MOP', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'MOP' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'MOP', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'MOP' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'MOP', 'DesignPressure','PSI','Kilopascal',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'MOP' And ColumnName = 'DesignPressure')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'NodeConnection', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'NodeConnection' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'NodeConnection', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'NodeConnection' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'OperatingData', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'OperatingData' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'OperatingData', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'OperatingData' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'OperatingData', 'OperatingTemperature','Fahrenheit','Celsius',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'OperatingData' And ColumnName = 'OperatingTemperature')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Rectifier', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Rectifier' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Rectifier', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Rectifier' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Rectifier', 'StationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Rectifier' And ColumnName = 'StationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'RectifierReading', 'RctfrReadingVoltage','MilliVolt','MilliVolt',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'RectifierReading' And ColumnName = 'RctfrReadingVoltage')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Reducer', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Reducer' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Reducer', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Reducer' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Reducer', 'ReducerOutsideDiameter','inch','inch',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Reducer' And ColumnName = 'ReducerOutsideDiameter')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Reducer', 'ReducerOutletGrade','PSI','Megapascal',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Reducer' And ColumnName = 'ReducerOutletGrade')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Reducer', 'ReducerInletGrade','PSI','Megapascal',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Reducer' And ColumnName = 'ReducerInletGrade')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Reducer', 'ReducerOutletWallthickness','Inch','Millimeter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Reducer' And ColumnName = 'ReducerOutletWallthickness')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Reducer', 'ReducerInletWallThickness','Inch','Millimeter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Reducer' And ColumnName = 'ReducerInletWallThickness')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Reducer', 'ReducerInletDiameter','inch','inch',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Reducer' And ColumnName = 'ReducerInletDiameter')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Reducer', 'ReducerOutletDiameter','inch','inch',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Reducer' And ColumnName = 'ReducerOutletDiameter')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Reducer', 'ReducerPressureRating','PSI','Megapascal',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Reducer' And ColumnName = 'ReducerPressureRating')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'RightOfWay', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'RightOfWay' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'RightOfWay', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'RightOfWay' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Sleeve', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Sleeve' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Sleeve', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Sleeve' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Sleeve', 'SleeveWallThickness','Inch','Millimeter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Sleeve' And ColumnName = 'SleeveWallThickness')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Sleeve', 'SleeveGrade','PSI','Megapascal',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Sleeve' And ColumnName = 'SleeveGrade')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'SoilArea', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'SoilArea' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'SoilArea', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'SoilArea' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'SoilLandUseArea', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'SoilLandUseArea' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'SoilLandUseArea', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'SoilLandUseArea' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'StateProvince', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'StateProvince' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'StateProvince', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'StateProvince' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'StationSeries', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'StationSeries' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'StationSeries', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'StationSeries' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Tap', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Tap' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Tap', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Tap' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Tap', 'TapOutsideDiameter','inch','inch',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Tap' And ColumnName = 'TapOutsideDiameter')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Tap', 'TapOutletGrade','PSI','Megapascal',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Tap' And ColumnName = 'TapOutletGrade')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Tap', 'TapInletGrade','PSI','Megapascal',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Tap' And ColumnName = 'TapInletGrade')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Tap', 'TapPressureRating','PSI','Megapascal',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Tap' And ColumnName = 'TapPressureRating')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Tap', 'TapOutletWallthickness','Inch','Millimeter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Tap' And ColumnName = 'TapOutletWallthickness')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Tap', 'TapInletWallThickness','Inch','Millimeter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Tap' And ColumnName = 'TapInletWallThickness')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Tap', 'TapInletDiameter','Inch','Inch',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Tap' And ColumnName = 'TapInletDiameter')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Tap', 'TapOutletDiameter','Inch','Inch',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Tap' And ColumnName = 'TapOutletDiameter')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Tee', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Tee' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Tee', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Tee' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Tee', 'TeeOutsideDiameter','Inch','Inch',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Tee' And ColumnName = 'TeeOutsideDiameter')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Tee', 'TeeInletDiameter','Inch','Inch',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Tee' And ColumnName = 'TeeInletDiameter')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Tee', 'TeeOutletDiameter','Inch','Inch',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Tee' And ColumnName = 'TeeOutletDiameter')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Tee', 'TeeOutletGrade','PSI','Megapascal',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Tee' And ColumnName = 'TeeOutletGrade')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Tee', 'TeeInletGrade','PSI','Megapascal',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Tee' And ColumnName = 'TeeInletGrade')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Tee', 'TeePressureRating','PSI','Megapascal',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Tee' And ColumnName = 'TeePressureRating')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Tee', 'TeeOutletWallthickness','Inch','Millimeter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Tee' And ColumnName = 'TeeOutletWallthickness')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Tee', 'TeeInletWallThickness','Inch','Millimeter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Tee' And ColumnName = 'TeeInletWallThickness')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'TestPostPoint', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'TestPostPoint' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'TestPostPoint', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'TestPostPoint' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'TestPostPoint', 'StationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'TestPostPoint' And ColumnName = 'StationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'TestPostPointReading', 'TestPointPotentialON','Volt','MilliVolt',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'TestPostPointReading' And ColumnName = 'TestPointPotentialON')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'TestPostPointReading', 'TestPointPotentialOFF','Volt','MilliVolt',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'TestPostPointReading' And ColumnName = 'TestPointPotentialOFF')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'TestPostPointReading', 'TestPointPotentialNatural','Volt','MilliVolt',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'TestPostPointReading' And ColumnName = 'TestPointPotentialNatural')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Valve', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Valve' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Valve', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Valve' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Valve', 'StationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Valve' And ColumnName = 'StationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Valve', 'ValveDiameter','inch','inch',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Valve' And ColumnName = 'ValveDiameter')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Vent', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Vent' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Vent', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Vent' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Vent', 'VentOutsideDiameter','inch','inch',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Vent' And ColumnName = 'VentOutsideDiameter')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Vent', 'VentInletDiameter','inch','inch',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Vent' And ColumnName = 'VentInletDiameter')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Vent', 'VentOutletDiameter','inch','inch',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Vent' And ColumnName = 'VentOutletDiameter')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Vent', 'VentOutletGrade','PSI','Megapascal',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Vent' And ColumnName = 'VentOutletGrade')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Vent', 'VentInletGrade','PSI','Megapascal',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Vent' And ColumnName = 'VentInletGrade')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Vent', 'VentPressureRating','PSI','Megapascal',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Vent' And ColumnName = 'VentPressureRating')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Vent', 'VentOutletWallthickness','inch','millimeter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Vent' And ColumnName = 'VentOutletWallthickness')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Vent', 'VentInletWallThickness','inch','millimeter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Vent' And ColumnName = 'VentInletWallThickness')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Weight', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Weight' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'Weight', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'Weight' And ColumnName = 'EndStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'VirtualTableStationing', 'BeginStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'VirtualTableStationing' And ColumnName = 'BeginStationNum')
			INSERT INTO dbo.ConversionLookup (TableName,ColumnName,FromUnit,ToUnit,Precision,Scale) SELECT 'VirtualTableStationing', 'EndStationNum','feet','meter',38,5 WHERE NOT EXISTS (SELECT * FROM ConversionLookup WHERE TableName = 'VirtualTableStationing' And ColumnName = 'EndStationNum')
			
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 2, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650005 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 06
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650006', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 0, Updates 06', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650006 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @sql nvarchar(max)

			SET @sql = 'Create function [dbo].[fn_GenerateTransfromSelectStatement]
			(
			 @tableName varchar(200)
			)
			returns varchar(max)
			AS
			BEGIN

			DECLARE @column_names varchar(max) = ''''
			DECLARE @column_name varchar(100)
			DECLARE @column_short_name varchar(100)
			DECLARE @joins varchar(max) = ''''
			DECLARE @selectStatment varchar(max) = ''''
			DECLARE @refTableCount int 
			DECLARE @refParentTableCount int 
			DECLARE @fromUnit varchar(50)
			DECLARE @toUnit varchar(50)
			DECLARE @precision varchar(10)
			DECLARE @scale varchar(10)
			DECLARE @conversionVariables varchar(max) = ''''
			DECLARE @execConversions varchar(max) = ''''
			DECLARE @tempconversionVariables varchar(max) = ''''
			DECLARE @exectempConversions varchar(max) = ''''

			-- Check whether the table is virtual table

			IF EXISTS (SELECT * FROM dbo.VirtualTable WHERE VirtualTableName = @tableName)
			BEGIN
				SET @tableName = ''VT_'' + @tableName
			END

			-- Create temp listdomain table variable
			DECLARE @ListDomain TABLE (
			FK_Name varchar(100), TableName varchar(100), ColumnName varchar(100), ReferenceTable varchar(100), ReferenceColumn varchar(100))

			Insert into @ListDomain
			SELECT FK_Name, TableName, ColumnName, ReferencedTable, ReferencedColumn 
			FROM (
			SELECT obj.name AS FK_NAME,tab1.name AS TableName, col1.name AS ColumnName,tab2.name AS ReferencedTable,col2.name AS ReferencedColumn
			FROM sys.foreign_key_columns fkc
			INNER JOIN sys.objects obj ON obj.object_id = fkc.constraint_object_id
			INNER JOIN sys.tables tab1 ON tab1.object_id = fkc.parent_object_id
			INNER JOIN sys.schemas sch ON tab1.schema_id = sch.schema_id
			INNER JOIN sys.columns col1 ON col1.column_id = parent_column_id AND col1.object_id = tab1.object_id
			INNER JOIN sys.tables tab2 ON tab2.object_id = fkc.referenced_object_id
			INNER JOIN sys.columns col2 ON col2.column_id = referenced_column_id AND col2.object_id = tab2.object_id
			) tmp
			WHERE tmp.ReferencedTable like ''LD_%''
			order by tablename

			-- Generate variables for conversion - no temperature
			DECLARE cv_cursor CURSOR FOR
				SELECT distinct FromUnit, ToUnit FROM ConversionLookup c WHERE  (FromUnit <> ''Fahrenheit'') and c.TableName = @TableName
				UNION
				SELECT distinct FromUnit, ToUnit FROM ConversionLookup c WHERE  c.TableName = ''VirtualTableStationing'' AND c.ColumnName LIKE ''%StationNum''
				AND EXISTS (SELECT * FROM dbo.VirtualTable WHERE VirtualTableName = SubString(@TableName, 4, len(@TableName)))
			OPEN cv_cursor
				FETCH NEXT FROM cv_cursor INTO @fromUnit, @toUnit

				IF @@FETCH_STATUS = 0
				BEGIN
					SET @conversionVariables = @conversionVariables + '' ''
				END

				WHILE @@FETCH_STATUS = 0
				BEGIN
					SET @conversionVariables = @conversionVariables + ''Declare @'' + @fromUnit + @toUnit + '' numeric(13,5) '' + CHAR(13)
					FETCH NEXT FROM cv_cursor INTO @fromUnit, @toUnit
				END
			CLOSE cv_cursor
			DEALLOCATE cv_cursor

			-- Generate exec conversion stored proc - no temperature
			DECLARE ec_cursor CURSOR FOR
				SELECT distinct FromUnit, ToUnit FROM ConversionLookup c WHERE  (FromUnit <> ''Fahrenheit'') and c.TableName = @tablename 
				UNION
				SELECT distinct FromUnit, ToUnit FROM ConversionLookup c WHERE  c.TableName = ''VirtualTableStationing'' AND c.ColumnName LIKE ''%StationNum''
				AND EXISTS (SELECT * FROM dbo.VirtualTable WHERE VirtualTableName = SubString(@TableName, 4, len(@TableName)))

			OPEN ec_cursor
				FETCH NEXT FROM ec_cursor INTO @fromUnit, @toUnit

				IF @@FETCH_STATUS = 0
				BEGIN
					SET @execConversions = @execConversions + '' ''
				END


				WHILE @@FETCH_STATUS = 0
				BEGIN
					SET @execConversions = @execConversions + ''EXEC sp_ConversionCheck '' + '''''''' + @fromUnit + '''''''' + '' , '' + '''''''' + @toUnit + '''''''' + '', NULL, @'' + @fromUnit + @toUnit + '' OUTPUT '' + CHAR(13)
					FETCH NEXT FROM ec_cursor INTO @fromUnit, @toUnit
				END
			CLOSE ec_cursor
			DEALLOCATE ec_cursor

			-- Generate variables for conversion - temperature
			DECLARE tcv_cursor CURSOR FOR
				SELECT ColumnName, FromUnit, ToUnit, Precision, Scale FROM ConversionLookup c WHERE  (FromUnit = ''Fahrenheit'' or FromUnit = ''Celsius'') and c.TableName = @tableName ORDER BY ColumnName

			OPEN tcv_cursor
				FETCH NEXT FROM tcv_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale

				WHILE @@FETCH_STATUS = 0
				BEGIN
					SET @tempconversionVariables =''Declare @'' + @fromUnit + @toUnit + '' numeric(13,5) , @TempOffset numeric(13,5)'' + CHAR(13)
					FETCH NEXT FROM tcv_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale
				END
			CLOSE tcv_cursor
			DEALLOCATE tcv_cursor

			-- Generate exec conversion stored proc - temperature
			DECLARE tec_cursor CURSOR FOR
				SELECT ColumnName, FromUnit, ToUnit, Precision, Scale FROM ConversionLookup c WHERE   (FromUnit = ''Fahrenheit'' or FromUnit = ''Celsius'') and c.TableName = @tableName ORDER BY ColumnName

			OPEN tec_cursor
				FETCH NEXT FROM tec_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale

				WHILE @@FETCH_STATUS = 0
				BEGIN
					SET @exectempConversions =''EXEC sp_ConversionCheck '' + '''''''' + @fromUnit + '''''''' + '' , '' + '''''''' + @toUnit + '''''''' + '', @TempOffset OUTPUT, @'' + @fromUnit + @toUnit + '' OUTPUT '' + CHAR(13)
					FETCH NEXT FROM tec_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale
				END
			CLOSE tec_cursor
			DEALLOCATE tec_cursor

			SET @column_names = ''Id = case when t.SourceId not like ''''%[^0-9]%'''' then t.SourceId else IDLookup.Id end '' + CHAR(13)
			-- Get StationSeriesId columns
			DECLARE s_cursor CURSOR FOR
				SELECT c.Column_Name FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = ''Extract_'' + @tableName
				AND c.Column_Name LIKE ''%StationSeriesId'' ORDER BY c.Column_Name

			SET @refTableCount = 1
			OPEN s_cursor
				FETCH NEXT FROM s_cursor INTO @column_name
	
				IF @@FETCH_STATUS = 0
				BEGIN
					SET @column_names = @column_names + '',''
				END

				WHILE @@FETCH_STATUS = 0
				BEGIN
					IF @column_name <> ''StationSeriesId''
					BEGIN
						SET @column_names = @column_names + ''ss'' + cast(@refTableCount AS varchar(10)) + ''.Id AS '' + @column_name + '', '' 

						SET @joins = @joins + '' LEFT JOIN StationSeries ss'' + cast(@refTableCount AS varchar(10)) + '' with (nolock) ON ss'' + cast(@refTableCount AS varchar(10)) + ''.SourceId = t.'' + @column_name + CHAR(13)
					END
					ELSE
					BEGIN
						SET @column_names = @column_names + ''ss1.Id AS '' + @column_name + '', '' 
					END

					SET @refTableCount = @refTableCount + 1

					FETCH NEXT FROM s_cursor INTO @column_name
				END

			CLOSE s_cursor
			DEALLOCATE s_cursor

			IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = @tableName AND c.Column_Name IN (''BeginStationSeriesId'',''EndStationSeriesId''))
			BEGIN
				IF right(@column_names, 1) = '',''
				BEGIN
					SET @column_names = subString(@column_names, 1, len(@column_names)-1)
				END

				SET @column_names = @column_names + 
					(SELECT Cols = STUFF((SELECT  '', '' + CASE WHEN c.Column_Name = ''BeginStationSeriesId'' THEN ''BeginStationSeriesGUID'' WHEN c.Column_Name = ''EndStationSeriesId'' THEN ''EndStationSeriesGUID'' WHEN c.Column_Name = ''StationSeriesId'' THEN ''StationSeriesGUID'' END + '' = t.'' + QUOTENAME(c.Column_Name)
					FROM INFORMATION_SCHEMA.COLUMNS c	
					WHERE table_name = @tableName
					AND c.Column_Name IN (''BeginStationSeriesId'',''EndStationSeriesId'')
					ORDER BY c.Column_Name
					FOR XML PATH('''')), 1, 2, ''''))
			END

			-- Get ListDomain columns
			DECLARE l_cursor CURSOR FOR
				SELECT c.Column_Name FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = ''Extract_'' + @tableName
				And Column_Name in (Select ColumnName from @ListDomain)
				ORDER BY c.Column_Name

			SET @refTableCount = 1
			OPEN l_cursor
				FETCH NEXT FROM l_cursor INTO @column_name

				WHILE @@FETCH_STATUS = 0
				BEGIN
					IF @column_name like ''%DomainId''
					BEGIN
						SET @column_short_name = replace(@column_name, ''DomainId'', '''')
					END
					ELSE
					BEGIN
						SET @column_short_name = CASE WHEN right(@column_name, 2) = ''ld'' then SUBSTRING(@column_name, 1, LEN(@column_name) - 2) ELSE @column_name END
					END
		
					SET @joins = @joins + '' '' + (SELECT Replace(dbo.fn_ScriptJoinLDColumn(@tableName, @column_name, '' tbl'' + cast(@refTableCount AS varchar(10))), ''.Id'', ''.Code''))+ CHAR(13)

					IF right(@column_names, 1) = '',''
					BEGIN
						SET @column_names = subString(@column_names, 1, len(@column_names)-1)
					END

					SET @column_names = @column_names + '', tbl'' + cast(@refTableCount AS varchar(10)) + ''.Id AS '' + @column_name + '', t.'' + @column_name + '' AS '' + @column_short_name + CHAR(13)
					SET @refTableCount = @refTableCount + 1

					FETCH NEXT FROM l_cursor INTO @column_name
				END

			CLOSE l_cursor
			DEALLOCATE l_cursor

			-- Get ParentColumns columns
			DECLARE p_cursor CURSOR FOR
				SELECT c.Column_Name FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = ''Extract_'' + @tableName
				And Column_Name in (select ColumnName from StageFKeysInfo where TableName= @tableName )
				And Column_Name NOT in (Select ColumnName from @ListDomain)
				AND Column_Name NOT IN (''StationSeriesId'',''BeginStationSeriesId'',''EndStationSeriesId'', ''BaseIliId'', ''Stg_ILIId'')
				ORDER BY c.Column_Name

			SET @refParentTableCount = 1
			OPEN p_cursor
				FETCH NEXT FROM p_cursor INTO @column_name

				WHILE @@FETCH_STATUS = 0
				BEGIN
					BEGIN
						SET @column_short_name = CASE WHEN right(@column_name, 2) = ''Id'' then SUBSTRING(@column_name, 1, LEN(@column_name) - 2) ELSE @column_name END
					END

					IF @column_name <> ''RCReasonTypeId''
					BEGIN
						SET @joins = @joins + '' '' + (SELECT REPLACE(dbo.fn_ScriptJoinColumn(@tableName, @column_name, '' p'' + cast(@refParentTableCount AS varchar(10))),''.Id'',''.SourceId'')) + CHAR(13)
					END
					ELSE
					BEGIN
						SET @joins = @joins + '' '' + (SELECT dbo.fn_ScriptJoinColumn(@tableName, @column_name, '' p'' + cast(@refParentTableCount AS varchar(10)))) + CHAR(13)
					END

					IF right(@column_names, 1) = '',''
					BEGIN
						SET @column_names = subString(@column_names, 1, len(@column_names)-1)
					END

					SET @column_names = @column_names + '', p'' + cast(@refParentTableCount AS varchar(10)) + ''.Id AS '' + @column_name + '', t.'' + @column_name + '' AS '' + @column_short_name + CHAR(13)
					SET @refParentTableCount = @refParentTableCount + 1

					FETCH NEXT FROM p_cursor INTO @column_name
				END

			CLOSE p_cursor
			DEALLOCATE p_cursor

			IF NOT EXISTS (SELECT * FROM dbo.VirtualTable WHERE VirtualTableName = SubString(@TableName, 4, len(@TableName)))
			BEGIN
				SET @joins = @joins + '' LEFT JOIN GUIDLookup IDLookup with (nolock)
					on IDLookup.GUID = t.SourceId
						and IDLookup.TableName = '''''' + @TableName + '''''''' + CHAR(13)
			END
			ELSE
			BEGIN
				SET @joins = @joins + '' LEFT JOIN VTGUIDLookup IDLookup with (nolock)
					on IDLookup.GUID = t.SourceId
						and IDLookup.TableName = '''''' + SubString(@TableName, 4, len(@TableName)) + '''''''' + CHAR(13)
			END

			----Get columns which required conversion -- no temperature
			DECLARE c_cursor CURSOR FOR
				SELECT * FROM (
					SELECT ColumnName, FromUnit, ToUnit, Precision, Scale FROM ConversionLookup c WHERE  (FromUnit <> ''Fahrenheit'') and c.TableName = @tableName 
					UNION
					SELECT ColumnName, FromUnit, ToUnit, Precision, Scale FROM ConversionLookup c WHERE  c.TableName = ''VirtualTableStationing'' AND c.ColumnName LIKE ''%StationNum''
					AND EXISTS (SELECT * FROM dbo.VirtualTable WHERE VirtualTableName = SubString(@TableName, 4, len(@TableName)))
				) tmp
				ORDER BY ColumnName

			OPEN c_cursor
				FETCH NEXT FROM c_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale

				WHILE @@FETCH_STATUS = 0
				BEGIN
					IF right(@column_names, 1) = '',''
					BEGIN
						SET @column_names = subString(@column_names, 1, len(@column_names)-1)
					END
					ELSE IF right(@column_names, 2) = '', ''
					BEGIN
						SET @column_names = subString(@column_names, 1, len(@column_names)-2)
					END

					IF @column_name <> ''StationNum''
					BEGIN
						SET @column_names = @column_names + '', ''  + @column_name + '' = cast(t.'' + @column_name + '' * @'' + @fromUnit + @toUnit + '' as numeric('' + @precision + '','' + @scale + ''))'' + CHAR(13)
					END
					ELSE
					BEGIN
						SET @column_names = @column_names + '', ''  + @column_name + '' = cast(t.BeginStationNum * @'' + @fromUnit + @toUnit + '' as numeric('' + @precision + '','' + @scale + ''))'' + CHAR(13)
					END

					FETCH NEXT FROM c_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale
				END
			CLOSE c_cursor
			DEALLOCATE c_cursor

			----Get columns which required conversion -- temperature

			DECLARE ct_cursor CURSOR FOR
				SELECT ColumnName, FromUnit, ToUnit, Precision, Scale FROM ConversionLookup c WHERE  (FromUnit = ''Fahrenheit'' or FromUnit = ''Celsius'') and c.TableName = @tableName ORDER BY ColumnName

			OPEN ct_cursor
				FETCH NEXT FROM ct_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale

				WHILE @@FETCH_STATUS = 0
				BEGIN
					IF right(@column_names, 1) = '',''
					BEGIN
						SET @column_names = subString(@column_names, 1, len(@column_names)-1)
					END

					SET @column_names = @column_names + '', '' + @column_name + '' = cast((t.'' + @column_name + '' + @TempOffset) * @'' + @fromUnit + @toUnit + '' as numeric('' + @precision + '','' + @scale + ''))'' + CHAR(13)
					FETCH NEXT FROM ct_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale
				END
			CLOSE ct_cursor
			DEALLOCATE ct_cursor

			------ Get all other columns

			IF right(@column_names, 1) = '',''
			BEGIN
				SET @column_names = subString(@column_names, 1, len(@column_names)-1)
			END

			SET @column_names = @column_names + '','' +
			(SELECT Cols = STUFF((SELECT  '', t.'' + QUOTENAME(c.Column_Name)
			FROM INFORMATION_SCHEMA.Columns c 
			LEFT JOIN StageFKeysInfo sfi ON replace(c.Table_Name,''Extract_'','''') = sfi.TableName AND c.Column_Name = sfi.ColumnName
			Where c.Table_Name = ''Extract_'' + @tableName
			AND c.Column_Name NOT in (Select ColumnName from @ListDomain)
			And sfi.ColumnName IS NULL
			AND c.Column_Name NOT IN (''StationSeriesId'',''BeginStationSeriesId'',''EndStationSeriesId'',''LastModByUserId'', ''LastModDateTime'', ''CreatedDate'', ''CreatedUser'', ''SourceId'', ''Id'', ''BeginStationSeriesGUID'', ''EndStationSeriesGUID'')
			AND c.Column_Name NOT LIKE ''%StationNum''
			AND c.Column_Name NOT IN (SELECT ColumnName FROM ConversionLookup c WHERE c.TableName = @tableName)
			ORDER BY c.Column_Name
			FOR XML PATH('''')), 1, 2, ''''))

			IF right(@column_names, 1) = '',''
			BEGIN
				SET @column_names = subString(@column_names, 1, len(@column_names)-1)
			END

			SET @column_names = @column_names + CHAR(13) +  '',[LastModDateTime] = getdate() 
			,[LastModByUserId] = SUSER_SNAME() 
			,t.[SourceId]
			,[CreatedDate] = getdate()  
			,[CreatedUser] = SUSER_SNAME() 
			,t.[CheckSumValue]''

			SET @selectStatment =  @conversionVariables + @tempconversionVariables + @execConversions + @exectempConversions +  ''SELECT '' + @column_names + '' from (select * , BINARY_CHECKSUM(*) CheckSumValue from Extract_'' + @tableName + '' with (nolock)) as t ''+ CHAR(13) + @joins

			RETURN @selectStatment
			END'
			EXEC sp_executesql @sql
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650006 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 07
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650007', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 0, Updates 07', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650007 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @sql nvarchar(max)

			IF object_id('fn_ScriptJoinColumn') IS NULL
			BEGIN
				SET @sql = 'CREATE function [dbo].[fn_ScriptJoinColumn]
							(
								@tableName varchar(200), @columnName varchar(200), @tableAlias varchar(10) = ''ref''
							)
							returns varchar(max)
							as
							BEGIN
								DECLARE @sql varchar(max)

								SET @sql = (SELECT joinStatement = STUFF(
								(SELECT '' LEFT JOIN '' + tmp.ReferencedTable + '' '' + @tableAlias 
								+ case when @tableAlias <> ''ref'' THEN '''' ELSE cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10)) END + '' with (nolock) ON '' + @tableAlias 
								+ case when @tableAlias <> ''ref'' THEN '''' ELSE cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10)) END
								+ ''.'' + tmp.ReferencedColumn + '' = t.'' + tmp.ColumnName 
								FROM (
								SELECT FK_NAME,TableName,ColumnName,ReferencedTable,ReferencedColumn
								FROM StageFkeysInfo
								) tmp
								WHERE tmp.TableName = @tableName AND tmp.ColumnName = @columnName
								order by TableName
								FOR XML PATH('''')), 1, 1, '''') )

								RETURN @sql
							END'
				EXEC sp_executesql @sql
			END

			IF object_id('fn_ScriptJoinLDColumn') IS NULL
			BEGIN
				SET @sql = 'CREATE function [dbo].[fn_ScriptJoinLDColumn]
							(
								@tableName varchar(200), @columnName varchar(200), @tableAlias varchar(10) = ''ref''
							)
							returns varchar(max)
							as
							BEGIN
								DECLARE @sql varchar(max)

								SET @sql = (SELECT joinStatement = STUFF(
								(SELECT '' LEFT JOIN (SELECT Min(Id) AS Id, Upper(Code) AS Code FROM '' + tmp.ReferencedTable + '' with (nolock) GROUP BY Code) '' + @tableAlias
								+ case when @tableAlias <> ''ref'' THEN '''' ELSE cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10)) END  + '' ON '' + @tableAlias 
								+ case when @tableAlias <> ''ref'' THEN '''' ELSE cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10)) END
								+ ''.'' + tmp.ReferencedColumn + '' = t.'' + tmp.ColumnName		
								FROM (
								SELECT obj.name AS FK_NAME,tab1.name AS TableName, col1.name AS ColumnName,tab2.name AS ReferencedTable,col2.name AS ReferencedColumn
								FROM sys.foreign_key_columns fkc
								INNER JOIN sys.objects obj ON obj.object_id = fkc.constraint_object_id
								INNER JOIN sys.tables tab1 ON tab1.object_id = fkc.parent_object_id
								INNER JOIN sys.schemas sch ON tab1.schema_id = sch.schema_id
								INNER JOIN sys.columns col1 ON col1.column_id = parent_column_id AND col1.object_id = tab1.object_id
								INNER JOIN sys.tables tab2 ON tab2.object_id = fkc.referenced_object_id
								INNER JOIN sys.columns col2 ON col2.column_id = referenced_column_id AND col2.object_id = tab2.object_id
								) tmp
								WHERE tmp.TableName = @tableName AND tmp.ColumnName = @columnName
								FOR XML PATH('''')), 1, 1, '''') )

								RETURN @sql
							END'
				EXEC sp_executesql @sql
			END

			IF object_id('fn_ScriptJoinReferenceTable') IS NULL
			BEGIN
				SET @sql = 'CREATE function [dbo].[fn_ScriptJoinReferenceTable]
							(
								@tableName varchar(200), @referenceTable varchar(200)
							)
							returns varchar(max)
							as
							BEGIN
								DECLARE @sql varchar(max)

								SET @sql = (SELECT joinStatement = STUFF(
								(SELECT '' LEFT JOIN '' + tmp.ReferencedTable + '' ref'' + cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10)) + '' ON ref'' + cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10))
								+ ''.'' + tmp.ReferencedColumn + '' = t.'' + tmp.ColumnName 
								FROM (
								SELECT obj.name AS FK_NAME,tab1.name AS TableName, col1.name AS ColumnName,tab2.name AS ReferencedTable,col2.name AS ReferencedColumn
								FROM sys.foreign_key_columns fkc
								INNER JOIN sys.objects obj ON obj.object_id = fkc.constraint_object_id
								INNER JOIN sys.tables tab1 ON tab1.object_id = fkc.parent_object_id
								INNER JOIN sys.schemas sch ON tab1.schema_id = sch.schema_id
								INNER JOIN sys.columns col1 ON col1.column_id = parent_column_id AND col1.object_id = tab1.object_id
								INNER JOIN sys.tables tab2 ON tab2.object_id = fkc.referenced_object_id
								INNER JOIN sys.columns col2 ON col2.column_id = referenced_column_id AND col2.object_id = tab2.object_id
								) tmp
								WHERE tmp.TableName = @tableName AND tmp.ReferencedTable = @referenceTable
								FOR XML PATH('''')), 1, 1, '''') )

								RETURN @sql
							END'
				EXEC sp_executesql @sql
			END

			IF object_id('fn_ScriptJoins') IS NULL
			BEGIN
				SET @sql = 'CREATE function [dbo].[fn_ScriptJoins]
							(
								@tableName varchar(200), @withStationSeries int
							)
							returns varchar(max)
							as
							BEGIN
								DECLARE @sql varchar(max)
								IF @withStationSeries = 1
								BEGIN
									SET @sql = (SELECT joinStatement = STUFF(
									(SELECT '' LEFT JOIN '' + tmp.ReferencedTable + '' ref'' + cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10)) + '' ON ref'' + cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10))
									+ ''.'' + tmp.ReferencedColumn + '' = t.'' + tmp.ColumnName 
									FROM (
									SELECT obj.name AS FK_NAME,tab1.name AS TableName, col1.name AS ColumnName,tab2.name AS ReferencedTable,col2.name AS ReferencedColumn
									FROM sys.foreign_key_columns fkc
									INNER JOIN sys.objects obj ON obj.object_id = fkc.constraint_object_id
									INNER JOIN sys.tables tab1 ON tab1.object_id = fkc.parent_object_id
									INNER JOIN sys.schemas sch ON tab1.schema_id = sch.schema_id
									INNER JOIN sys.columns col1 ON col1.column_id = parent_column_id AND col1.object_id = tab1.object_id
									INNER JOIN sys.tables tab2 ON tab2.object_id = fkc.referenced_object_id
									INNER JOIN sys.columns col2 ON col2.column_id = referenced_column_id AND col2.object_id = tab2.object_id
									) tmp
									WHERE tmp.TableName = @tableName AND tmp.ReferencedTable = ''StationSeries''
									FOR XML PATH('''')), 1, 1, '''') )
								END
								ELSE
								BEGIN
									SET @sql = (SELECT joinStatement = STUFF(
									(SELECT '' LEFT JOIN '' + tmp.ReferencedTable + '' ref'' + cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10)) + '' ON ref'' + cast(Row_Number() OVER (ORDER BY tmp.ColumnName) AS varchar(10))
									+ ''.'' + tmp.ReferencedColumn + '' = t.'' + tmp.ColumnName 
									FROM (
									SELECT obj.name AS FK_NAME,tab1.name AS TableName, col1.name AS ColumnName,tab2.name AS ReferencedTable,col2.name AS ReferencedColumn
									FROM sys.foreign_key_columns fkc
									INNER JOIN sys.objects obj ON obj.object_id = fkc.constraint_object_id
									INNER JOIN sys.tables tab1 ON tab1.object_id = fkc.parent_object_id
									INNER JOIN sys.schemas sch ON tab1.schema_id = sch.schema_id
									INNER JOIN sys.columns col1 ON col1.column_id = parent_column_id AND col1.object_id = tab1.object_id
									INNER JOIN sys.tables tab2 ON tab2.object_id = fkc.referenced_object_id
									INNER JOIN sys.columns col2 ON col2.column_id = referenced_column_id AND col2.object_id = tab2.object_id
									) tmp
									WHERE tmp.TableName = @tableName AND tmp.ReferencedTable <> ''StationSeries'' 
									FOR XML PATH('''')), 1, 1, '''') )
								END

								RETURN @sql
							END'
				EXEC sp_executesql @sql
			END
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650007 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 08
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650008', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 0, Updates 08', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650008 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @sql nvarchar(max)

			SET @sql = 'ALTER PROCEDURE [dbo].[sp_InsertNewListDomains]
						(@tableName              VARCHAR(250), 
						 @domainCatalogTableName VARCHAR(250) = NULL, 
						 @isVirtualTable         BIT          = 0
						)
						AS
							BEGIN
								IF @domainCatalogTableName IS NULL
									BEGIN
										SET @domainCatalogTableName = @tableName;
									END;
								DECLARE @TrimSQL AS NVARCHAR(MAX)= '''';
								IF @isVirtualTable = 0
									BEGIN
										SELECT @TrimSQL = ''update  extract_'' + @tableName + '' set  '' + STUFF(
										(
											SELECT '','' + tmp.ColumnName + '' = left( '' + tmp.ColumnName + '' , 40)''
											FROM (
											SELECT obj.name AS FK_NAME,tab1.name AS TableName, col1.name AS ColumnName,tab2.name AS ReferencedTable,col2.name AS ReferencedColumn
											FROM sys.foreign_key_columns fkc
											INNER JOIN sys.objects obj ON obj.object_id = fkc.constraint_object_id
											INNER JOIN sys.tables tab1 ON tab1.object_id = fkc.parent_object_id
											INNER JOIN sys.schemas sch ON tab1.schema_id = sch.schema_id
											INNER JOIN sys.columns col1 ON col1.column_id = parent_column_id AND col1.object_id = tab1.object_id
											INNER JOIN sys.tables tab2 ON tab2.object_id = fkc.referenced_object_id
											INNER JOIN sys.columns col2 ON col2.column_id = referenced_column_id AND col2.object_id = tab2.object_id
											) tmp
											WHERE tmp.ReferencedTable LIKE ''LD[_]%'' AND tmp.TableName = @tableName
										FOR XML PATH(''''), TYPE
										).value(''.'', ''NVARCHAR(MAX)''), 1, 1, '''');
									END;
									ELSE
									BEGIN
										SELECT @TrimSQL = ''update  Extract_Vt_'' + @tableName + '' set DataFieldValueDomainId = left( DataFieldValueDomainId , 40)'';
									END;
								PRINT @TrimSQL;
								EXEC (@TrimSQL);
        
								DECLARE @sql NVARCHAR(MAX)
								DECLARE i_cursor CURSOR FOR
									SELECT ''INSERT INTO '' + tmp.ReferencedTable + ''(Code, Descr) Select '' + tmp.ColumnName + '','' + tmp.ColumnName + '' FROM Extract_'' 
									+ tmp.TableName + '' WHERE '' + tmp.ColumnName + '' NOT IN (SELECT CODE FROM '' + tmp.ReferencedTable + '') AND '' + tmp.ColumnName + '' IS NOT NULL'' 
									FROM (
									SELECT obj.name AS FK_NAME,tab1.name AS TableName, col1.name AS ColumnName,tab2.name AS ReferencedTable,col2.name AS ReferencedColumn
									FROM sys.foreign_key_columns fkc
									INNER JOIN sys.objects obj ON obj.object_id = fkc.constraint_object_id
									INNER JOIN sys.tables tab1 ON tab1.object_id = fkc.parent_object_id
									INNER JOIN sys.schemas sch ON tab1.schema_id = sch.schema_id
									INNER JOIN sys.columns col1 ON col1.column_id = parent_column_id AND col1.object_id = tab1.object_id
									INNER JOIN sys.tables tab2 ON tab2.object_id = fkc.referenced_object_id
									INNER JOIN sys.columns col2 ON col2.column_id = referenced_column_id AND col2.object_id = tab2.object_id
									) tmp
									WHERE tmp.ReferencedTable LIKE ''LD[_]%'' AND tmp.TableName = @tableName
		
								OPEN i_cursor
									FETCH NEXT FROM i_cursor INTO @sql

									WHILE @@FETCH_STATUS = 0
									BEGIN
										PRINT @sql;
										EXEC (@sql);
				
										FETCH NEXT FROM i_cursor INTO @sql
									END

								CLOSE i_cursor
								DEALLOCATE i_cursor
							END;'
			EXEC sp_executesql @sql
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650008 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 09
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650009', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 0, Updates 09', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650009 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @sql nvarchar(max)

			SET @sql = 'ALTER PROCEDURE [dbo].[sp_BuildCentreline] AS
						BEGIN

						CREATE TABLE #StationSeriesWorker
						  (
							 OrdId               NUMERIC(10, 0) IDENTITY,
							 StationSeriesId     VARCHAR(50) NOT NULL,
							 SeriesValueNumber   VARCHAR(100) NOT NULL,
							 LineLoopId          VARCHAR(50) NOT NULL,
							 BeginStationNum     NUMERIC(13, 5) NOT NULL,
							 EndStationNum       NUMERIC(13, 5) NOT NULL,
							 Ascending           INT NOT NULL,
							 PrevStationSeriesId VARCHAR(50),
							 PrevStationNum      NUMERIC(13, 5),
							 PrevAscending       INT,
							 Equation            NUMERIC(13, 5),
							 BegChainage         NUMERIC(13, 5),
							 EndChainage         NUMERIC(13, 5)
						  )

						CREATE TABLE #Equations
						  (
							 LineLoopId      VARCHAR(50) NOT NULL,
							 StationSeriesId VARCHAR(50) NOT NULL,
							 Equation        NUMERIC(13, 5)
						  ) 

						-- load #StationSeriesWorker variable table and calculate equations to the start of the route
						INSERT INTO #StationSeriesWorker
									(StationSeriesId,
									 SeriesValueNumber,
									 LineLoopId,
									 BeginStationNum,
									 EndStationNum,
									 Ascending)
						SELECT Id,
							   REPLICATE(''0'', 10 - LEN(LineLoopId))+
						LTRIM(STR(LineLoopId))+
						REPLICATE(''0'', 10 - LEN(SeriesValueNumber))+LTRIM(STR(CAST(SeriesValueNumber AS INTEGER))) AS SeriesValueNumber,
							   LineLoopId,
							   BeginStationNum,
							   EndStationNum,
							   Ascending = CASE
											 WHEN EndStationNum - BeginStationNum >= 0 THEN 1
											 ELSE -1
										   END
						FROM   StationSeries
						WHERE  EffectiveEndDate IS NULL
						ORDER  BY LineLoopId,REPLICATE(''0'', 10 - LEN(LineLoopId))+
						LTRIM(STR(LineLoopId))+
						REPLICATE(''0'', 10 - LEN(SeriesValueNumber))+LTRIM(STR(CAST(SeriesValueNumber AS INTEGER))) 

						UPDATE #StationSeriesWorker
						SET    PrevStationSeriesId = cc.ss,
							   PrevStationNum = cc.stn,
							   PrevAscending = cc.mult
						FROM   ( SELECT NEXT.OrdId           AS ordered,
										prev.StationSeriesId AS SS,
										prev.EndStationNum   AS stn,
										prev.Ascending       AS mult
								 FROM   #StationSeriesWorker prev
										INNER JOIN #StationSeriesWorker NEXT
												ON prev.LineLoopId = NEXT.LineLoopId AND
												   prev.OrdId + 1 = NEXT.OrdId ) cc,
							   #StationSeriesWorker T
						WHERE  T.OrdId = cc.ordered

						UPDATE #StationSeriesWorker
						SET    Equation = -BeginStationNum * Ascending
						WHERE  PrevStationSeriesId IS NULL 

						--  calculate equations
						INSERT INTO #Equations
						SELECT LineLoopId,
							   sso.StationSeriesId,
							   ( SELECT SUM( eq )
								 FROM   #StationSeriesWorker ss_l,
										( SELECT LineLoopId,
												 SeriesValueNumber,
												 Isnull( sc.PrevStationNum * PrevAscending - sc.BeginStationNum * Ascending, equation ) AS eq
										  FROM   #StationSeriesWorker sc ) ssq
								 WHERE  ss_l.LineLoopId = ssq.LineLoopId AND
										( Cast( Substring( Cast( ssq.SeriesValueNumber AS VARCHAR(55)), ( Charindex(''_'', ssq.SeriesValueNumber) + 1 ), ( Len( ssq.SeriesValueNumber ) - Charindex( ''_'', ssq.SeriesValueNumber ) ) ) AS NUMERIC(20, 0)) ) <= ( Cast( Substring( Cast( ss_l.SeriesValueNumber AS VARCHAR(55)), ( Charindex(''_'', ss_l.SeriesValueNumber) + 1 ), ( Len( ss_l.SeriesValueNumber ) - Charindex( ''_'', ss_l.SeriesValueNumber ) ) ) AS NUMERIC(20, 0)) ) AND
										ss_l.StationSeriesId = sso.StationSeriesId
								 GROUP  BY ssq.LineLoopId ) AS Equation
						FROM   #StationSeriesWorker sso 

						-- update equations in #StationSeriesWorker
						UPDATE #StationSeriesWorker
						SET    #StationSeriesWorker.Equation = v.Equation,
							   BegChainage = t.BeginStationNum * t.Ascending + v.Equation,
							   EndChainage = t.EndStationNum * t.Ascending + v.Equation
						FROM   #StationSeriesWorker t,
							   #Equations v
						WHERE  t.StationSeriesId = v.StationSeriesId 

						--LOAD SERIES CONNECTION
						DELETE FROM SeriesConnection

						INSERT INTO SeriesConnection
									(Id,
									 PrevStationSeriesId,
									 NextStationSeriesId,
									 PrevStationNum,
									 NextStationNum)
						SELECT OrdId,
							   PrevStationSeriesId,
							   StationSeriesId,
							   PrevStationNum,
							   BeginStationNum
						FROM   #StationSeriesWorker w
						WHERE  PrevStationSeriesId IS NOT NULL 

						-- Load MLV Correction
						DELETE FROM MLVCorrection

						INSERT INTO MLVCorrection
									(Id,
									 EffectiveStartDate,
									 MultiplierNum,
									 FactorNum,
									 MLVSectionId,
									 StationSeriesId,
									 BeginStationNum,
									 EndStationNum)
						SELECT OrdId,
							   EffectiveStartDate,
							   w.Ascending,
							   w.Equation,
							   w.StationSeriesId,
							   w.StationSeriesId,
							   w.BeginStationNum,
							   w.EndStationNum
						FROM   #StationSeriesWorker w
							   INNER JOIN StationSeries s
									   ON w.StationSeriesId = s.Id
							   INNER JOIN Lineloop l
									   ON S.LineloopId = l.Id 

						DROP TABLE #StationSeriesWorker

						DROP TABLE #Equations 

						IF EXISTS (SELECT * FROM dbo.MLVSection WHERE BeginStationSeriesId IS NOT NULL AND EndStationSeriesId IS NOT NULL) 
						BEGIN	

						--Temp tables
						IF OBJECT_ID(''tempdb..#temp_MLVSection'') IS NOT NULL
						BEGIN
							DROP TABLE #temp_MLVSection
						END

						CREATE TABLE #temp_MLVSection
						(
						[Id] [numeric](10, 0) NULL,
						[MLVSectionName] [varchar](70) NULL,
						[UpstreamCompressorName] [varchar](100) NULL,
						[DownstreamCompressorName] [varchar](100) NULL,
						[ValveSectionNumberDomainId] [numeric](7, 0) NULL,
						[BeginStationSeriesId] [numeric](10, 0) NULL,
						[BeginStationNum] [numeric](13, 5) NULL,
						[EndStationSeriesId] [numeric](10, 0) NULL,
						[EndStationNum] [numeric](13, 5) NULL,
						[SourceId] [varchar](50) NULL,
						[LLId] [numeric](10, 0) NULL,
						[BeginChainage] [numeric](13, 5) NULL,
						[EndChainage] [numeric](13, 5) NULL
						)

						IF OBJECT_ID(''tempdb..#temp_MLVCorrection'') IS NOT NULL
						BEGIN
							DROP TABLE #temp_MLVCorrection
						END

						CREATE TABLE #temp_MLVCorrection
						(
						[Id] [numeric](10, 0) NULL,
						[EffectiveStartDate] [datetime] NULL,
						[EffectiveEndDate] [datetime] NULL,
						[MultiplierNum] [numeric](5, 3) NULL,
						[FactorNum] [numeric](13, 5) NULL,
						[MLVSectionId] [numeric](10, 0) NULL,
						[StateProvinceDomainId] [numeric](7, 0) NULL,
						[DistrictDivisionDomainId] [numeric](7, 0) NULL,
						[AreaDomainId] [numeric](7, 0) NULL,
						[StationSeriesId] [numeric](10, 0) NULL,
						[BeginStationNum] [numeric](13, 5) NULL,
						[EndStationNum] [numeric](13, 5) NULL,
						[SourceId] [varchar](50) NULL,
						[LLId] [numeric](10, 0) NULL,
						[BeginChainage] [numeric](13, 5) NULL,
						[EndChainage] [numeric](13, 5) NULL
						)

						INSERT INTO #temp_MLVSection
								( Id ,
								  MLVSectionName ,
								  UpstreamCompressorName ,
								  DownstreamCompressorName ,
								  ValveSectionNumberDomainId ,
								  BeginStationSeriesId ,
								  BeginStationNum ,
								  EndStationSeriesId ,
								  EndStationNum ,
								  SourceId 
								)
						SELECT Id ,
								  MLVSectionName ,
								  UpstreamCompressorName ,
								  DownstreamCompressorName ,
								  ValveSectionNumberDomainId ,
								  BeginStationSeriesId ,
								  BeginStationNum ,
								  EndStationSeriesId ,
								  EndStationNum ,
								  SourceId  
						FROM dbo.MLVSection

						INSERT INTO #temp_MLVCorrection
								( Id ,
								  EffectiveStartDate ,
								  EffectiveEndDate ,
								  MultiplierNum ,
								  FactorNum ,
								  MLVSectionId ,
								  StateProvinceDomainId ,
								  DistrictDivisionDomainId ,
								  AreaDomainId ,
								  StationSeriesId ,
								  BeginStationNum ,
								  EndStationNum ,
								  SourceId 
								)
						SELECT Id ,
								  EffectiveStartDate ,
								  EffectiveEndDate ,
								  MultiplierNum ,
								  FactorNum ,
								  MLVSectionId ,
								  StateProvinceDomainId ,
								  DistrictDivisionDomainId ,
								  AreaDomainId ,
								  StationSeriesId ,
								  BeginStationNum ,
								  EndStationNum ,
								  SourceId 
						FROM dbo.MLVCorrection mc

						UPDATE ms 
						SET BeginChainage = ms.BeginStationNum * m_beg.MultiplierNum + m_beg.FactorNum, 
							EndChainage =  ms.EndStationNum * m_end.MultiplierNum + m_end.FactorNum
						FROM #temp_MLVSection ms
						INNER JOIN #temp_MLVCorrection m_beg ON m_beg.StationSeriesId = ms.BeginStationSeriesId
						INNER JOIN #temp_MLVCorrection m_end ON m_end.StationSeriesId = ms.EndStationSeriesId

						UPDATE ms
						SET LLId = ss.LineLoopId
						FROM #temp_MLVSection ms
						INNER JOIN StationSeries ss ON ss.Id = ms.BeginStationSeriesId
						WHERE ss.EffectiveEndDate IS NULL

						UPDATE mc 
						SET BeginChainage = mc.BeginStationNum * mc.MultiplierNum + mc.FactorNum,
							EndChainage = mc.EndStationNum * mc.MultiplierNum + mc.FactorNum,
							LLId = ss.LineLoopId
						FROM #temp_MLVCorrection mc
						INNER JOIN StationSeries ss ON ss.Id = mc.StationSeriesId

						--Draw Linear Lines
						IF OBJECT_ID(''tempdb..#MLVCorrectionLinear'') IS NOT NULL
						BEGIN
							DROP TABLE #MLVCorrectionLinear
						END

						CREATE TABLE #MLVCorrectionLinear
						(
						OId NUMERIC (10,0) NULL,
						LLId NUMERIC(10,0) NULL,
						Chainage NUMERIC(13,5) NULL
						)
						INSERT INTO #MLVCorrectionLinear
								( OId, LLId, Chainage )
						SELECT ROW_NUMBER() OVER (ORDER BY LLID, Chainage) AS OId,  *
						FROM (
						SELECT LLId, BeginChainage AS Chainage FROM #temp_MLVCorrection
						UNION
						SELECT LLId, EndChainage AS Chainage FROM #temp_MLVCorrection
						UNION
						SELECT LLId, BeginChainage AS Chainage FROM #temp_MLVSection
						UNION
						SELECT LLId, EndChainage AS Chainage FROM #temp_MLVSection
						) t ORDER BY LLid, Chainage


						--Create Dynamic Segments for the MLVCorrection Table
						IF OBJECT_ID(''tempdb..#MLVDynamicSeg'') IS NOT NULL
						BEGIN
							DROP TABLE #MLVDynamicSeg
						END

						CREATE TABLE #MLVDynamicSeg
						(
						ID NUMERIC(10,0) NULL,
						LLId NUMERIC (10,0) NULL,
						BeginChainage NUMERIC(13, 5) NULL,
						EndChainage NUMERIC(13, 5) NULL
						)

						INSERT INTO #MLVDynamicSeg
								( ID ,
								  LLId ,
								  BeginChainage ,
								  EndChainage
								)
						SELECT  mvcl1.OID AS Id ,
								mvcl1.LLId ,
								mvcl1.Chainage AS BeginChainage ,
								mvcl2.Chainage AS EndChainage 
						FROM #MLVCorrectionLinear mvcl1
						INNER JOIN #MLVCorrectionLinear mvcl2 ON mvcl1.LLId = mvcl2.LLId 
						AND mvcl2.OId = mvcl1.OID +1


						-- Get back station series from chainage
						IF OBJECT_ID(''tempdb..#MLVCorrectionStationing'') IS NOT NULL
						BEGIN
							DROP TABLE #MLVCorrectionStationing
						END

						CREATE TABLE #MLVCorrectionStationing
						(
						ID NUMERIC(10,0) NULL,
						StationSeriesId NUMERIC (10,0) NULL,
						BeginChainage NUMERIC (13,5) NULL,
						EndChainage NUMERIC (13,5) NULL,
						LLId NUMERIC (10,0) NULL
						)

						INSERT INTO #MLVCorrectionStationing
								( ID ,
								  StationSeriesId ,
								  BeginChainage ,
								  EndChainage ,
								  LLId
								)
						SELECT  mds.ID ,
								sscBeg.Id ,
								mds.BeginChainage ,
								mds.EndChainage ,
								mds.LLId 
						FROM #MLVDynamicSeg mds
						INNER JOIN (SELECT ss.Id, ss.LineLoopId, ss.BeginStationNum, ss.EndStationNum,
							ss.BeginStationNum * mlv.MultiplierNum + mlv.FactorNum AS BeginChainage,
							ss.EndStationNum * mlv.MultiplierNum + mlv.FactorNum AS EndChainage
							FROM dbo.StationSeries ss
							INNER JOIN dbo.MLVCorrection mlv ON ss.Id = mlv.StationSeriesId) sscBeg ON mds.LLId = sscBeg.LineLoopId 
						AND mds.BeginChainage >= sscBeg.BeginChainage 
						AND mds.EndChainage <= sscBeg.EndChainage 

						--Get MLVCorrection Data
						IF OBJECT_ID(''tempdb..#MLVCorrection_New'') IS NOT NULL
						BEGIN
							DROP TABLE #MLVCorrection_New
						END

						CREATE TABLE #MLVCorrection_New
						(
						Id NUMERIC (10,0) NULL,
						EffectiveStartDate DATETIME NULL,
						EffectiveEndDate DATETIME NULL,
						MultiplierNum NUMERIC (5,3) NULL,
						FactorNum NUMERIC (13,5) NULL,
						MLVSectionId NUMERIC (10,0) NULL,
						StateProvinceDomainId NUMERIC (7,0) NULL,
						DistrictDivisionDomainId NUMERIC (7,0) NULL,
						AreaDomainId NUMERIC (7,0) NULL,
						StationSeriesId NUMERIC (10,0) NULL,
						BeginStationNum NUMERIC (13,5) NULL,
						EndStationNum NUMERIC (13,5) NULL,
						Record_Status VARCHAR(1) NULL,
						BeginChainage NUMERIC (13,5) NULL,
						EndChainage NUMERIC (13,5) NULL,
						LLId NUMERIC (10,0) NULL
						)

						INSERT INTO #MLVCorrection_New
								( Id ,
								  EffectiveStartDate ,
								  EffectiveEndDate ,
								  MultiplierNum ,
								  FactorNum ,
								  MLVSectionId ,
								  StateProvinceDomainId ,
								  DistrictDivisionDomainId ,
								  AreaDomainId ,
								  StationSeriesId ,
								  BeginStationNum ,
								  EndStationNum ,
								  BeginChainage ,
								  EndChainage ,
								  LLId
								)
						SELECT  mcs.ID ,
								mc.EffectiveStartDate ,
								mc.EffectiveEndDate ,
								mc.MultiplierNum ,
								mc.FactorNum ,
								NULL AS MLVSectionId ,
								mc.StateProvinceDomainId ,
								mc.DistrictDivisionDomainId ,
								mc.AreaDomainId ,
								mcs.StationSeriesId ,
								NULL AS BeginStationNum ,
								NULL AS EndStationNum ,
								mcs.BeginChainage ,
								mcs.EndChainage ,
								mcs.LLId 
						FROM #MLVCorrectionStationing mcs
						INNER JOIN #temp_MLVCorrection mc ON mcs.LLId = mc.LLId 
						AND mcs.BeginChainage >= mc.BeginChainage 
						AND mcs.BeginChainage <= mc.EndChainage 
						AND mcs.StationSeriesId = mc.StationSeriesId
						AND mcs.EndChainage >= mc.BeginChainage 
						AND mcs.EndChainage <= mc.EndChainage 

						--Recalculate Begin Stationing
						UPDATE mcs
						SET BeginStationNum = (mcs.BeginChainage - mc_beg.FactorNum) / mc_beg.MultiplierNum
						FROM #MLVCorrection_New mcs
						INNER JOIN #temp_MLVCorrection mc_beg ON mcs.LLId = mc_beg.LLId 
						AND mcs.BeginChainage >= mc_beg.BeginChainage 
						AND mcs.BeginChainage <= mc_beg.EndChainage 
						AND mcs.StationSeriesId = mc_beg.StationSeriesId

						--Recalculate End Stationing
						UPDATE mcs
						SET  EndStationNum = (mcs.EndChainage - mc_end.FactorNum) / mc_end.MultiplierNum
						FROM #MLVCorrection_New mcs
						INNER JOIN #temp_MLVCorrection mc_end ON mcs.LLId = mc_end.LLId 
						AND mcs.EndChainage >= mc_end.BeginChainage 
						AND mcs.EndChainage <= mc_end.EndChainage 
						AND mcs.StationSeriesId = mc_end.StationSeriesId

						--Get MLVSectionId
						UPDATE mcn
						SET MLVSectionId = ms.ID
						FROM #MLVCorrection_New mcn
						LEFT JOIN #temp_MLVSection ms ON ms.LLId = mcn.LLId
						AND mcn.BeginChainage >= ms.BeginChainage
						AND mcn.BeginChainage <= ms.EndChainage
						AND mcn.EndChainage >= ms.BeginChainage
						AND mcn.EndChainage <= ms.EndChainage

						--Clear out ETL_MLVCorrection
						DELETE FROM MLVCorrection

						--Copy temp table to ETL_MLVCorrection
						INSERT INTO MLVCorrection
								( Id ,
								  EffectiveStartDate ,
								  EffectiveEndDate ,
								  MultiplierNum ,
								  FactorNum ,
								  MLVSectionId ,
								  StateProvinceDomainId ,
								  DistrictDivisionDomainId ,
								  AreaDomainId ,
								  StationSeriesId ,
								  BeginStationNum ,
								  EndStationNum 
								)
						SELECT  ROW_NUMBER()OVER(ORDER BY LLId, BeginChainage) AS Id,
								mcn.EffectiveStartDate ,
								mcn.EffectiveEndDate ,
								mcn.MultiplierNum ,
								mcn.FactorNum ,
								mcn.MLVSectionId ,
								mcn.StateProvinceDomainId ,
								mcn.DistrictDivisionDomainId ,
								mcn.AreaDomainId ,
								mcn.StationSeriesId ,
								mcn.BeginStationNum ,
								mcn.EndStationNum 
						FROM #MLVCorrection_New mcn
						WHERE MLVSectionId IS NOT NULL

						DROP TABLE #temp_MLVSection

						DROP TABLE #temp_MLVCorrection 

						DROP TABLE #MLVCorrection_New 

						DROP TABLE #MLVCorrectionStationing

						DROP TABLE #MLVDynamicSeg

						DROP TABLE #MLVCorrectionLinear

						END	

						END'
			EXEC sp_executesql @sql
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650009 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 10
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650010', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 0, Updates 10', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650010 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @SQL NVARCHAR(MAX)
			SET @SQL = 'ALTER PROCEDURE [dbo].[sp_MergeVirtualTables]
									@VirtualTableList varchar(2000)
			AS
			BEGIN


				declare @VirtualTables table (VirtualTableName nvarchar(100), VirtualColumnDataTypeInd char(1)) 

				DECLARE @sql nvarchar(4000),@virtualTableName varchar(100)


				truncate table VirtualTableDataDate
				truncate table VirtualTableDataFlg
				truncate table VirtualTableDataInd
				truncate table VirtualTableDataListDomain
				truncate table VirtualTableDataNum
				truncate table VirtualTableDataString
				delete VirtualTableStationing


				insert into @VirtualTables
				SELECT  vt.VirtualTableName , VirtualColumnDataTypeInd
				FROM VirtualTable vt 
				inner join VirtualColumn vc 
					on vc.VirtualTableId = vt.Id
				inner join sys.tables t
					on  t.name = ''VT_'' +vt.VirtualTableName
					and charindex( '','' + vt.VirtualTableName + '','' ,'','' + @VirtualTableList  + '','') > 0

				DECLARE v_cursor_Stn CURSOR FOR SELECT distinct VirtualTableName FROM @VirtualTables
				OPEN v_cursor_Stn
				FETCH NEXT FROM v_cursor_Stn INTO @virtualTableName
				WHILE @@FETCH_STATUS = 0
				BEGIN
					SET @sql = ''INSERT INTO VirtualTableStationing (VirtualTableId, VirtualTableStationingId, EffectiveStartDate, EffectiveEndDate, BeginStationSeriesId, BeginStationNum, EndStationSeriesId, EndStationNum, SourceId)
								SELECT distinct VirtualTableId, VirtualTableStationingId, isnull(EffectiveStartDate,getdate()), EffectiveEndDate, BeginStationSeriesId, BeginStationNum, EndStationSeriesId, EndStationNum, SourceId FROM Vt_'' + @virtualTableName
					EXEC sp_executesql @sql
					FETCH NEXT FROM v_cursor_Stn INTO @virtualTableName	
				END
				CLOSE v_cursor_Stn
				DEALLOCATE v_cursor_Stn

				DECLARE v_cursor_D CURSOR FOR SELECT distinct VirtualTableName FROM @VirtualTables where VirtualColumnDataTypeInd = ''D''
				OPEN v_cursor_D
				FETCH NEXT FROM v_cursor_D INTO @virtualTableName
				WHILE @@FETCH_STATUS = 0
				BEGIN
					SET @sql = ''INSERT INTO VirtualTableDataDate (VirtualColumnId, VirtualTableId, VirtualTableStationingId, DataFieldValueDate, SourceId)
								SELECT distinct VirtualColumnId, VirtualTableId, VirtualTableStationingId, DataFieldValueDate, SourceId FROM Vt_'' + @virtualTableName
					EXEC sp_executesql @sql
					FETCH NEXT FROM v_cursor_D INTO @virtualTableName	
				END
				CLOSE v_cursor_D
				DEALLOCATE v_cursor_D

				DECLARE v_cursor_F CURSOR FOR SELECT distinct VirtualTableName FROM @VirtualTables where VirtualColumnDataTypeInd = ''F''
				OPEN v_cursor_F
				FETCH NEXT FROM v_cursor_F INTO @virtualTableName
				WHILE @@FETCH_STATUS = 0
				BEGIN
					SET @sql = ''INSERT INTO VirtualTableDataFlg (VirtualColumnId, VirtualTableId, VirtualTableStationingId, DataFieldValueFlg, SourceId)
								SELECT distinct VirtualColumnId, VirtualTableId, VirtualTableStationingId, DataFieldValueFlg, SourceId FROM Vt_'' + @virtualTableName
					EXEC sp_executesql @sql
					FETCH NEXT FROM v_cursor_F INTO @virtualTableName	
				END
				CLOSE v_cursor_F
				DEALLOCATE v_cursor_F

				DECLARE v_cursor_I CURSOR FOR SELECT distinct VirtualTableName FROM @VirtualTables where VirtualColumnDataTypeInd = ''I''
				OPEN v_cursor_I
				FETCH NEXT FROM v_cursor_I INTO @virtualTableName
				WHILE @@FETCH_STATUS = 0
				BEGIN
					SET @sql = ''INSERT INTO VirtualTableDataInd (VirtualColumnId, VirtualTableId, VirtualTableStationingId, DataFieldValueInd, SourceId)
								SELECT distinct VirtualColumnId, VirtualTableId, VirtualTableStationingId, DataFieldValueInd, SourceId FROM Vt_'' + @virtualTableName
					EXEC sp_executesql @sql
					FETCH NEXT FROM v_cursor_I INTO @virtualTableName	
				END
				CLOSE v_cursor_I
				DEALLOCATE v_cursor_I

				DECLARE v_cursor_L CURSOR FOR SELECT distinct VirtualTableName FROM @VirtualTables where VirtualColumnDataTypeInd = ''L''
				OPEN v_cursor_L
				FETCH NEXT FROM v_cursor_L INTO @virtualTableName
				WHILE @@FETCH_STATUS = 0
				BEGIN
					SET @sql = ''INSERT INTO VirtualTableDataListDomain (VirtualColumnId, VirtualTableId, VirtualTableStationingId, DataFieldValueDomainId, SourceId)
								SELECT distinct VirtualColumnId, VirtualTableId, VirtualTableStationingId, DataFieldValueDomainId, SourceId FROM Vt_'' + @virtualTableName
					EXEC sp_executesql @sql
					FETCH NEXT FROM v_cursor_L INTO @virtualTableName	
				END
				CLOSE v_cursor_L
				DEALLOCATE v_cursor_L

				DECLARE v_cursor_N CURSOR FOR SELECT distinct VirtualTableName FROM @VirtualTables where VirtualColumnDataTypeInd = ''N''
				OPEN v_cursor_N
				FETCH NEXT FROM v_cursor_N INTO @virtualTableName
				WHILE @@FETCH_STATUS = 0
				BEGIN
					SET @sql = ''INSERT INTO VirtualTableDataNum (VirtualColumnId, VirtualTableId, VirtualTableStationingId, DataFieldValueNum, SourceId)
								SELECT distinct VirtualColumnId, VirtualTableId, VirtualTableStationingId, DataFieldValueNum, SourceId FROM Vt_'' + @virtualTableName
					EXEC sp_executesql @sql
					FETCH NEXT FROM v_cursor_N INTO @virtualTableName	
				END
				CLOSE v_cursor_N
				DEALLOCATE v_cursor_N

				DECLARE v_cursor_S CURSOR FOR SELECT distinct VirtualTableName FROM @VirtualTables where VirtualColumnDataTypeInd = ''S''
				OPEN v_cursor_S
				FETCH NEXT FROM v_cursor_S INTO @virtualTableName
				WHILE @@FETCH_STATUS = 0
				BEGIN
					SET @sql = ''INSERT INTO VirtualTableDataString (VirtualColumnId, VirtualTableId, VirtualTableStationingId, DataFieldValueString, SourceId)
								SELECT distinct VirtualColumnId, VirtualTableId, VirtualTableStationingId, DataFieldValueString, SourceId FROM Vt_'' + @virtualTableName
					EXEC sp_executesql @sql
					FETCH NEXT FROM v_cursor_S INTO @virtualTableName	
				END
				CLOSE v_cursor_S
				DEALLOCATE v_cursor_S
			END'

			EXECUTE (@SQL)

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650010 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			DECLARE @SQL NVARCHAR(MAX)
			SET @SQL = 'ALTER function [dbo].[fn_GenerateTransfromSelectStatement]
						(
						 @tableName varchar(200)
						)
						returns varchar(max)
						AS
						BEGIN

						DECLARE @column_names varchar(max) = ''''
						DECLARE @column_name varchar(100)
						DECLARE @column_short_name varchar(100)
						DECLARE @joins varchar(max) = ''''
						DECLARE @selectStatment varchar(max) = ''''
						DECLARE @refTableCount int 
						DECLARE @refParentTableCount int 
						DECLARE @fromUnit varchar(50)
						DECLARE @toUnit varchar(50)
						DECLARE @precision varchar(10)
						DECLARE @scale varchar(10)
						DECLARE @conversionVariables varchar(max) = ''''
						DECLARE @execConversions varchar(max) = ''''
						DECLARE @tempconversionVariables varchar(max) = ''''
						DECLARE @exectempConversions varchar(max) = ''''
						DECLARE @ldTableName varchar(100) = ''''

						-- Check whether the table is virtual table

						IF EXISTS (SELECT * FROM dbo.VirtualTable WHERE VirtualTableName = @tableName)
						BEGIN
							SET @tableName = ''VT_'' + @tableName
						END

						-- Create temp listdomain table variable
						DECLARE @ListDomain TABLE (
						FK_Name varchar(100), TableName varchar(100), ColumnName varchar(100), ReferenceTable varchar(100), ReferenceColumn varchar(100))

						Insert into @ListDomain
						SELECT FK_Name, TableName, ColumnName, ReferencedTable, ReferencedColumn 
						FROM (
						SELECT obj.name AS FK_NAME,tab1.name AS TableName, col1.name AS ColumnName,tab2.name AS ReferencedTable,col2.name AS ReferencedColumn
						FROM sys.foreign_key_columns fkc
						INNER JOIN sys.objects obj ON obj.object_id = fkc.constraint_object_id
						INNER JOIN sys.tables tab1 ON tab1.object_id = fkc.parent_object_id
						INNER JOIN sys.schemas sch ON tab1.schema_id = sch.schema_id
						INNER JOIN sys.columns col1 ON col1.column_id = parent_column_id AND col1.object_id = tab1.object_id
						INNER JOIN sys.tables tab2 ON tab2.object_id = fkc.referenced_object_id
						INNER JOIN sys.columns col2 ON col2.column_id = referenced_column_id AND col2.object_id = tab2.object_id
						) tmp
						WHERE tmp.ReferencedTable like ''LD_%''
						order by tablename

						-- Generate variables for conversion - no temperature
						DECLARE cv_cursor CURSOR FOR
							SELECT distinct FromUnit, ToUnit FROM ConversionLookup c WHERE  (FromUnit <> ''Fahrenheit'') and c.TableName = @TableName
							UNION
							SELECT distinct FromUnit, ToUnit FROM ConversionLookup c WHERE  c.TableName = ''VirtualTableStationing'' AND c.ColumnName LIKE ''%StationNum''
							AND EXISTS (SELECT * FROM dbo.VirtualTable WHERE VirtualTableName = SubString(@TableName, 4, len(@TableName)))
						OPEN cv_cursor
							FETCH NEXT FROM cv_cursor INTO @fromUnit, @toUnit

							IF @@FETCH_STATUS = 0
							BEGIN
								SET @conversionVariables = @conversionVariables + '' ''
							END

							WHILE @@FETCH_STATUS = 0
							BEGIN
								SET @conversionVariables = @conversionVariables + ''Declare @'' + @fromUnit + @toUnit + '' numeric(13,5) '' + CHAR(13)
								FETCH NEXT FROM cv_cursor INTO @fromUnit, @toUnit
							END
						CLOSE cv_cursor
						DEALLOCATE cv_cursor

						-- Generate exec conversion stored proc - no temperature
						DECLARE ec_cursor CURSOR FOR
							SELECT distinct FromUnit, ToUnit FROM ConversionLookup c WHERE  (FromUnit <> ''Fahrenheit'') and c.TableName = @tablename 
							UNION
							SELECT distinct FromUnit, ToUnit FROM ConversionLookup c WHERE  c.TableName = ''VirtualTableStationing'' AND c.ColumnName LIKE ''%StationNum''
							AND EXISTS (SELECT * FROM dbo.VirtualTable WHERE VirtualTableName = SubString(@TableName, 4, len(@TableName)))

						OPEN ec_cursor
							FETCH NEXT FROM ec_cursor INTO @fromUnit, @toUnit

							IF @@FETCH_STATUS = 0
							BEGIN
								SET @execConversions = @execConversions + '' ''
							END


							WHILE @@FETCH_STATUS = 0
							BEGIN
								SET @execConversions = @execConversions + ''EXEC sp_ConversionCheck '' + '''''''' + @fromUnit + '''''''' + '' , '' + '''''''' + @toUnit + '''''''' + '', NULL, @'' + @fromUnit + @toUnit + '' OUTPUT '' + CHAR(13)
								FETCH NEXT FROM ec_cursor INTO @fromUnit, @toUnit
							END
						CLOSE ec_cursor
						DEALLOCATE ec_cursor

						-- Generate variables for conversion - temperature
						DECLARE tcv_cursor CURSOR FOR
							SELECT ColumnName, FromUnit, ToUnit, Precision, Scale FROM ConversionLookup c WHERE  (FromUnit = ''Fahrenheit'' or FromUnit = ''Celsius'') and c.TableName = @tableName ORDER BY ColumnName

						OPEN tcv_cursor
							FETCH NEXT FROM tcv_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale

							WHILE @@FETCH_STATUS = 0
							BEGIN
								SET @tempconversionVariables =''Declare @'' + @fromUnit + @toUnit + '' numeric(13,5) , @TempOffset numeric(13,5)'' + CHAR(13)
								FETCH NEXT FROM tcv_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale
							END
						CLOSE tcv_cursor
						DEALLOCATE tcv_cursor

						-- Generate exec conversion stored proc - temperature
						DECLARE tec_cursor CURSOR FOR
							SELECT ColumnName, FromUnit, ToUnit, Precision, Scale FROM ConversionLookup c WHERE   (FromUnit = ''Fahrenheit'' or FromUnit = ''Celsius'') and c.TableName = @tableName ORDER BY ColumnName

						OPEN tec_cursor
							FETCH NEXT FROM tec_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale

							WHILE @@FETCH_STATUS = 0
							BEGIN
								SET @exectempConversions =''EXEC sp_ConversionCheck '' + '''''''' + @fromUnit + '''''''' + '' , '' + '''''''' + @toUnit + '''''''' + '', @TempOffset OUTPUT, @'' + @fromUnit + @toUnit + '' OUTPUT '' + CHAR(13)
								FETCH NEXT FROM tec_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale
							END
						CLOSE tec_cursor
						DEALLOCATE tec_cursor

						SET @column_names = ''Id = case when t.SourceId not like ''''%[^0-9]%'''' then t.SourceId else IDLookup.Id end '' + CHAR(13)
						-- Get StationSeriesId columns
						DECLARE s_cursor CURSOR FOR
							SELECT c.Column_Name FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = ''Extract_'' + @tableName
							AND c.Column_Name LIKE ''%StationSeriesId'' ORDER BY c.Column_Name

						SET @refTableCount = 1
						OPEN s_cursor
							FETCH NEXT FROM s_cursor INTO @column_name
	
							IF @@FETCH_STATUS = 0
							BEGIN
								SET @column_names = @column_names + '',''
							END

							WHILE @@FETCH_STATUS = 0
							BEGIN
								IF @column_name <> ''StationSeriesId''
								BEGIN
									SET @column_names = @column_names + ''ss'' + cast(@refTableCount AS varchar(10)) + ''.Id AS '' + @column_name + '', '' 

									SET @joins = @joins + '' LEFT JOIN StationSeries ss'' + cast(@refTableCount AS varchar(10)) + '' with (nolock) ON ss'' + cast(@refTableCount AS varchar(10)) + ''.SourceId = t.'' + @column_name + CHAR(13)
								END
								ELSE
								BEGIN
									SET @column_names = @column_names + ''ss1.Id AS '' + @column_name + '', '' 
								END

								SET @refTableCount = @refTableCount + 1

								FETCH NEXT FROM s_cursor INTO @column_name
							END

						CLOSE s_cursor
						DEALLOCATE s_cursor

						IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = @tableName AND c.Column_Name IN (''BeginStationSeriesId'',''EndStationSeriesId''))
						BEGIN
							IF right(@column_names, 1) = '',''
							BEGIN
								SET @column_names = subString(@column_names, 1, len(@column_names)-1)
							END

							SET @column_names = @column_names + 
								(SELECT Cols = STUFF((SELECT  '', '' + CASE WHEN c.Column_Name = ''BeginStationSeriesId'' THEN ''BeginStationSeriesGUID'' WHEN c.Column_Name = ''EndStationSeriesId'' THEN ''EndStationSeriesGUID'' WHEN c.Column_Name = ''StationSeriesId'' THEN ''StationSeriesGUID'' END + '' = t.'' + QUOTENAME(c.Column_Name)
								FROM INFORMATION_SCHEMA.COLUMNS c	
								WHERE table_name = @tableName
								AND c.Column_Name IN (''BeginStationSeriesId'',''EndStationSeriesId'')
								ORDER BY c.Column_Name
								FOR XML PATH('''')), 1, 2, ''''))
						END

						-- Get ListDomain columns
						DECLARE l_cursor CURSOR FOR
							SELECT c.Column_Name FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = ''Extract_'' + @tableName
							And Column_Name in (Select ColumnName from @ListDomain)
							ORDER BY c.Column_Name

						SET @refTableCount = 1
						OPEN l_cursor
							FETCH NEXT FROM l_cursor INTO @column_name

							WHILE @@FETCH_STATUS = 0
							BEGIN
								IF @column_name like ''%DomainId''
								BEGIN
									SET @column_short_name = replace(@column_name, ''DomainId'', '''')
								END
								ELSE
								BEGIN
									SET @column_short_name = CASE WHEN right(@column_name, 2) = ''ld'' then SUBSTRING(@column_name, 1, LEN(@column_name) - 2) ELSE @column_name END
								END
		
								SET @joins = @joins + '' '' + (SELECT Replace(dbo.fn_ScriptJoinLDColumn(@tableName, @column_name, '' tbl'' + cast(@refTableCount AS varchar(10))), ''.Id'', ''.Code''))+ CHAR(13)

								IF right(@column_names, 1) = '',''
								BEGIN
									SET @column_names = subString(@column_names, 1, len(@column_names)-1)
								END

								SET @column_names = @column_names + '', tbl'' + cast(@refTableCount AS varchar(10)) + ''.Id AS '' + @column_name + '', t.'' + @column_name + '' AS '' + @column_short_name + CHAR(13)
								SET @refTableCount = @refTableCount + 1

								FETCH NEXT FROM l_cursor INTO @column_name
							END

						CLOSE l_cursor
						DEALLOCATE l_cursor

						-- Get ParentColumns columns
						DECLARE p_cursor CURSOR FOR
							SELECT c.Column_Name FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = ''Extract_'' + @tableName
							And Column_Name in (select ColumnName from StageFKeysInfo where TableName= @tableName )
							And Column_Name NOT in (Select ColumnName from @ListDomain)
							AND Column_Name NOT IN (''StationSeriesId'',''BeginStationSeriesId'',''EndStationSeriesId'', ''BaseIliId'', ''Stg_ILIId'')
							ORDER BY c.Column_Name

						SET @refParentTableCount = 1
						OPEN p_cursor
							FETCH NEXT FROM p_cursor INTO @column_name

							WHILE @@FETCH_STATUS = 0
							BEGIN
								BEGIN
									SET @column_short_name = CASE WHEN right(@column_name, 2) = ''Id'' then SUBSTRING(@column_name, 1, LEN(@column_name) - 2) ELSE @column_name END
								END

								IF @column_name IN (''RCReasonTypeId'')
								BEGIN
									SET @joins = @joins + '' '' + (SELECT REPLACE(dbo.fn_ScriptJoinColumn(@tableName, @column_name, '' p'' + cast(@refParentTableCount AS varchar(10))),''.Id'',''.Code'')) + CHAR(13)
								END
								ELSE IF @column_name NOT IN (''RCScenarioID'')
								BEGIN
									SET @joins = @joins + '' '' + (SELECT REPLACE(dbo.fn_ScriptJoinColumn(@tableName, @column_name, '' p'' + cast(@refParentTableCount AS varchar(10))),''.Id'',''.SourceId'')) + CHAR(13)
								END
								ELSE
								BEGIN
									SET @joins = @joins + '' '' + (SELECT dbo.fn_ScriptJoinColumn(@tableName, @column_name, '' p'' + cast(@refParentTableCount AS varchar(10)))) + CHAR(13)
								END

								IF right(@column_names, 1) = '',''
								BEGIN
									SET @column_names = subString(@column_names, 1, len(@column_names)-1)
								END

								SET @column_names = @column_names + '', p'' + cast(@refParentTableCount AS varchar(10)) + ''.Id AS '' + @column_name + '', t.'' + @column_name + '' AS '' + @column_short_name + CHAR(13)
								SET @refParentTableCount = @refParentTableCount + 1

								FETCH NEXT FROM p_cursor INTO @column_name
							END

						CLOSE p_cursor
						DEALLOCATE p_cursor

						IF NOT EXISTS (SELECT * FROM dbo.VirtualTable WHERE VirtualTableName = SubString(@TableName, 4, len(@TableName)))
						BEGIN
							SET @joins = @joins + '' LEFT JOIN GUIDLookup IDLookup with (nolock)
								on IDLookup.GUID = t.SourceId
									and IDLookup.TableName = '''''' + @TableName + '''''''' + CHAR(13)
						END
						ELSE
						BEGIN
							SET @joins = @joins + '' LEFT JOIN VTGUIDLookup IDLookup with (nolock)
								on IDLookup.GUID = t.SourceId
									and IDLookup.TableName = '''''' + SubString(@TableName, 4, len(@TableName)) + '''''''' + CHAR(13)
						END

						----Get columns which required conversion -- no temperature
						DECLARE c_cursor CURSOR FOR
							SELECT * FROM (
								SELECT ColumnName, FromUnit, ToUnit, Precision, Scale FROM ConversionLookup c WHERE  (FromUnit <> ''Fahrenheit'') and c.TableName = @tableName 
								UNION
								SELECT ColumnName, FromUnit, ToUnit, Precision, Scale FROM ConversionLookup c WHERE  c.TableName = ''VirtualTableStationing'' AND c.ColumnName LIKE ''%StationNum''
								AND EXISTS (SELECT * FROM dbo.VirtualTable WHERE VirtualTableName = SubString(@TableName, 4, len(@TableName)))
							) tmp
							ORDER BY ColumnName

						OPEN c_cursor
							FETCH NEXT FROM c_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale

							WHILE @@FETCH_STATUS = 0
							BEGIN
								IF right(@column_names, 1) = '',''
								BEGIN
									SET @column_names = subString(@column_names, 1, len(@column_names)-1)
								END
								ELSE IF right(@column_names, 2) = '', ''
								BEGIN
									SET @column_names = subString(@column_names, 1, len(@column_names)-1)
								END

								IF @column_name <> ''StationNum''
								BEGIN
									SET @column_names = @column_names + '', ''  + @column_name + '' = cast(t.'' + @column_name + '' * @'' + @fromUnit + @toUnit + '' as numeric('' + @precision + '','' + @scale + ''))'' + CHAR(13)
								END
								ELSE
								BEGIN
									SET @column_names = @column_names + '', ''  + @column_name + '' = cast(t.BeginStationNum * @'' + @fromUnit + @toUnit + '' as numeric('' + @precision + '','' + @scale + ''))'' + CHAR(13)
								END

								FETCH NEXT FROM c_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale
							END
						CLOSE c_cursor
						DEALLOCATE c_cursor

						----Get columns which required conversion -- temperature

						DECLARE ct_cursor CURSOR FOR
							SELECT ColumnName, FromUnit, ToUnit, Precision, Scale FROM ConversionLookup c WHERE  (FromUnit = ''Fahrenheit'' or FromUnit = ''Celsius'') and c.TableName = @tableName ORDER BY ColumnName

						OPEN ct_cursor
							FETCH NEXT FROM ct_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale

							WHILE @@FETCH_STATUS = 0
							BEGIN
								IF right(@column_names, 1) = '',''
								BEGIN
									SET @column_names = subString(@column_names, 1, len(@column_names)-1)
								END

								SET @column_names = @column_names + '', '' + @column_name + '' = cast((t.'' + @column_name + '' + @TempOffset) * @'' + @fromUnit + @toUnit + '' as numeric('' + @precision + '','' + @scale + ''))'' + CHAR(13)
								FETCH NEXT FROM ct_cursor INTO @column_name, @fromUnit, @toUnit, @precision, @scale
							END
						CLOSE ct_cursor
						DEALLOCATE ct_cursor

						------ Get all other columns

						IF right(@column_names, 1) = '',''
						BEGIN
							SET @column_names = subString(@column_names, 1, len(@column_names)-1)
						END

						SET @column_names = @column_names + '','' +
						(SELECT Cols = STUFF((SELECT  '', t.'' + QUOTENAME(c.Column_Name)
						FROM INFORMATION_SCHEMA.Columns c 
						LEFT JOIN StageFKeysInfo sfi ON replace(c.Table_Name,''Extract_'','''') = sfi.TableName AND c.Column_Name = sfi.ColumnName
						Where c.Table_Name = ''Extract_'' + @tableName
						AND c.Column_Name NOT in (Select ColumnName from @ListDomain)
						And sfi.ColumnName IS NULL
						AND c.Column_Name NOT IN (''StationSeriesId'',''BeginStationSeriesId'',''EndStationSeriesId'',''LastModByUserId'', ''LastModDateTime'', ''CreatedDate'', ''CreatedUser'', ''SourceId'', ''Id'', ''BeginStationSeriesGUID'', ''EndStationSeriesGUID'')
						AND c.Column_Name NOT LIKE ''%StationNum''
						AND c.Column_Name NOT IN (SELECT ColumnName FROM ConversionLookup c WHERE c.TableName = @tableName)
						ORDER BY c.Column_Name
						FOR XML PATH('''')), 1, 2, ''''))

						IF right(@column_names, 1) = '',''
						BEGIN
							SET @column_names = subString(@column_names, 1, len(@column_names)-1)
						END

						SET @column_names = @column_names + CHAR(13) +  '',[LastModDateTime] = getdate() 
						,[LastModByUserId] = SUSER_SNAME() 
						,t.[SourceId]
						,[CreatedDate] = getdate()  
						,[CreatedUser] = SUSER_SNAME() 
						,t.[CheckSumValue]''

						IF NOT EXISTS (SELECT * FROM dbo.VirtualTable WHERE VirtualTableName = SubString(@TableName, 4, len(@TableName)))
						BEGIN
							SET @selectStatment =  @conversionVariables + @tempconversionVariables + @execConversions + @exectempConversions +  ''SELECT '' + @column_names + '' from (select * , BINARY_CHECKSUM(*) CheckSumValue from Extract_'' + @tableName + '' with (nolock)) as t ''+ CHAR(13) + @joins
						END
						ELSE
						BEGIN
							IF NOT EXISTS (SELECT * FROM dbo.VirtualColumn WHERE VirtualColumnName = SubString(@TableName, 4, len(@TableName)) AND VirtualColumnDataTypeInd = ''L'')
							BEGIN
								SET @selectStatment =  @conversionVariables + @tempconversionVariables + @execConversions + @exectempConversions 
								+ ''SELECT '' + replace(replace(replace(@column_names, ''t.[VirtualTableId]'', ''vt.Id AS VirtualTableId''), ''t.[VirtualColumnId]'', ''vc.Id AS VirtualColumnId''), ''t.[VirtualTableStationingId]'', ''IDLookup.ID AS VirtualTableStationingId'') 
								+ '', vt.VirtualTableName, vc.VirtualColumnName from (select * , BINARY_CHECKSUM(*) CheckSumValue from Extract_'' + @tableName + '' with (nolock)) as t ''+ CHAR(13) + @joins
								+ '' CROSS JOIN VirtualTable vt ''
								+ '' CROSS JOIN VirtualColumn vc WHERE vt.VirtualTableName = '''''' + SubString(@TableName, 4, len(@TableName)) + '''''' AND vc.VirtualColumnName = '''''' + SubString(@TableName, 4, len(@TableName)) + '''''''' 
							END
							ELSE
							BEGIN
								SET @ldTableName = (SELECT tldt.LDTableName FROM dbo.TempListDomainTable tldt WHERE tldt.TableName = SubString(@TableName, 4, len(@TableName)))

								SET @selectStatment =  @conversionVariables + @tempconversionVariables + @execConversions + @exectempConversions 
								+ ''SELECT '' + replace(replace(replace(replace(@column_names, ''t.[VirtualTableId]'', ''vt.Id AS VirtualTableId''), ''t.[VirtualColumnId]'', ''vc.Id AS VirtualColumnId''), ''t.[VirtualTableStationingId]'', ''IDLookup.ID AS VirtualTableStationingId''), ''t.[DataFieldValueDomainId],'',''ld.Id AS DataFieldValueDomainId,'')
								+ '', vt.VirtualTableName, vc.VirtualColumnName,t.[DataFieldValueDomainId] AS DataFieldValueDomain from (select * , BINARY_CHECKSUM(*) CheckSumValue from Extract_'' + @tableName + '' with (nolock)) as t ''+ CHAR(13) + @joins
								+ '' LEFT JOIN '' + @ldTableName + '' ld ON ld.Code = t.[DataFieldValueDomainId]''
								+ '' CROSS JOIN VirtualTable vt ''
								+ '' CROSS JOIN VirtualColumn vc WHERE vt.VirtualTableName = '''''' + SubString(@TableName, 4, len(@TableName)) + '''''' AND vc.VirtualColumnName = '''''' + SubString(@TableName, 4, len(@TableName)) + '''''''' 

							END
						END
						RETURN @selectStatment
						END'

						EXECUTE (@SQL)
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 2, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650010 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 11
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650011', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 0, Updates 11', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650011 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- Change ACVG and DCVG listdomain columns to nullable.sql
			-- This script will change the listdomain columns to nullable for ACVGSurvey, ACVGSurveyAnomaly, DCVGSurvey and DCVGSurveyAnomaly tables


			ALTER TABLE ACVGSurvey ALTER COLUMN ACVGSurveyTypeDomainid Numeric(10,0) NULL
			ALTER TABLE ACVGSurvey ALTER COLUMN ACVGSurveyEquipmentDomainId Numeric(10,0) NULL
			ALTER TABLE ACVGSurvey ALTER COLUMN ACVGSurveyContractorDomainId Numeric(10,0) NULL
			ALTER TABLE ACVGSurveyAnomaly ALTER COLUMN ACVGAnomalySeverityTypeLD Numeric(10,0) NULL
			ALTER TABLE ACVGSurveyAnomaly ALTER COLUMN ACVGAnomalyIndicationTypeLD Numeric(10,0) NULL
			ALTER TABLE DCVGSurvey ALTER COLUMN DCVGSurveyTypeDomainId Numeric(10,0) NULL
			ALTER TABLE DCVGSurvey ALTER COLUMN DCVGSurveyEquipmentDomainId Numeric(10,0) NULL
			ALTER TABLE DCVGSurvey ALTER COLUMN DCVGSurveyContractorDomainId Numeric(10,0) NULL
			ALTER TABLE DCVGSurveyAnomaly ALTER COLUMN DCVGAnomalySeverityTypeLD Numeric(10,0) NULL
			ALTER TABLE DCVGSurveyAnomaly ALTER COLUMN DCVGAnomalyIndicationTypeLD Numeric(10,0) NULL

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650011 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 12
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650012', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 0, Updates 12', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650012 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- Change ACVG and DCVG EffectiveStartDate columns to nullable.sql
			-- This script will change the EffectiveStartDate columns to nullable for ACVGSurvey, ACVGSurveyAnomaly, DCVGSurvey and DCVGSurveyAnomaly tables


			ALTER TABLE ACVGSurveyRange ALTER COLUMN EffectiveStartDate datetime NULL
			ALTER TABLE ACVGSurveyAnomaly ALTER COLUMN EffectiveStartDate datetime NULL
			ALTER TABLE DCVGSurveyRange ALTER COLUMN EffectiveStartDate datetime NULL
			ALTER TABLE DCVGSurveyAnomaly ALTER COLUMN EffectiveStartDate datetime NULL

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650012 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 13
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650013', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 0, Updates 13', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650013 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- Create error tables for acvg and dcvg.sql
			-- Create the Error tables for acvg and dcvg
			-- Err_ACVGSurvey

			DECLARE @sql nvarchar(max)

			IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Err_ACVGSurvey]') AND type in (N'U'))
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[Err_ACVGSurvey](
								[IRASId] [varchar](500) NULL,
								[ACVGSurveyTypeDomainId] [varchar](500) NULL,
								[ACVGSurveyEquipmentDomainId] [varchar](500) NULL,
								[ACVGSurveyContractorDomainId] [varchar](500) NULL,
								[ACVGSurveySpacing] [varchar](500) NULL,
								[ACVGSurveyComment] [varchar](500) NULL,
								[ACVGSurveyDate] [varchar](500) NULL,
								[LastModByUserId] [varchar](500) NULL,
								[LastModDateTime] [varchar](500) NULL,
								[CreatedDate] [varchar](500) NULL,
								[CreatedUser] [varchar](500) NULL,
								[SourceId] [varchar](500) NULL,
								[ErrorCount] [int] NULL,
								[WarningCount] [int] NULL,
								[MessagesText] [varchar](4000) NULL,
								[ElementName] [varchar](500) NULL
							)'
				EXEC sp_executesql @sql
			END

			-- Err_ACVGSurveyRange

			IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Err_ACVGSurveyRange]') AND type in (N'U'))
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[Err_ACVGSurveyRange](
								[IRASId] [varchar](500) NULL,
								[EffectiveStartDate] [varchar](500) NULL,
								[EffectiveEndDate] [varchar](500) NULL,
								[ACVGSurveyId] [varchar](500) NULL,
								[BeginStationSeriesId] [varchar](500) NULL,
								[BeginStationNum] [varchar](500) NULL,
								[EndStationSeriesId] [varchar](500) NULL,
								[EndStationNum] [varchar](500) NULL,
								[LastModByUserId] [varchar](500) NULL,
								[LastModDateTime] [varchar](500) NULL,
								[SourceId] [varchar](500) NULL,
								[ErrorCount] [int] NULL,
								[WarningCount] [int] NULL,
								[MessagesText] [varchar](4000) NULL,
								[ElementName] [varchar](500) NULL
							)'
				EXEC sp_executesql @sql
			END


			-- Err_ACVGSurveyAnomaly

			IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Err_ACVGSurveyAnomaly]') AND type in (N'U'))
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[Err_ACVGSurveyAnomaly](
									[IRASId] [varchar](500) NULL,
									[EffectiveStartDate] [varchar](500) NULL,
									[EffectiveEndDate] [varchar](500) NULL,
									[ACVGSurveyRangeId] [varchar](500) NULL,
									[ACVGAnomalySeverityTypeLD] [varchar](500) NULL,
									[ACVGAnomalyIndicationTypeLD] [varchar](500) NULL,
									[ACVGAnomalyIRDrop] [varchar](500) NULL,
									[ACVGAnomalyVoltageDrop] [varchar](500) NULL,
									[ACVGAnomalyMaxGradient] [varchar](500) NULL,
									[ACVGAnomalyMaxOn] [varchar](500) NULL,
									[ACVGAnomalyMaxOff] [varchar](500) NULL,
									[ACVGAnomalyComment] [varchar](500) NULL,
									[SourceId] [varchar](500) NULL,
									[StationSeriesId] [varchar](500) NULL,
									[StationNum] [varchar](500) NULL,
									[BeginStationSeriesId] [varchar](500) NULL,
									[BeginStationNum] [varchar](500) NULL,
									[EndStationSeriesId] [varchar](500) NULL,
									[EndStationNum] [varchar](500) NULL,
									[ErrorCount] [int] NULL,
									[WarningCount] [int] NULL,
									[MessagesText] [varchar](4000) NULL,
									[ElementName] [varchar](500) NULL,
									[LastModByUserId] [varchar](500) NULL,
									[LastModDateTime] [varchar](500) NULL
								)'
				EXEC sp_executesql @sql
			END

			-- Err_ACVGSurveyReading

			IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Err_ACVGSurveyReading]') AND type in (N'U'))
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[Err_ACVGSurveyReading](
								[IRASId] [varchar](500) NULL,
								[EffectiveStartDate] [varchar](500) NULL,
								[EffectiveEndDate] [varchar](500) NULL,
								[ACVGSurveyRangeId] [varchar](500) NULL,
								[ACVGReadingAdjustedCurrent] [varchar](500) NULL,
								[ACVGReadingCurrent] [varchar](500) NULL,
								[ACVGReadingCurrentLoss] [varchar](500) NULL,
								[ACVGReadingCurrentDirection] [varchar](500) NULL,
								[ACVGReadingDepthOfCover] [varchar](500) NULL,
								[ACVGReadingCoatingConductance] [varchar](500) NULL,
								[ACVGReadingCoatingResistance] [varchar](500) NULL,
								[ACVGReadingSevClassification] [varchar](500) NULL,
								[ACVGReadingComment] [varchar](500) NULL,
								[StationSeriesId] [varchar](500) NULL,
								[StationNum] [varchar](500) NULL,
								[LastModByUserId] [varchar](500) NULL,
								[LastModDateTime] [varchar](500) NULL,
								[SourceId] [varchar](500) NULL,
								[BeginStationSeriesId] [varchar](500) NULL,
								[BeginStationNum] [varchar](500) NULL,
								[EndStationSeriesId] [varchar](500) NULL,
								[EndStationNum] [varchar](500) NULL,
								[ErrorCount] [int] NULL,
								[WarningCount] [int] NULL,
								[MessagesText] [varchar](4000) NULL,
								[ElementName] [varchar](500) NULL
							)'
				EXEC sp_executesql @sql
			END


			-- Err_DCVGSurvey
			IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Err_DCVGSurvey]') AND type in (N'U'))
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[Err_DCVGSurvey](
								[IRASId] [varchar](500) NULL,
								[DCVGSurveyTypeDomainId] [varchar](500) NULL,
								[DCVGSurveyEquipmentDomainId] [varchar](500) NULL,
								[DCVGSurveyContractorDomainId] [varchar](500) NULL,
								[DCVGSurveySpacing] [varchar](500) NULL,
								[DCVGSurveyComment] [varchar](500) NULL,
								[DCVGSurveyDate] [varchar](500) NULL,
								[LastModByUserId] [varchar](500) NULL,
								[LastModDateTime] [varchar](500) NULL,
								[CreatedDate] [varchar](500) NULL,
								[CreatedUser] [varchar](500) NULL,
								[SourceId] [varchar](500) NULL,
								[ErrorCount] [int] NULL,
								[WarningCount] [int] NULL,
								[MessagesText] [varchar](4000) NULL,
								[ElementName] [varchar](500) NULL
							) '
				EXEC sp_executesql @sql
			END

			-- Err_DCVGSurveyRange

			IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Err_DCVGSurveyRange]') AND type in (N'U'))
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[Err_DCVGSurveyRange](
								[IRASId] [varchar](500) NULL,
								[EffectiveStartDate] [varchar](500) NULL,
								[EffectiveEndDate] [varchar](500) NULL,
								[DCVGSurveyId] [varchar](500) NULL,
								[BeginStationSeriesId] [varchar](500) NULL,
								[BeginStationNum] [varchar](500) NULL,
								[EndStationSeriesId] [varchar](500) NULL,
								[EndStationNum] [varchar](500) NULL,
								[LastModByUserId] [varchar](500) NULL,
								[LastModDateTime] [varchar](500) NULL,
								[SourceId] [varchar](500) NULL,
								[ErrorCount] [int] NULL,
								[WarningCount] [int] NULL,
								[MessagesText] [varchar](4000) NULL,
								[ElementName] [varchar](500) NULL
							)'
				EXEC sp_executesql @sql
			END

			-- Err_DCVGSurveyAnomaly

			IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Err_DCVGSurveyAnomaly]') AND type in (N'U'))
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[Err_DCVGSurveyAnomaly](
								[IRASId] [varchar](500) NULL,
								[EffectiveStartDate] [varchar](500) NULL,
								[EffectiveEndDate] [varchar](500) NULL,
								[DCVGSurveyRangeId] [varchar](500) NULL,
								[DCVGAnomalySeverityTypeLD] [varchar](500) NULL,
								[DCVGAnomalyIndicationTypeLD] [varchar](500) NULL,
								[DCVGAnomalyIRDrop] [varchar](500) NULL,
								[DCVGAnomalyVoltageDrop] [varchar](500) NULL,
								[DCVGAnomalyMaxGradient] [varchar](500) NULL,
								[DCVGAnomalyMaxOn] [varchar](500) NULL,
								[DCVGAnomalyMaxOff] [varchar](500) NULL,
								[DCVGAnomalyComment] [varchar](500) NULL,
								[StationSeriesId] [varchar](500) NULL,
								[StationNum] [varchar](500) NULL,
								[BeginStationSeriesId] [varchar](500) NULL,
								[BeginStationNum] [varchar](500) NULL,
								[EndStationSeriesId] [varchar](500) NULL,
								[EndStationNum] [varchar](500) NULL,
								[CVGAnomlayMaxOff] [varchar](500) NULL,
								[ErrorCount] [int] NULL,
								[WarningCount] [int] NULL,
								[MessagesText] [varchar](4000) NULL,
								[ElementName] [varchar](500) NULL,
								[LastModByUserId] [varchar](500) NULL,
								[LastModDateTime] [varchar](500) NULL
							)'
				EXEC sp_executesql @sql
			END

			-- Err_DCVGSurveyReading

			IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Err_DCVGSurveyReading]') AND type in (N'U'))
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[Err_DCVGSurveyReading](
								[IRASId] [varchar](500) NULL,
								[EffectiveStartDate] [varchar](500) NULL,
								[EffectiveEndDate] [varchar](500) NULL,
								[DCVGSurveyRangeId] [varchar](500) NULL,
								[DCVGSurveyReadingOn] [varchar](500) NULL,
								[DCVGSurveyReadingOff] [varchar](500) NULL,
								[DCVGSurveyReadingNatural] [varchar](500) NULL,
								[DCVGSurveyReadingComment] [varchar](500) NULL,
								[StationSeriesId] [varchar](500) NULL,
								[StationNum] [varchar](500) NULL,
								[LastModByUserId] [varchar](500) NULL,
								[LastModDateTime] [varchar](500) NULL,
								[BeginStationSeriesId] [varchar](500) NULL,
								[EndStationSeriesId] [varchar](500) NULL,
								[BeginStationNum] [varchar](500) NULL,
								[EndStationNum] [varchar](500) NULL,
								[CreatedDate] [varchar](500) NULL,
								[CreatedUser] [varchar](500) NULL,
								[SourceId] [varchar](500) NULL,
								[DCVGSurveyReadingStatic] [varchar](500) NULL,
								[ErrorCount] [int] NULL,
								[WarningCount] [int] NULL,
								[MessagesText] [varchar](4000) NULL,
								[ElementName] [varchar](500) NULL
							)'
				EXEC sp_executesql @sql
			END

			-- Extract_ACVSurvey

			IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Extract_ACVGSurvey]') AND type in (N'U'))
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[Extract_ACVGSurvey](
								[Id] [varchar](500) NULL,
								[ACVGSurveyTypeDomainId] [varchar](500) NULL,
								[ACVGSurveyEquipmentDomainId] [varchar](500) NULL,
								[ACVGSurveyContractorDomainId] [varchar](500) NULL,
								[ACVGSurveySpacing] [varchar](500) NULL,
								[ACVGSurveyComment] [varchar](500) NULL,
								[ACVGSurveyDate] [varchar](500) NULL,
								[LastModByUserId] [varchar](500) NULL,
								[LastModDateTime] [varchar](500) NULL,
								[CreatedDate] [varchar](500) NULL,
								[CreatedUser] [varchar](500) NULL,
								[SourceId] [varchar](500) NULL
							)'
				EXEC sp_executesql @sql
			END

			-- Extract_ACVGSurveyRange

			IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Extract_ACVGSurveyRange]') AND type in (N'U'))
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[Extract_ACVGSurveyRange](
								[Id] [varchar](500) NULL,
								[EffectiveStartDate] [varchar](500) NULL,
								[EffectiveEndDate] [varchar](500) NULL,
								[ACVGSurveyId] [varchar](500) NULL,
								[BeginStationSeriesId] [varchar](500) NULL,
								[BeginStationNum] [varchar](500) NULL,
								[EndStationSeriesId] [varchar](500) NULL,
								[EndStationNum] [varchar](500) NULL,
								[LastModByUserId] [varchar](500) NULL,
								[LastModDateTime] [varchar](500) NULL,
								[SourceId] [varchar](500) NULL
							)'
				EXEC sp_executesql @sql
			END

			-- Extract_ACVGSurveyAnomaly

			IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Extract_ACVGSurveyAnomaly]') AND type in (N'U'))
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[Extract_ACVGSurveyAnomaly](
								[Id] [varchar](500) NULL,
								[EffectiveStartDate] [varchar](500) NULL,
								[EffectiveEndDate] [varchar](500) NULL,
								[ACVGSurveyRangeId] [varchar](500) NULL,
								[ACVGAnomalySeverityTypeLD] [varchar](500) NULL,
								[ACVGAnomalyIndicationTypeLD] [varchar](500) NULL,
								[ACVGAnomalyIRDrop] [varchar](500) NULL,
								[ACVGAnomalyVoltageDrop] [varchar](500) NULL,
								[ACVGAnomalyMaxGradient] [varchar](500) NULL,
								[ACVGAnomalyMaxOn] [varchar](500) NULL,
								[ACVGAnomalyMaxOff] [varchar](500) NULL,
								[ACVGAnomalyComment] [varchar](500) NULL,
								[StationSeriesId] [varchar](500) NULL,
								[StationNum] [varchar](500) NULL,
								[BeginStationSeriesId] [varchar](500) NULL,
								[BeginStationNum] [varchar](500) NULL,
								[EndStationSeriesId] [varchar](500) NULL,
								[EndStationNum] [varchar](500) NULL,
								[LastModByUserId] [varchar](500) NULL,
								[LastModDateTime] [varchar](500) NULL,
								[SourceId] [varchar](500) NULL
							)'
				EXEC sp_executesql @sql
			END

			-- Extract_ACVGSurveyReading

			IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Extract_ACVGSurveyReading]') AND type in (N'U'))
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[Extract_ACVGSurveyReading](
								[Id] [varchar](500) NULL,
								[EffectiveStartDate] [varchar](500) NULL,
								[EffectiveEndDate] [varchar](500) NULL,
								[ACVGSurveyRangeId] [varchar](500) NULL,
								[ACVGReadingAdjustedCurrent] [varchar](500) NULL,
								[ACVGReadingCurrent] [varchar](500) NULL,
								[ACVGReadingCurrentLoss] [varchar](500) NULL,
								[ACVGReadingCurrentDirection] [varchar](500) NULL,
								[ACVGReadingDepthOfCover] [varchar](500) NULL,
								[ACVGReadingCoatingConductance] [varchar](500) NULL,
								[ACVGReadingCoatingResistance] [varchar](500) NULL,
								[ACVGReadingSevClassification] [varchar](500) NULL,
								[ACVGReadingComment] [varchar](500) NULL,
								[StationSeriesId] [varchar](500) NULL,
								[StationNum] [varchar](500) NULL,
								[LastModByUserId] [varchar](500) NULL,
								[LastModDateTime] [varchar](500) NULL,
								[SourceId] [varchar](500) NULL,
								[BeginStationSeriesId] [varchar](500) NULL,
								[BeginStationNum] [varchar](500) NULL,
								[EndStationSeriesId] [varchar](500) NULL,
								[EndStationNum] [varchar](500) NULL
							) '
				EXEC sp_executesql @sql
			END

			-- Extract_DCVGSurvey


			IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Extract_DCVGSurvey]') AND type in (N'U'))
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[Extract_DCVGSurvey](
								[Id] [varchar](500) NULL,
								[DCVGSurveyTypeDomainId] [varchar](500) NULL,
								[DCVGSurveyEquipmentDomainId] [varchar](500) NULL,
								[DCVGSurveyContractorDomainId] [varchar](500) NULL,
								[DCVGSurveySpacing] [varchar](500) NULL,
								[DCVGSurveyComment] [varchar](500) NULL,
								[DCVGSurveyDate] [varchar](500) NULL,
								[LastModByUserId] [varchar](500) NULL,
								[LastModDateTime] [varchar](500) NULL,
								[CreatedDate] [varchar](500) NULL,
								[CreatedUser] [varchar](500) NULL,
								[SourceId] [varchar](500) NULL
							)'
				EXEC sp_executesql @sql
			END


			-- Extract_DCVGSurveyRange

			IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Extract_DCVGSurveyRange]') AND type in (N'U'))
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[Extract_DCVGSurveyRange](
								[Id] [varchar](500) NULL,
								[EffectiveStartDate] [varchar](500) NULL,
								[EffectiveEndDate] [varchar](500) NULL,
								[DCVGSurveyId] [varchar](500) NULL,
								[BeginStationSeriesId] [varchar](500) NULL,
								[BeginStationNum] [varchar](500) NULL,
								[EndStationSeriesId] [varchar](500) NULL,
								[EndStationNum] [varchar](500) NULL,
								[LastModByUserId] [varchar](500) NULL,
								[LastModDateTime] [varchar](500) NULL,
								[SourceId] [varchar](500) NULL
							)'
				EXEC sp_executesql @sql
			END

			-- Extract_DCVGSurveyAnomaly


			IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Extract_DCVGSurveyAnomaly]') AND type in (N'U'))
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[Extract_DCVGSurveyAnomaly](
								[Id] [varchar](500) NULL,
								[EffectiveStartDate] [varchar](500) NULL,
								[EffectiveEndDate] [varchar](500) NULL,
								[DCVGSurveyRangeId] [varchar](500) NULL,
								[DCVGAnomalySeverityTypeLD] [varchar](500) NULL,
								[DCVGAnomalyIndicationTypeLD] [varchar](500) NULL,
								[DCVGAnomalyIRDrop] [varchar](500) NULL,
								[DCVGAnomalyVoltageDrop] [varchar](500) NULL,
								[DCVGAnomalyMaxGradient] [varchar](500) NULL,
								[DCVGAnomalyMaxOn] [varchar](500) NULL,
								[DCVGAnomalyMaxOff] [varchar](500) NULL,
								[DCVGAnomalyComment] [varchar](500) NULL,
								[StationSeriesId] [varchar](500) NULL,
								[StationNum] [varchar](500) NULL,
								[BeginStationSeriesId] [varchar](500) NULL,
								[BeginStationNum] [varchar](500) NULL,
								[EndStationSeriesId] [varchar](500) NULL,
								[EndStationNum] [varchar](500) NULL,
								[CVGAnomlayMaxOff] [varchar](500) NULL,
								[LastModByUserId] [varchar](500) NULL,
								[LastModDateTime] [varchar](500) NULL,
								[SourceId] [varchar](500) NULL
							)'
				EXEC sp_executesql @sql
			END

			-- Extract_DCVGSurveyReading

			IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Extract_DCVGSurveyReading]') AND type in (N'U'))
			BEGIN
				SET @sql = 'CREATE TABLE [dbo].[Extract_DCVGSurveyReading](
								[Id] [varchar](500) NULL,
								[EffectiveStartDate] [varchar](500) NULL,
								[EffectiveEndDate] [varchar](500) NULL,
								[DCVGSurveyRangeId] [varchar](500) NULL,
								[DCVGSurveyReadingOn] [varchar](500) NULL,
								[DCVGSurveyReadingOff] [varchar](500) NULL,
								[DCVGSurveyReadingNatural] [varchar](500) NULL,
								[DCVGSurveyReadingComment] [varchar](500) NULL,
								[StationSeriesId] [varchar](500) NULL,
								[StationNum] [varchar](500) NULL,
								[LastModByUserId] [varchar](500) NULL,
								[LastModDateTime] [varchar](500) NULL,
								[BeginStationSeriesId] [varchar](500) NULL,
								[EndStationSeriesId] [varchar](500) NULL,
								[BeginStationNum] [varchar](500) NULL,
								[EndStationNum] [varchar](500) NULL,
								[CreatedDate] [varchar](500) NULL,
								[CreatedUser] [varchar](500) NULL,
								[SourceId] [varchar](500) NULL,
								[DCVGSurveyReadingStatic] [varchar](500) NULL,
								[BeginStationSeriesGUID] [varchar](500) NULL,
								[EndStationSeriesGUID] [varchar](500) NULL,
								[DCVGSurveyRangeGUID] [varchar](500) NULL
							)'
				EXEC sp_executesql @sql
			END

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650013 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			--Change ACVG and DCVG add CheckSumValue column.sql
			-- This will add the CheckSumValue column into DCVGSurvey, DCVGSurveyRange, DCVGSurveyReading, DCVGSurveyAnomaly, 
			-- ACVGSurveyReading, ACVGSurveyAnomaly, ACVGSurveyRange and ACVGSurvey

			If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurveyReading' And c.Column_Name = 'CheckSumValue')
			BEGIN
				ALTER TABLE DCVGSurveyReading ADD CheckSumValue int NULL
			END

			If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurveyAnomaly' And c.Column_Name = 'CheckSumValue')
			BEGIN
				ALTER TABLE DCVGSurveyAnomaly ADD CheckSumValue int NULL
			END

			If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurveyRange' And c.Column_Name = 'CheckSumValue')
			BEGIN
				ALTER TABLE DCVGSurveyRange ADD CheckSumValue int NULL
			END

			If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurvey' And c.Column_Name = 'CheckSumValue')
			BEGIN
				ALTER TABLE DCVGSurvey ADD CheckSumValue int NULL
			END

			If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurveyReading' And c.Column_Name = 'CheckSumValue')
			BEGIN
				ALTER TABLE ACVGSurveyReading ADD CheckSumValue int NULL
			END

			If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurveyAnomaly' And c.Column_Name = 'CheckSumValue')
			BEGIN
				ALTER TABLE ACVGSurveyAnomaly ADD CheckSumValue int NULL
			END

			If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurveyRange' And c.Column_Name = 'CheckSumValue')
			BEGIN
				ALTER TABLE ACVGSurveyRange ADD CheckSumValue int NULL
			END

			If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurvey' And c.Column_Name = 'CheckSumValue')
			BEGIN
				ALTER TABLE ACVGSurvey ADD CheckSumValue int NULL
			END

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 2, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650013 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 14
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650014', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 0, Updates 14', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650014 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- Create sp_AlignLocateEndStationNum stored proc.sql
			IF object_id('sp_AlignLocateEndStationNum') IS NOT NULL
			BEGIN
				DROP PROCEDURE sp_AlignLocateEndStationNum
			END

			DECLARE @sqlstatement nvarchar(max)

			SET @sqlstatement = 'CREATE PROCEDURE sp_AlignLocateEndStationNum
									AS
									BEGIN
										DECLARE @tableName varchar(100)
										DECLARE @sql nvarchar(max)

										DECLARE l_cursor CURSOR FOR
											SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME IN (
											SELECT ''Extract_'' + Replace(REPLACE(Table_Name, ''ETL_'', ''''),''_Locate'', '''')  FROM INFORMATION_SCHEMA.TABLES WHERE table_name LIKE ''ETL%locate%'')

										OPEN l_cursor 
											FETCH NEXT FROM l_cursor INTO @tableName

											WHILE @@FETCH_STATUS = 0 
											BEGIN
													SET @sql = ''UPDATE tbl
																SET tbl.BeginStationNum = ss.EndStationNum, tbl.EndStationNum = ss.EndStationNum, tbl.StationNum = ss.EndStationNum
																FROM '' + @tableName + '' tbl
																INNER JOIN StationSeries ss on tbl.BeginStationSeriesId = ss.Id
																WHERE tbl.BeginStationNum > ss.EndStationNum''
													EXEC sp_executesql @sql
												FETCH NEXT FROM l_cursor INTO @tableName
											END

										CLOSE l_cursor
										DEALLOCATE l_cursor
									END'
			EXEC sp_executesql @sqlstatement

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650014 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 15
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650015', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 0, Updates 15', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650015 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- Add SourceId, CreatedDate, CreatedUser and Stationing columns into ACVG and DCVG tables.sql
			-- Adding the SourceId, CreatedDate and CreatedUser columns into ACVG and DCVG tables

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurveyAnomaly' And c.Column_Name = 'BeginStationSeriesGUID')
			BEGIN
				ALTER TABLE ACVGSurveyAnomaly
				ADD BeginStationSeriesGUID varchar(50) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurveyAnomaly' And c.Column_Name = 'EndStationSeriesGUID')
			BEGIN
				ALTER TABLE ACVGSurveyAnomaly
				ADD EndStationSeriesGUID varchar(50) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurveyRange' And c.Column_Name = 'BeginStationSeriesGUID')
			BEGIN
				ALTER TABLE ACVGSurveyRange
				ADD BeginStationSeriesGUID varchar(50) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurveyRange' And c.Column_Name = 'EndStationSeriesGUID')
			BEGIN
				ALTER TABLE ACVGSurveyRange
				ADD EndStationSeriesGUID varchar(50) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurveyReading' And c.Column_Name = 'BeginStationSeriesGUID')
			BEGIN
				ALTER TABLE ACVGSurveyReading
				ADD BeginStationSeriesGUID varchar(50) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurveyReading' And c.Column_Name = 'EndStationSeriesGUID')
			BEGIN
				ALTER TABLE ACVGSurveyReading
				ADD EndStationSeriesGUID varchar(50) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurveyAnomaly' And c.Column_Name = 'BeginStationSeriesGUID')
			BEGIN
				ALTER TABLE DCVGSurveyAnomaly
				ADD BeginStationSeriesGUID varchar(50) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurveyAnomaly' And c.Column_Name = 'EndStationSeriesGUID')
			BEGIN
				ALTER TABLE DCVGSurveyAnomaly
				ADD EndStationSeriesGUID varchar(50) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurveyRange' And c.Column_Name = 'BeginStationSeriesGUID')
			BEGIN
				ALTER TABLE DCVGSurveyRange
				ADD BeginStationSeriesGUID varchar(50) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurveyRange' And c.Column_Name = 'EndStationSeriesGUID')
			BEGIN
				ALTER TABLE DCVGSurveyRange
				ADD EndStationSeriesGUID varchar(50) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurveyReading' And c.Column_Name = 'BeginStationSeriesGUID')
			BEGIN
				ALTER TABLE DCVGSurveyReading
				ADD BeginStationSeriesGUID varchar(50) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurveyReading' And c.Column_Name = 'EndStationSeriesGUID')
			BEGIN
				ALTER TABLE DCVGSurveyReading
				ADD EndStationSeriesGUID varchar(50) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurveyAnomaly' And c.Column_Name = 'BeginStationSeriesId')
			BEGIN
				ALTER TABLE ACVGSurveyAnomaly
				ADD BeginStationSeriesId numeric(10, 0) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurveyAnomaly' And c.Column_Name = 'BeginStationNum')
			BEGIN
				ALTER TABLE ACVGSurveyAnomaly
				ADD BeginStationNum numeric(13, 5) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurveyAnomaly' And c.Column_Name = 'EndStationSeriesId')
			BEGIN
				ALTER TABLE ACVGSurveyAnomaly
				ADD EndStationSeriesId numeric(10, 0) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurveyAnomaly' And c.Column_Name = 'EndStationNum')
			BEGIN
				ALTER TABLE ACVGSurveyAnomaly
				ADD EndStationNum numeric(13, 5) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurveyReading' And c.Column_Name = 'BeginStationSeriesId')
			BEGIN
				ALTER TABLE ACVGSurveyReading
				ADD BeginStationSeriesId numeric(10, 0) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurveyReading' And c.Column_Name = 'BeginStationNum')
			BEGIN
				ALTER TABLE ACVGSurveyReading
				ADD BeginStationNum numeric(13, 5) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurveyReading' And c.Column_Name = 'EndStationSeriesId')
			BEGIN
				ALTER TABLE ACVGSurveyReading
				ADD EndStationSeriesId numeric(10, 0) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurveyReading' And c.Column_Name = 'EndStationNum')
			BEGIN
				ALTER TABLE ACVGSurveyReading
				ADD EndStationNum numeric(13, 5) NOT NULL
			END


			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurveyAnomaly' And c.Column_Name = 'BeginStationSeriesId')
			BEGIN
				ALTER TABLE DCVGSurveyAnomaly
				ADD BeginStationSeriesId numeric(10, 0) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurveyAnomaly' And c.Column_Name = 'BeginStationNum')
			BEGIN
				ALTER TABLE DCVGSurveyAnomaly
				ADD BeginStationNum numeric(13, 5) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurveyAnomaly' And c.Column_Name = 'EndStationSeriesId')
			BEGIN
				ALTER TABLE DCVGSurveyAnomaly
				ADD EndStationSeriesId numeric(10, 0) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurveyAnomaly' And c.Column_Name = 'EndStationNum')
			BEGIN
				ALTER TABLE DCVGSurveyAnomaly
				ADD EndStationNum numeric(13, 5) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurveyReading' And c.Column_Name = 'BeginStationSeriesId')
			BEGIN
				ALTER TABLE DCVGSurveyReading
				ADD BeginStationSeriesId numeric(10, 0) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurveyReading' And c.Column_Name = 'BeginStationNum')
			BEGIN
				ALTER TABLE DCVGSurveyReading
				ADD BeginStationNum numeric(13, 5) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurveyReading' And c.Column_Name = 'EndStationSeriesId')
			BEGIN
				ALTER TABLE DCVGSurveyReading
				ADD EndStationSeriesId numeric(10, 0) NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurveyReading' And c.Column_Name = 'EndStationNum')
			BEGIN
				ALTER TABLE DCVGSurveyReading
				ADD EndStationNum numeric(13, 5) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurvey' And c.Column_Name = 'SourceId')
			BEGIN
				ALTER TABLE ACVGSurvey
				ADD SourceId varchar(50) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurvey' And c.Column_Name = 'CreatedDate')
			BEGIN
				ALTER TABLE ACVGSurvey
				ADD CreatedDate datetime default getdate() NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurvey' And c.Column_Name = 'CreatedUser')
			BEGIN
				ALTER TABLE ACVGSurvey
				ADD CreatedUser varchar(45) default suser_sname() NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurveyAnomaly' And c.Column_Name = 'SourceId')
			BEGIN
				ALTER TABLE ACVGSurveyAnomaly
				ADD SourceId varchar(50) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurveyAnomaly' And c.Column_Name = 'CreatedDate')
			BEGIN
				ALTER TABLE ACVGSurveyAnomaly
				ADD CreatedDate datetime default getdate() NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurveyAnomaly' And c.Column_Name = 'CreatedUser')
			BEGIN
				ALTER TABLE ACVGSurveyAnomaly
				ADD CreatedUser varchar(45) default suser_sname() NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurveyRange' And c.Column_Name = 'SourceId')
			BEGIN
				ALTER TABLE ACVGSurveyRange
				ADD SourceId varchar(50) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurveyRange' And c.Column_Name = 'CreatedDate')
			BEGIN
				ALTER TABLE ACVGSurveyRange
				ADD CreatedDate datetime default getdate() NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurveyRange' And c.Column_Name = 'CreatedUser')
			BEGIN
				ALTER TABLE ACVGSurveyRange
				ADD CreatedUser varchar(45) default suser_sname() NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurveyReading' And c.Column_Name = 'SourceId')
			BEGIN
				ALTER TABLE ACVGSurveyReading
				ADD SourceId varchar(50) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurveyReading' And c.Column_Name = 'CreatedDate')
			BEGIN
				ALTER TABLE ACVGSurveyReading
				ADD CreatedDate datetime default getdate() NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'ACVGSurveyReading' And c.Column_Name = 'CreatedUser')
			BEGIN
				ALTER TABLE ACVGSurveyReading
				ADD CreatedUser varchar(45) default suser_sname() NOT NULL
			END


			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurvey' And c.Column_Name = 'SourceId')
			BEGIN
				ALTER TABLE DCVGSurvey
				ADD SourceId varchar(50) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurvey' And c.Column_Name = 'CreatedDate')
			BEGIN
				ALTER TABLE DCVGSurvey
				ADD CreatedDate datetime default getdate() NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurvey' And c.Column_Name = 'CreatedUser')
			BEGIN
				ALTER TABLE DCVGSurvey
				ADD CreatedUser varchar(45) default suser_sname() NOT NULL
			END


			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurveyAnomaly' And c.Column_Name = 'SourceId')
			BEGIN
				ALTER TABLE DCVGSurveyAnomaly
				ADD SourceId varchar(50) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurveyAnomaly' And c.Column_Name = 'CreatedDate')
			BEGIN
				ALTER TABLE DCVGSurveyAnomaly
				ADD CreatedDate datetime default getdate() NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurveyAnomaly' And c.Column_Name = 'CreatedUser')
			BEGIN
				ALTER TABLE DCVGSurveyAnomaly
				ADD CreatedUser varchar(45) default suser_sname() NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurveyRange' And c.Column_Name = 'SourceId')
			BEGIN
				ALTER TABLE DCVGSurveyRange
				ADD SourceId varchar(50) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurveyRange' And c.Column_Name = 'CreatedDate')
			BEGIN
				ALTER TABLE DCVGSurveyRange
				ADD CreatedDate datetime default getdate() NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurveyRange' And c.Column_Name = 'CreatedUser')
			BEGIN
				ALTER TABLE DCVGSurveyRange
				ADD CreatedUser varchar(45) default suser_sname() NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurveyReading' And c.Column_Name = 'SourceId')
			BEGIN
				ALTER TABLE DCVGSurveyReading
				ADD SourceId varchar(50) NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurveyReading' And c.Column_Name = 'CreatedDate')
			BEGIN
				ALTER TABLE DCVGSurveyReading
				ADD CreatedDate datetime default getdate() NOT NULL
			END

			IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'DCVGSurveyReading' And c.Column_Name = 'CreatedUser')
			BEGIN
				ALTER TABLE DCVGSurveyReading
				ADD CreatedUser varchar(45) default suser_sname() NOT NULL
			END

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650015 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 16
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650016', DBVersionComment = 'Link Service Pack DDL 6.5, Rel. 0, Updates 16', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

/****************************************************************************************************************
****************************************************************************************************************
								Script Sanity Checks and Data QC
****************************************************************************************************************
****************************************************************************************************************/
IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650016 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
BEGIN
	DECLARE @DBVersion INT
	DECLARE @DBCheckPointVersion INT
	DECLARE @ErrorMsg NVARCHAR(MAX)
	DECLARE @flag INT
	DECLARE @SQL NVARCHAR(MAX)
	DECLARE @ErrorMessage NVARCHAR(MAX)

	---------------------- Check that LD tables are created for virtual table columns ------------------------

	--Check that an LD table is created for all virtual table columns with an 'L' datatype indicator

	SET @SQL = 'SELECT @Result = COUNT(*) 		
		FROM virtualcolumn vc
		JOIN VirtualTable vt
		ON vc.VirtualTableId = vt.Id
		LEFT JOIN TempListDomainTable tmp
		ON REPLACE(vc.VirtualColumnName, CHAR(32), '''') = tmp.ColumnName
		AND REPLACE(vt.VirtualTableName, CHAR(32), '''') = tmp.TableName
		WHERE virtualcolumndatatypeind = ''L''
		AND vc.VirtualColumnComment <> ''DO NOT USE''
		AND tmp.LDTableName IS NULL'

	EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @flag OUTPUT

	IF @flag != 0
	BEGIN
		SET @SQL = 'SELECT vc.Id AS VirtualColumnId, 
				REPLACE(vc.VirtualColumnName, CHAR(32), ''''),
				vc.VirtualTableId, 
				REPLACE(vt.VirtualTableName, CHAR(32), '''')
		FROM virtualcolumn vc
		JOIN VirtualTable vt
		ON vc.VirtualTableId = vt.Id
		LEFT JOIN TempListDomainTable tmp
		ON REPLACE(vc.VirtualColumnName, CHAR(32), '''') = tmp.ColumnName
		AND REPLACE(vt.VirtualTableName, CHAR(32), '''') = tmp.TableName
		WHERE virtualcolumndatatypeind = ''L''
		AND vc.VirtualColumnComment <> ''DO NOT USE''
		AND tmp.LDTableName IS NULL'

		EXECUTE (@SQL)
			
			PRINT @SQL
		SET @SQL = NULL;
		THROW 51001, N'An LD table was not created for the virtual tables listed in the results tab', 1

	END

	------------------------- Check that all LD tables in the TempListDomainTable are created ---------------------
			
	SET @SQL = 'SELECT @Result = COUNT(*) 
	FROM TempListDomainTable
	WHERE LDTableName NOT IN (SELECT name FROM sys.tables)'
		
	EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @flag OUTPUT

	IF @flag <> 0 
	BEGIN
		SET @SQL = 'SELECT LDTableName FROM TempListDomainTable
		WHERE LDTableName NOT IN (SELECT name FROM sys.tables)';

		EXECUTE (@SQL)
				
		SET @SQL = NULL;
		THROW 51001, N'The tables listed in the Results tab were found in the TempListDomainTable table but were not created', 1;
			
	END

	---------------------------------------- QC data in LD tables ---------------------------------------

	-- Check that data in LD tables match data in ListDomain table
	SET @SQL = 'SELECT @Result = COUNT(*) 
	FROM TempListDomainTable 
	WHERE ListDomainDataCountMatches = ''NO''';

	EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @flag OUTPUT

	IF @flag <> 0
	BEGIN
		SELECT * FROM TempListDomainTable WHERE ListDomainDataCountMatches = 'NO';
		SET @SQL = NULL;
		THROW 51001, N'The data in the LD tables listed in the Results tab do not match the data in the ListDomain table', 1;
	END

	------------------------------- Check that all relevant Listdomain data has a New_Id value ----------------

	SELECT @flag = COUNT(*)
	FROM Temp_ListDomain ld
	JOIN DomainCatalogColXRef dcxr
	ON dcxr.DomainCatalogId = ld.DomainCatalogId
	WHERE New_Id IS NULL 
	AND EXISTS (SELECT * FROM INFORMATION_SCHEMA.columns c 
				WHERE c.Column_Name = dcxr.ColumnName
				AND c.Table_Name = dcxr.ColumnName);

	IF @flag <> 0 
	BEGIN
		THROW 51001, N'Some relevant data in the Temp_ListDomain table are missing a New_Id', 1;
	END

	/*
	Check that the LDTableName, DomainCatalogId, and New LD Ids are conistent in
	Temp_VirtualTableDataListDomain, Temp_ListDomain, TempListDomainTable, and new LD table
	*/

	/*
		Check that the LDTableName and DomainCatalogId are conistent in
		Temp_VirtualTableDataListDomain, Temp_ListDomain and TempListDomainTable tables
	*/

	SET @SQL = 'SELECT  @Result = COUNT(*)
	FROM Temp_VirtualTableDataListDomain vtld
	JOIN Temp_ListDomain ld
	ON ld.Old_Id = vtld.Old_DataFieldValueDomainId
	JOIN TempListDomainTable tmp
	ON vtld.VirtualTableName = tmp.TableName
	AND vtld.VirtualColumnName = tmp.ColumnName
	WHERE ld.New_Id <> vtld.New_DataFieldValueDomainId OR
		vtld.LDTableName <> ld.LDTableName OR vtld.LDTableName <> tmp.LDTableName
		OR ld.LDTableName <> tmp.LDTableName OR vtld.LDTableName IS NULL
		OR ld.LDTableName IS NULL OR tmp.LDTableName IS NULL
		OR vtld.DomainDescr <> ld.DomainDescr OR vtld.Domaindescr <> tmp.DomainDescr
		OR ld.DomainDescr <> tmp.DomainDescr 
		OR (vtld.DomainDescr IS NULL OR ld.DomainDescr IS NULL OR tmp.DomainDescr IS NULL AND TableName NOT LIKE ''IRASCustom%'')
		OR vtld.DomainCatalogId <> ld.DomainCatalogId OR vtld.DomainCatalogId <> tmp.DomainCatalogId
		OR ld.DomainCatalogId <> tmp.DomainCatalogId 
		OR (vtld.DomainCatalogId IS NULL OR ld.DomainCatalogId IS NULL OR tmp.DomainCatalogId IS NULL AND TableName NOT LIKE ''IRASCustom%'')'
				 

	EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @flag OUTPUT

	IF @Flag <> 0
	BEGIN

		SET @SQL = 'SELECT DISTINCT VirtualTableName
				,VirtualColumnName
				,vtld.Old_DataFieldValueDomainId
				,ld.Old_Id
		FROM Temp_VirtualTableDataListDomain vtld
		JOIN Temp_ListDomain ld
		ON ld.Old_Id = vtld.Old_DataFieldValueDomainId
		JOIN TempListDomainTable tmp
		ON vtld.VirtualTableName = tmp.TableName
		AND vtld.VirtualColumnName = tmp.ColumnName
		WHERE ld.New_Id <> vtld.New_DataFieldValueDomainId 

		SELECT DISTINCT VirtualTableName
				,VirtualColumnName
				,vtld.LDTableName VirtualTableDataListDomain_LDTableName
				,ld.LDTableName ListDomain_LDTableName
				,tmp.LDTableName TempListDomainTable_LDTableName
		FROM Temp_VirtualTableDataListDomain vtld
		JOIN Temp_ListDomain ld
		ON ld.Old_Id = vtld.Old_DataFieldValueDomainId
		JOIN TempListDomainTable tmp
		ON vtld.VirtualTableName = tmp.TableName
		AND vtld.VirtualColumnName = tmp.ColumnName
		WHERE vtld.LDTableName <> ld.LDTableName OR vtld.LDTableName <> tmp.LDTableName
			OR ld.LDTableName <> tmp.LDTableName OR vtld.LDTableName IS NULL
			OR ld.LDTableName IS NULL OR tmp.LDTableName IS NULL

		SELECT DISTINCT VirtualTableName
				,VirtualColumnName
				,vtld.DomainDescr VirtualTableDataListDomain_DomainDescr
				,ld.DomainDescr ListDomain_DomainDescr
				,tmp.DomainDescr TempListDomainTable_DomainDescr
		FROM Temp_VirtualTableDataListDomain vtld
		JOIN Temp_ListDomain ld
		ON ld.Old_Id = vtld.Old_DataFieldValueDomainId
		JOIN TempListDomainTable tmp
		ON vtld.VirtualTableName = tmp.TableName
		AND vtld.VirtualColumnName = tmp.ColumnName
		WHERE vtld.DomainDescr <> ld.DomainDescr OR vtld.Domaindescr <> tmp.DomainDescr
			OR ld.DomainDescr <> tmp.DomainDescr 
			OR (vtld.DomainDescr IS NULL OR ld.DomainDescr IS NULL OR tmp.DomainDescr IS NULL 
			AND TableName NOT LIKE ''IRASCustom%'')
					
		SELECT DISTINCT VirtualTableName
				,VirtualColumnName
				,vtld.DomainCatalogId VirtualTableDataListDomain_DomainCatalogId
				,ld.DomainCatalogId ListDomain_DomainCatalogId
				,tmp.DomainCatalogId TempListDomainTable_DomainCatalogId
		FROM Temp_VirtualTableDataListDomain vtld
		JOIN Temp_ListDomain ld
		ON ld.Old_Id = vtld.Old_DataFieldValueDomainId
		JOIN TempListDomainTable tmp
		ON vtld.VirtualTableName = tmp.TableName
		AND vtld.VirtualColumnName = tmp.ColumnName
		WHERE vtld.DomainCatalogId <> ld.DomainCatalogId OR vtld.DomainCatalogId <> tmp.DomainCatalogId
			OR ld.DomainCatalogId <> tmp.DomainCatalogId 
			OR (vtld.DomainCatalogId IS NULL OR ld.DomainCatalogId IS NULL 
			OR tmp.DomainCatalogId IS NULL AND TableName NOT LIKE ''IRASCustom%'')';			 

		EXECUTE (@SQL)

		SET @SQL = NULL

		SET @ErrorMsg = N'The New LD table name, DomainCatalogId, and/or new ListDomain Ids are inconistent in the following tables: '
		+CHAR(10) + 'Temp_VirtualTableDataListDomain, Temp_ListDomain, TempListDomainTable' + CHAR(10) + CHAR(10)
		+ 'These columns must match across these tables. ' + CHAR(10)+ CHAR(10) +'The inconsistent rows are in the Results tab' + CHAR(10);
			
		THROW 51001, @ErrorMsg, 1

	END

--------------- Data QC ActionItemPropDCXRef, RememberedListDomainValues,  CategoryDataListDomainXRef tables -------------

	IF EXISTS (SELECT * FROM sys.tables WHERE name IN ('Tmp_ActionItemPropDCXRef','Tmp_RememberedListDomainValues', 'Tmp_CategoryDataListDomainXRef'))
	BEGIN
		SET @SQL = NULL

		SELECT @SQL =  COALESCE(@SQL + ' + ', '') + '((SELECT COUNT(*) FROM ' + name + ') - (SELECT COUNT(*) FROM tmp_' + name + ')) '
		FROM sys.tables  WHERE name IN ('ActionItemPropDCXRef', 'RememberedListDomainValues', 'CategoryDataListDomainXRef')

		SELECT @SQL = 'SET @flag = ' + @SQL

		EXECUTE sp_executesql @SQL, N'@flag INT OUTPUT', @flag OUTPUT

		IF @flag <> 0
		BEGIN
			SET @SQL = NULL;
			THROW 51001, N'Some data is missing or added to the modified ActionItemPropDCXRef, RememberedListDomainValues or CategoryDataListDomainXRef tables', 1;
		END
	END

	IF OBJECT_ID('Tmp_ActionItemPropDCXRef', 'U') IS NOT NULL
	BEGIN
		DROP TABLE Tmp_ActionItemPropDCXRef
	END

	IF OBJECT_ID('Tmp_RememberedListDomainValues', 'U') IS NOT NULL
	BEGIN
		DROP TABLE Tmp_RememberedListDomainValues
	END

	IF OBJECT_ID('Tmp_CategoryDataListDomainXRef', 'U') IS NOT NULL
	BEGIN
		DROP TABLE Tmp_CategoryDataListDomainXRef
	END
END
GO

/*
	Everything below this should remain at the end of this script. Any added code should be placed above
	this section and the @FinalDBVersion variable should be changed to the last DBVersion within this script
*/
BEGIN
	DECLARE @FinalDBVersion INT 
	DECLARE @DBVersion INT 
	DECLARE @CheckPoint INT
	DECLARE @ErrorMsg NVARCHAR(600)

	SET @FinalDBVersion = 650016

	SELECT @DBVersion = DBVersion, @CheckPoint = DBVersionCheckPoint
	FROM Versioninfo

	IF EXISTS (SELECT * FROM dbo.VersionInfo WHERE DBVersion BETWEEN 640205 AND @FinalDBVersion)
		AND @DBVersion <> @FinalDBVersion AND @CheckPoint <> 0
	BEGIN

		SET @ErrorMsg = 'The database upgrade did not complete. This database is currently at DBVersion ' 
		+ CAST(@DBVersion AS NVARCHAR) + ', Checkpoint ' + CAST(@CheckPoint AS NVARCHAR);
		
		THROW 51001, @ErrorMsg, 1
	END
	ELSE
	BEGIN
		PRINT 'This database is currently at DBVersion ' + CAST(@DBVersion AS NVARCHAR) 
		+ ', Checkpoint ' + CAST(@CheckPoint AS NVARCHAR) + '.'
		+ CHAR(10) + 'This script upgrades IRAS databases from DBVersion 640205 to ' + CAST(@FinalDBVersion AS NVARCHAR);		
	END
END
GO
