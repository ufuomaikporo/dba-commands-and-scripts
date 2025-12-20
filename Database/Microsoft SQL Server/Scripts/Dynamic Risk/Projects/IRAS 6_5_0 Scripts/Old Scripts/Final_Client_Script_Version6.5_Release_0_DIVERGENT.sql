IF NOT EXISTS (SELECT * FROM dbo.SystemPreferences sp WHERE sp.ParameterName = 'DatabaseType' AND sp.Value = 'Stage')
BEGIN
	RAISERROR( 'The target database is not Stage database for applying this upgrade script.', 11, 0)
END
GO


--Script_To_Improve_Query_Performance_SQLServer.sql
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640208 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640208 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/*

			This script deletes all tables named in the variable '@List' from the database where it is executed

			*/
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
			tmpStg_ILIAxialStrain
			UnitConversion
			UnitOfMeasure'

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
							EXECUTE sp_executesql @SQL
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
	DECLARE @dbVersion varchar(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint varchar(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	DECLARE @ErrorMsg VARCHAR(MAX) = CHAR(10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO


-- 2_Modify_ListDomain_ColumnDefinition.sql
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640208 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
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

			DROP TABLE IF EXISTS ##Temp_Constraint_Definitions

			-- Table to Store Foreign Key Constraints
			IF OBJECT_ID('tempdb..##Temp_Constraint_Definitions', 'U') IS NULL
			BEGIN
				CREATE TABLE ##Temp_Constraint_Definitions (id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED, 
															table_name NVARCHAR(100),
															constraint_name NVARCHAR(100), 
															definition NVARCHAR(MAX)
															)
			END

			-- Permanent table to store commands for recreating an index
			IF OBJECT_ID('tempdb..##Temp_Index_Definition', 'U') IS NULL
			BEGIN
				CREATE TABLE ##Temp_Index_Definition (id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED, 
													  index_name NVARCHAR(100), 
													  definition NVARCHAR(MAX)
													 )
			END

			IF OBJECT_ID('tempdb..##AlterColumnList') IS NOT NULL
			BEGIN 
				DROP TABLE ##AlterColumnList
			END

			IF OBJECT_ID('tempdb..##AlterColumnList') IS  NULL
			BEGIN
				CREATE TABLE ##AlterColumnList (fk_table NVARCHAR(100), 
										  fk_column NVARCHAR(100), 
										  is_nullable NVARCHAR(15),
										  precision INT,
										  scale INT)

				INSERT INTO ##AlterColumnList
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
				
				INSERT INTO ##AlterColumnList
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
				AND NOT EXISTS (SELECT * FROM ##AlterColumnList WHERE fk_column = col.column_name 
								AND fk_table = col.table_name
								)
				AND col.table_name IN (SELECT name FROM sys.tables)
			END

			DECLARE AlterColumn_cursor CURSOR FOR
			SELECT fk_table, fk_column, is_nullable 
			FROM ##AlterColumnList
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

					SET @GetExistsCheck = 'IF EXISTS (SELECT 1 FROM ##Temp_Index_Definition WHERE index_name = ''' + @IndexName + ''')
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
						SET @CMD = 'INSERT INTO ##Temp_Index_Definition
						SELECT ' + '''' + @IndexName +  '''' + ', '+ '''' + @SQL + ''''

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
						
							SET @GetExistsCheck = 'IF EXISTS (SELECT 1 FROM ##Temp_Constraint_Definitions WHERE constraint_name = ''' + @ConstraintName + ''')
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
								EXECUTE ('INSERT INTO ##Temp_Constraint_Definitions SELECT ''' + @FK_Table  + ''', ''' + @ConstraintName + ''',''' + @SQL + '''')
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
	
				IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE WHERE table_name = @TableName AND column_name = @ColumnName )
				BEGIN
					SELECT @ConstraintName = constraint_name FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
					WHERE table_name = @TableName 
					AND column_name = @ColumnName 

					SET @ColumnList1 = NULL

					SELECT @ColumnList1 =  COALESCE(@ColumnList1 + ', ' , '' ) + column_name 
					FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE keys
					WHERE constraint_name = @ConstraintName

					SET @SQL = 'ALTER TABLE [' + @TableName + '] WITH CHECK ADD CONSTRAINT [' + @ConstraintName + '] PRIMARY KEY (' + @ColumnList1 + ')'
			
					SET @GetExistsCheck = 'IF EXISTS (SELECT 1 FROM ##Temp_Constraint_Definitions WHERE constraint_name = ''' + @ConstraintName + ''')
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
						SET @CMD = 'INSERT INTO ##Temp_Constraint_Definitions
						SELECT ''' + @TableName + ''', ''' + @ConstraintName +  ''', ''' + @SQL + ''''
						EXECUTE (@CMD)	
					END

					--Drop Primary Key
					IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE WHERE constraint_name = @ConstraintName)
					BEGIN
						SET @SQL = 'ALTER TABLE ' + @TableName + ' DROP CONSTRAINT ' + @ConstraintName
						EXECUTE sp_executesql @SQL
					END
				END

				--------------------------------------------- Modify Column Definition ---------------------------------------------------
	
				-- The column definition for the column in the current loop iteration is being modified
				SET @SQL =  'ALTER TABLE [' + @TableName + '] ALTER COLUMN [' + @ColumnName + '] NUMERIC(10,0) '  + @IsNullable
					
				EXECUTE sp_executesql @SQL
	
				FETCH NEXT FROM AlterColumn_cursor INTO @TableName, @ColumnName, @IsNullable
			END -- End of WHILE-LOOP

			CLOSE AlterColumn_cursor
			DEALLOCATE AlterColumn_cursor

			/* 
			'The FOREIGN KEY definitions have been saved to the following table: ##Temp_Constraint_Definitions'
			 'The INDEX definitions have been saved to the following table: ##Temp_Index_Definition'
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
			SELECT index_name, definition FROM ##Temp_Index_Definition

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
			FROM ##Temp_Constraint_Definitions
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640208 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 3
		BEGIN
			/*
			his script takes the ListDomain data for virtual tables and seperates them
			into various ListDomain tables with names prefixed by 'LD_' or 'GLD_' in the 'DRAS' schema. 
			'GLD_' tables share ListDomain data with other tables whereas 'LD_' tables have only one table
			referencing them. 

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
			DECLARE @NewLine NVARCHAR(100) = CHAR(10) + CHAR(9) + CHAR(9) + CHAR(9) + CHAR(9);

			---------------------------------- Create/Define Temporary tables ---------------------------------
			IF OBJECT_ID('VirtualTableDataListDomain', 'U') IS NOT NULL
			BEGIN

				IF OBJECT_ID ('Tempdb..##NewDomainTableList') IS NOT NULL
				BEGIN
					DROP TABLE ##NewDomainTableList
				END

				IF OBJECT_ID ('Tempdb..##NewDomainTableList') IS NULL
				BEGIN

					CREATE TABLE ##NewDomainTableList (VirtualColumnId INT,
													   VirtualTableId INT,
													   NewTableName NVARCHAR(100),
													   DomainCatalogId INT)

					INSERT INTO ##NewDomainTableList
					SELECT DISTINCT vc.Id AS VirtualColumnId,
							VirtualTableId,
							'LD_' + VirtualColumnname,
							NULL
					FROM VirtualColumn vc
					JOIN VirtualTable vt
						ON vc.VirtualTableId =vt.Id
					WHERE VirtualColumnDataTypeInd = 'L'
				END

				UPDATE ##NewDomainTableList
				SET NewTableName = REPLACE(REPLACE(NewTableName, 'Remediation', 'Remed'), 'Reinforcement', 'Reinforce')
				WHERE LEN(NewTableName) > 30

			/**************************************************************************************************
												VALIDATE LISTDOMAIN DATA
			**********************************************************************************************/

				DECLARE NewDomainTableList CURSOR FOR
				SELECT VirtualColumnId, VirtualTableId, NewTableName, DomainCatalogId 
				FROM ##NewDomainTableList

				OPEN NewDomainTableList
				FETCH FROM NewDomainTableList INTO @VirtualColumnId, @VirtualTableId, @NewTableName, @DomainCatalogId

				WHILE @@FETCH_STATUS = 0
				BEGIN
					SET @SQL = 'SELECT @Result = VirtualColumnName 
					FROM VirtualColumn WHERE id = ' + CAST(@VirtualColumnId AS NVARCHAR)

					EXECUTE sp_executesql @SQL, N'@Result NVARCHAR(100) OUT', @VirtualColumnName OUT

					SET @SQL = 'SELECT @Result = VirtualTableName 
					FROM VirtualTable WHERE Id = ' + CAST(@VirtualTableId AS NVARCHAR)

					EXECUTE sp_executesql @SQL, N'@Result NVARCHAR(100) OUT', @VirtualTableName OUT

					SET @DomainCatalogId = NULL

					SET @SQL = 'SELECT @Result = DomainCatalogId 
					FROM DomainCatalogColXRef 
					WHERE TableName = ''' + @VirtualTableName + '''
					AND ColumnName = ''' + @VirtualColumnName + ''''

					EXECUTE sp_executesql @SQL, N'@Result INT OUT', @DomainCatalogId OUT

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

						RAISERROR('There is are more than 1 domain categories for virtual table ----> ''%s'' and virtual column %s.%sOnly domain category can be assigned for the column-table combination for this script to continue', 11, 0, 
						@VirtualTableName, @VirtualColumnName, @NewLine)

					END

					UPDATE ##NewDomainTableList
					SET DomainCatalogId = @DomainCatalogId
					WHERE VirtualColumnId = @VirtualColumnId
					AND VirtualTableId = @VirtualTableId

				-------------------------------------------- CREATE THE NEW LIST DOMAIN TABLES ----------------------------------
	
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
									[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
									CONSTRAINT [PK_' + @NewTableName + '] PRIMARY KEY NONCLUSTERED 
									(
										[Id] ASC
									)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
									) ON [PRIMARY]';

						EXECUTE sp_executesql @SQL;

					END;

					-- Recreate update trigger on new listdomain table table
					IF OBJECT_ID ( 'tu_' + @NewTableName + '', 'TR') IS NULL
					BEGIN
						SET @SQL = 'CREATE TRIGGER [tu_' + @NewTableName + '] ON [' + @NewTableName + '] FOR UPDATE AS 
						IF EXISTS(SELECT * FROM DELETED)
						BEGIN
							UPDATE ' + @NewTableName + '
							SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
							FROM ' + @NewTableName + ' as t, DELETED as d
							WHERE t.Id=d.Id;
						END'

						EXECUTE sp_executesql @SQL
					END

				-------------------------------- POPULATE NEW DOMAIN TABLE WITH DATA FROM LISTDOMAIN TABLE ----------------------------------------

					-- Populate the new list domain table if it is empty (Ensures the ListDomain Id is unique)
					SET @SQL = 'IF (SELECT COUNT(*) FROM ' + @NewTableName + ') = 0
								BEGIN 
					
								-- Copy data into new list domain table
								SET IDENTITY_INSERT ' + @NewTableName + ' ON;
					
								WITH tmpQuery AS
								(SELECT Id,
										Code,
										Descr,
										DomainCatalogId
								 FROM dbo.ListDomain
								 WHERE Id IN (SELECT DISTINCT DataFieldValueDomainId 
												FROM VirtualTableDataListDomain
												WHERE VirtualTableId = ' + CAST(@VirtualTableId AS NVARCHAR) + '
												AND VirtualColumnId = ' + CAST(@VirtualColumnId AS NVARCHAR) + ')
								UNION
								SELECT Id,
									   Code,
									   Descr,
									   DomainCatalogId
								FROM dbo.ListDomain
								WHERE DomainCatalogId = ' + CAST(@DomainCatalogId AS NVARCHAR) + '
								)
								INSERT INTO ' + @NewTableName + ' (Id, Code, Descr, EffectiveEndDate)
								SELECT Id, 
										CASE
										WHEN Code = '''' THEN ''<None>''
										ELSE Code
										END AS Code, 
										CASE 
										WHEN Code = '''' THEN ''<None>''
										ELSE Descr
										END AS Descr,
										CASE 
											WHEN DomainCatalogId = -1 THEN GETDATE()
											ELSE NULL
										END AS EffectiveEndDate
								FROM tmpQuery
								WHERE Id NOT IN (SELECT Id FROM ' + @NewTableName + ')
					
								SET IDENTITY_INSERT ' + @NewTableName + ' OFF
							END';

					EXECUTE sp_executesql @SQL;	 

					FETCH FROM NewDomainTableList INTO @VirtualColumnId, @VirtualTableId, @NewTableName, @DomainCatalogId
				END

				CLOSE NewDomainTableList
				DEALLOCATE NewDomainTableList

				------------------------------- CREATE AND/OR UPDATE the TempListDomainTable table ------------------------

				-- Create temporary table in config databases to store list domain info
				SET @SQL = 'IF OBJECT_ID(''dbo.TempListDomainTable'') IS NOT NULL
							BEGIN
								DROP TABLE dbo.TempListDomainTable
							END'

				EXECUTE sp_executesql @SQL

				SET @SQL = 'IF OBJECT_ID(''dbo.TempListDomainTable'') IS NULL
							BEGIN
								CREATE TABLE dbo.TempListDomainTable (TableType VARCHAR(50),
																		ListDomainTableName VARCHAR(100),
																		ReferencedTableName VARCHAR(50),
																		ReferencedColumnName VARCHAR(50),
																		DomainCatalogId INT,
																		DomainDescr VARCHAR(255)
																		)
						
									INSERT INTO dbo.TempListDomainTable
									SELECT ''Virtual'' AS TableType,
											nld.NewTableName,
											vt.VirtualTableName AS ReferencedTableName,
											vc.VirtualColumnName AS ReferencedColumnName,
											DomainCatalogId,
											(SELECT DomainDescr FROM DomainCatalog WHERE Id = nld.DomainCatalogId) As DomainDescr	
									FROM ##NewDomainTableList nld
									LEFT JOIN dbo.VirtualTable vt 
										ON nld.VirtualTableId = vt.Id
									JOIN dbo.VirtualColumn vc
										ON nld.VirtualColumnId = vc.Id
							END'
			
				EXECUTE sp_executesql @SQL

			END
			----------------------------- DROP FK on VirtualTableDataListDomain referencing ListDomain table -------------------------------

			IF OBJECT_ID('dbo.VirtualTableDataListDomain', 'U') IS NOT NULL
			BEGIN
				-- Drop Foreign Key Referencing the ListDomain table if it exists
				IF EXISTS (SELECT 1
								FROM sys.foreign_key_columns
								WHERE OBJECT_NAME(referenced_object_id) = 'ListDomain'
								AND OBJECT_NAME(parent_object_id) = 'VirtualTableDataListDomain'
							) AND EXISTS (SELECT 1 FROM TempListDomainTable WHERE TableType = 'Virtual')
				BEGIN
					-- Drop foreign key
					SELECT @SQL = 'ALTER TABLE dbo.VirtualTableDataListDomain DROP CONSTRAINT ' +  OBJECT_NAME(constraint_object_id)
									FROM sys.foreign_key_columns
									WHERE OBJECT_NAME(referenced_object_id) = 'ListDomain'
									AND OBJECT_NAME(parent_object_id) = 'VirtualTableDataListDomain'

					EXECUTE sp_executesql @SQL
			
				END

				IF OBJECT_ID ('Tempdb..##NewDomainTableList') IS NOT NULL
				BEGIN
					DROP TABLE ##NewDomainTableList
				END
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640208 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 4
		BEGIN
			--5_Create_NewListDomainTables.sql
			/*

			This script takes the ListDomain data for all tables referencing the ListDomain table and seperates them
			into new tables prefixed with 'GLD_' for shared data or 'LD_' for non-shared data. 

			This script also 
			1) Takes the ListDomain data in the Category and CategoryDataListDomainXRef tables, breaks it up into smaller tables 
			with names prefixed by 'LD_CD_', then drops the Category and CategoryDataListDomainXRef tables. 
			2) Modifies the ActionItemPropDCXRef table by adding columns referencing the newly created LisDomain tables.
			3) Drops the ListDomain, DomainCatalog, and DomainCatalogColXRef tables

			This script must be executed on the target database

			*/
			DECLARE @FKConstraintName NVARCHAR(100);
			DECLARE @NewTableName NVARCHAR(100);
			DECLARE @FKTableName NVARCHAR(100);
			DECLARE @FKColumnName NVARCHAR(100);
			DECLARE @SQL NVARCHAR(MAX);
			DECLARE @StageDB NVARCHAR(100);
			DECLARE @ConfigDB NVARCHAR(100);
			DECLARE @Count INT
			DECLARE @DomainCatalogId INT;
			DECLARE @CategoryId INT;
			DECLARE @DomainDescr NVARCHAR(200);
			DECLARE @NewLine NVARCHAR(100) = CHAR(10) + CHAR(9) + CHAR(9) + CHAR(9) + CHAR(9);

			/*************************************************************************************************
								CREATE New Listdomain tables & Populate the new tables with Data
			**************************************************************************************************/

			IF EXISTS(SELECT 1 FROM sys.tables WHERE name IN ('DomainCatalog', 'ListDomain')) 
			BEGIN

				IF OBJECT_ID('tempdb..##ListDomainInfo') IS NOT NULL
				BEGIN
					DROP TABLE ##ListDomainInfo
				END

				IF OBJECT_ID('tempdb..##ListDomainInfo') IS NULL
				BEGIN
					CREATE TABLE ##ListDomainInfo ( Id INT, 
													DomainCatalogId INT,
													Code NVARCHAR(60),  
													Descr NVARCHAR(255));
				END

				IF OBJECT_ID('tempdb..##NewDomainTableList') IS NOT NULL
				BEGIN
					DROP TABLE ##NewDomainTableList;
				END;

				/*
					Generates a list of all child tables with a foreign key constraint referencing the 
					ListDomain table and store the results in a temporary table
				*/

				IF OBJECT_ID ('tempdb..##NewDomainTableList') IS NULL 
				BEGIN
					CREATE TABLE ##NewDomainTableList  (Id INT IDENTITY(1,1),
										FKConstraint NVARCHAR(100),
										FKTableName NVARCHAR(100),
										FKColumnName NVARCHAR(100),
										NewListDomainTable NVARCHAR(100),
										DomainCatalogId INT,
										DomainDescr NVARCHAR(MAX),
										flag BIT
										);

					SET @SQL = '
						INSERT INTO ##NewDomainTableList (FKConstraint, FKTableName, FKColumnName)
						SELECT OBJECT_NAME(fkc.constraint_object_id),
								OBJECT_NAME(fkc.parent_object_id) AS fk_table,
								COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS fk_column
						FROM sys.foreign_key_columns fkc
						JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
							ON kcu.constraint_name = OBJECT_NAME(fkc.constraint_object_id)
							AND kcu.column_name = COL_NAME(fkc.parent_object_id, fkc.parent_column_id)
						JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
						JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id
						WHERE OBJECT_NAME(fkc.referenced_object_id) LIKE ''ListDomain''
						AND OBJECT_NAME(fkc.parent_object_id) NOT IN (''RememberedListDomainValues'', ''VirtualTableDataListDomain'', ''ActionItemPropDCXRef'', ''CategoryDataListDomainXRef'')
						'

					EXECUTE sp_executesql @SQL

				END

				---------------------------- Tables that are included as exceptions ----------------------------

				-- Tables that are missing a foreign key reference to the ListDomain table

				INSERT INTO ##NewDomainTableList (FKConstraint, FKTablename, FKColumnName)
				VALUES ('FK_POECompLookup_MetalLossTypeDomain', 'POECompanyLookUp', 'MetalLossTypeDomainId')

				INSERT INTO ##NewDomainTableList (FKConstraint, FKTablename, FKColumnName)
				VALUES ('FK_POECompLookup_ToolTypeDomain', 'POECompanyLookUp', 'ToolTypeDomainId')

				INSERT INTO ##NewDomainTableList (FKConstraint, FKTablename, FKColumnName)
				VALUES ('FK_StgILICA_ILICADepthDomain', 'Stg_ILICrackAnomaly', 'ILICADepthDomainId')
				
				-- LD tables that will not have a foreign key referencing them but are necessary for App function
				INSERT INTO ##NewDomainTableList (DomainDescr, DomainCatalogId, NewListDomainTable)
				SELECT DISTINCT dc.DomainDescr, 
							 dc.Id,
							 ldi.LDTableName
				FROM  SQL2019.DrasInternal.dbo.ListDomainTableInfo ldi
				JOIN DomainCatalog dc
					ON ldi.DomainDescr = dc.DomainDescr
				WHERE dc.DomainDescr LIKE '%PMM%'
				OR dc.Id IN (SELECT DomainCatalogId FROM ActionItemPropDCXRef)

				-------------- Get the New ListDomain table names from the ListDomainTableInfo table -----------------------------------------------------

				-- Get the new ListDomain table name from SQL2019.DrasInternal.dbo.ListDomainTableInfo  (matching tableName and columnName)
				UPDATE ##NewDomainTableList
				SET NewListDomainTable = tab2.LDTableName,
					DomainDescr = tab2.DomainDescr,
					DomainCatalogId = tab3.Id
				FROM ##NewDomainTableList tab1
				JOIN SQL2019.DrasInternal.dbo.ListDomainTableInfo tab2
					ON tab1.FKColumnName = tab2.ColumnName
					AND tab1.FKTableName = tab2.TableName
				JOIN DomainCatalog tab3
					ON tab2.DomainDescr = tab3.DomainDescr
				WHERE tab2.flag = 0 AND FKTableName NOT LIKE 'IRASCustom%'

				-- Get the new ListDomain table name from SQL2019.DrasInternal.dbo.ListDomainTableInfo (matching only column name if there are no tablename matches)
				UPDATE ##NewDomainTableList
				SET NewListDomainTable = tab2.LDTableName,
					DomainDescr = tab2.DomainDescr
				FROM ##NewDomainTableList tab1
				JOIN SQL2019.DrasInternal.dbo.ListDomainTableInfo tab2
					ON tab1.FKColumnName = tab2.ColumnName
				WHERE tab2.flag = 0 AND tab1.NewListDomainTable IS NULL

				--Generate an LD table name for tables that could not be matched with an LD table name in the SQL2019.DrasInternal.dbo.ListDomainTableInfo database
				UPDATE ##NewDomainTableList
				SET NewListDomainTable = (CASE WHEN PATINDEX('%_DomainId', FKColumnName) > 0
								THEN 'LD_' + REPLACE(REPLACE(FKColumnName, '_DomainId', ''), 'DomainId', '') 
							WHEN PATINDEX('%Ld', FKColumnName) > 0
								THEN 'LD_' + REPLACE(FKColumnName, 'Ld', '')
							ELSE 'LD_' + FKColumnName
						END)
				WHERE NewListDomainTable IS NULL

				DECLARE LDTables_Cursor CURSOR FOR
				SELECT FKTableName,
					   FKColumnName,
					   NewListDomainTable,
					   DomainCatalogId
				FROM ##NewDomainTableList

				OPEN LDTables_Cursor
				FETCH NEXT FROM LDTables_Cursor INTO @FKTableName, @FKColumnName, @NewTableName, @DomainCatalogId

				WHILE @@FETCH_STATUS = 0
				BEGIN
				--------------------- 1) ListDomain source-table columns that can be found in DomainCAtalogXRef table
	
					-- Store all ListDomain table entries for the table and column in the current loop iteration into a temporary table
					SET @SQL = 'DELETE FROM ##ListDomainInfo

									INSERT INTO ##ListDomainInfo (Id, DomainCatalogId, Code, Descr)
									SELECT Id,
											DomainCatalogId,
											Code,
											Descr
									FROM ListDomain
									WHERE Id IN (SELECT DISTINCT ' + @FKColumnName + ' FROM ' + @FKTableName+ ')'

					EXECUTE sp_executesql @SQL

					-- Get the DomainCatalogId FROM the ##NewDomainTableList			
					SELECT @DomainCatalogId = DomainCatalogId, @DomainDescr = dc.DomainDescr
					FROM ##NewDomainTableList nld
					JOIN DomainCatalog dc
						ON dc.Id = nld.DomainCatalogId
					WHERE FKTableName = @FKTableName
					AND FKColumnName = @FKColumnName 

					-- If the DomainCatalogId is null in the ##NewDomainTableList table get it from the DomainCatalogColXRef table
					IF (@DomainCatalogId IS NULL)
					BEGIN
						SELECT @DomainCatalogId = dcxr.DomainCatalogId, @DomainDescr = dc.DomainDescr 
						FROM DomainCatalogColXRef dcxr
						JOIN DomainCatalog dc
							ON dc.Id = dcxr.DomainCatalogId
						WHERE TableName = @FKTableName
						AND ColumnName = @FKColumnName

					END

					--Get the DomainCatalogId from the ListDomain table if it does not exist in DomainCatalogColXRef table and there are no conflicts
					IF (@DomainCatalogId IS NULL) AND (SELECT COUNT(DISTINCT DomainCatalogId) FROM ##ListDomainInfo WHERE DomainCatalogId <> -1) = 1	
					BEGIN
						SELECT @DomainCatalogId = DomainCatalogId FROM ##ListDomainInfo
						SELECT @DomainDescr = DomainDescr FROM DomainCatalog WHERE Id = @DomainCatalogId
					END

					--Use the DomainDescr from the ListDomainTableInfo in the DrasInternal database to find the DomainCatalogId in the DomainCatalog table
					IF (@DomainCatalogId IS NULL) 
						AND (SELECT COUNT(DISTINCT DomainDescr) FROM SQL2019.DrasInternal.dbo.ListDomainTableInfo 
							 WHERE ColumnName = @FKColumnName AND DomainCatalogId IS NOT NULL) = 1
					BEGIN
						SELECT @DomainCatalogId = Id FROM DomainCatalog 
						WHERE DomainDescr = (SELECT TOP 1 DomainDescr FROM SQL2019.DrasInternal.dbo.ListDomainTableInfo 
											WHERE ColumnName = @FKColumnName AND DomainCatalogId IS NOT NULL)
						
						SELECT @DomainDescr = DomainDescr FROM DomainCatalog WHERE Id = @DomainCatalogId
					END

					/*
						If the table and column in the current loop has an entry in the DomainCatalogColXRef table
						and more than 1 distinct DomainCatalogIds (other than -1) in it's ListDomain table entries,
						throw an error and force the user to fix the issue manually
					*/
					IF (@DomainCatalogId IS NOT NULL) AND (SELECT COUNT(DISTINCT DomainCatalogId) FROM ##ListDomainInfo WHERE DomainCatalogId <> -1) >= 2
					BEGIN

						PRINT CHAR(10) + 'ERROR: More than 1 distinct DomainCatalogId was found in the Listdomain table for the '''  
										+ @FKColumnName + ''' column' + CHAR(10) + CHAR(9) + CHAR(9) + 'of the ''' + @FKTableName + ''' table'
										+ '. ONLY 1 distinct DomainCatalogId is allowed. A manual fix is required for the script to continue'
										+ CHAR(10) + CHAR(9) + CHAR(9) + 'The query below shows all the ListDomain table entries for the table-column combination mentioned' + CHAR(10)
		
						PRINT 'QUERY: SELECT * FROM ##ListDomainInfo' + CHAR(10)

						PRINT 'SOLUTION: An entry was found in the DomainCatalogColXRef table. Replace the values in the column ''' + @FKColumnName + ''''
								+ CHAR(10) + CHAR(9) + CHAR(9) + 'of table ''' + @FKTableName + '''' 
								+ ' with Ids from the ListDomain table that have the appropriate Code, Descr, '
								+ CHAR(10) + CHAR(9) + CHAR(9) + 'and a DomainCatalogId of ' + CAST(@DomainCatalogId AS NVARCHAR) + '.' 
									+ ' You can modify and use the following command.' + CHAR(10) 
						PRINT 'COMMAND: UPDATE ' + @FKTableName + ' SET ' + @FKColumnName + ' = {NewListDomainId}' + CHAR(10) +
							'		 WHERE ' + @FKColumnName + ' = {OldListDomainId}' + CHAR(10)
				
						SET @SQL = ''
						DEALLOCATE LDTables_Cursor

						RAISERROR('There are duplicate DomainCatalogIds in the ListDomain table for the ''%s'' column %sof the ''%s'' table. You must manually fix the issue before re-running the script', 11, 0, @FKColumnName, @NewLine, @FKTableName)
							
					END
					/*
						if the table and column in the current iteration has no entry in the DomainCatalogColXRef 
						table and there are more than 1 distinct DomainCatalogIds in it's entries in the ListDomain table, 
						then throw an error to force user to manually fix the issue
					*/
					ELSE IF (@DomainCatalogId IS NULL) AND (SELECT COUNT(DISTINCT DomainCatalogId) FROM ##ListDomainInfo WHERE DomainCatalogId <> -1) >= 2
					BEGIN
						PRINT CHAR(10) + 'ERROR: More than 1 distinct DomainCatalogId was found in the Listdomain table for Column ---> '  
										+ @FKColumnName + CHAR(10) + CHAR(9) + CHAR(9) + 'of the ''' + @FKTableName + ''' table'
										+ '. ONLY 1 distinct DomainCatalogId is allowed. A manual fix is required for the script to continue'
										+ CHAR(10) + CHAR(9) + CHAR(9) + 'The query below shows all the ListDomain table entries for the table-column combination mentioned' + CHAR(10)
		
						PRINT 'QUERY: SELECT * FROM ##ListDomainInfo' + CHAR(10)
		
						PRINT 'SOLUTION: A reference could not be found in the DomainCatalogColXRef table for column ''' + @FKColumnName + ''''
							+ CHAR(10) + CHAR(9) + CHAR(9) + 'of table ''' + @FKTableName + '''. '
							+ 'Talk to the BA assigned to the client for this database.' 
							+ CHAR(10) + CHAR(9) + CHAR(9) + 'You may need to set some values in ''' + @FKColumnName+ ''' column of ''' + @FKTableName + ''' table to NULL' + CHAR(10)	
	
						SET @SQL = ''
						DEALLOCATE LDTables_Cursor

						RAISERROR('There are duplicate DomainCatalogIds in the ListDomain table for the ''%s'' column %sof the ''%s'' table. You must manually fix the issue before re-running the script', 11, 0, @FKColumnName, @NewLine, @FKTableName)

					END
			
					-- Update DomainCatalogIds in ##NewDomainTableList use DomainDescr 
					UPDATE ##NewDomainTableList
					SET DomainCatalogId = CASE WHEN @DomainCatalogId IS NULL	
												THEN (SELECT Id FROM DomainCatalog WHERE DomainDescr = ndt.DomainDescr)
											   ELSE @DomainCatalogId
											END,
						DomainDescr = @DomainDescr
					FROM ##NewDomainTableList ndt
					WHERE FKTableName = @FKTableName
					AND FKColumnName = @FKColumnName
					AND DomainCatalogId IS NULL
					AND FKTableName NOT LIKE 'IRASCustom%'

					-- Assign the new list domain table name from ##NewDomainTableList table to variable
					SELECT @NewTableName = NewListDomainTable 
					FROM ##NewDomainTableList
					WHERE FKTableName = @FKTableName
						AND FKColumnName = @FKColumnName
	
	
				/*****************************************************************************************
									Create and Populate New List Domain Tables 
				**********************************************************************************************/
	
				-------------------------------------- CREATE New ListDomain tables ---------------------------------------

					-- Create the new list domain table if it does not already exist
					IF OBJECT_ID(@NewTableName, 'U') IS NULL
					BEGIN
						SET @SQL = 'CREATE TABLE [dbo].' +QUOTENAME( @NewTableName) + '(
						[Id] numeric(10, 0) IDENTITY(1,1) NOT NULL,
						[Code] varchar(60) NOT NULL,
						[Descr] varchar(255) NOT NULL,
						[EffectiveEndDate] Datetime,
						[CreatedUser] varchar(45) DEFAULT (suser_sname()) NOT NULL,
						[CreatedDate] datetime DEFAULT (getdate()) NOT NULL,
						[LastModByUserId] varchar(45) DEFAULT (suser_sname()) NOT NULL,
						[LastModDateTime] datetime DEFAULT (getdate()) NOT NULL,
						CONSTRAINT [PK_' + @NewTableName + '] PRIMARY KEY CLUSTERED (Id)
						)';

						EXECUTE sp_executesql @SQL
			
						-- Recreate update trigger on new listdomain table table
						IF OBJECT_ID ('tu_' + @NewTableName + '', 'TR') IS NULL
						BEGIN
							SET @SQL = 'CREATE TRIGGER [dbo].[tu_' + @NewTableName + '] ON [dbo].[' + @NewTableName + '] FOR UPDATE AS 
							IF EXISTS(SELECT * FROM DELETED)
							BEGIN
								UPDATE dbo.' + @NewTableName + '
								SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
								FROM dbo.' + @NewTableName + ' as t, DELETED as d
								WHERE t.Id=d.Id;
							END'

							EXECUTE sp_executesql @SQL
						END
					END; -- End create new list domain table
					
				---------------------------------- Populate the New List Domain Table ----------------------------------

					-- Populate the new list domain table
					IF (@FKColumnName IS NOT NULL)
					BEGIN
						SET @SQL = 'SET IDENTITY_INSERT ' + @NewTableName + ' ON;
				
									WITH tmpQuery AS 
									(SELECT Id,
											DomainCatalogId,
											Code,
											Descr
									FROM ListDomain
									WHERE Id IN (SELECT DISTINCT ' + @FKColumnName + ' FROM ' + @FKTableName + ')
									UNION
									SELECT Id,
											DomainCatalogId,
											Code,
											Descr
									FROM ListDomain WHERE DomainCatalogId = ' + CAST(@DomainCatalogId AS NVARCHAR) +'
									AND Code NOT IN (SELECT Code FROM ' + @NewTableName + ')
									) 
									INSERT INTO ' + @NewTableName + ' (Id, Code, Descr, EffectiveEndDate)
									SELECT Id,
											CASE 
											WHEN Code = '''' THEN ''<None>''
											ELSE Code
											END AS Code,
											CASE 
											WHEN Code = '''' THEN ''<None>''
											ELSE ISNULL(Descr, ''<None>'')
											END AS Descr,
											CASE 
												WHEN DomainCatalogId = -1 THEN GETDATE()
												ELSE NULL
											END AS EffectiveEndDate
									FROM tmpQuery
									WHERE Id NOT IN (SELECT Id FROM ' + @NewTableName + ')
									ORDER BY 1

									SET IDENTITY_INSERT ' + @NewTableName + ' OFF'
					END
					ELSE 
					BEGIN
						SET @SQL = 'SET IDENTITY_INSERT ' + @NewTableName + ' ON;
				
									WITH tmpQuery AS 
									(SELECT Id,
											DomainCatalogId,
											Code,
											Descr
									FROM ListDomain WHERE DomainCatalogId = ' + CAST(@DomainCatalogId AS NVARCHAR) +'
									AND Code NOT IN (SELECT Code FROM ' + @NewTableName + ')
									)
									INSERT INTO ' + @NewTableName + ' (Id, Code, Descr, EffectiveEndDate)
									SELECT Id,
											CASE 
											WHEN Code = '''' THEN ''<None>''
											ELSE Code
											END AS Code,
											CASE 
											WHEN Code = '''' THEN ''<None>''
											ELSE ISNULL(Descr, ''<None>'')
											END AS Descr,
											CASE 
												WHEN DomainCatalogId = -1 THEN GETDATE()
												ELSE NULL
											END AS EffectiveEndDate
									FROM tmpQuery
									WHERE Id NOT IN (SELECT Id FROM ' + @NewTableName + ')
									ORDER BY 1
						
									SET IDENTITY_INSERT ' + @NewTableName + ' OFF'
					END

					EXECUTE sp_executesql @SQL
			

					/*
					Force data into new ListDomain table for tables that are missing parent entries in ListDomain table.
					This forced data will not be meaningful having a code and descr of 'N/A'	
					*/
					SET @SQL = '
					
					DROP TABLE IF EXISTS tmp_table

					SELECT DISTINCT ' + @FKColumnName + ' Id
					INTO tmp_table
					FROM ' + @FKTableName + ' tab1
					WHERE NOT EXISTS (SELECT Id FROM ' + @NewTableName + ' WHERE Id = tab1.' + @FKColumnName + ')
					AND ' + @FKColumnName + ' IS NOT NULL

					SET IDENTITY_INSERT dbo.' + @NewTableName + ' ON

					INSERT INTO dbo.' + @NewTableName + ' (id, Code, Descr, EffectiveEndDate, CreatedUser, CreatedDate, LastModByUserId, LastModDateTime)
					SELECT Id, ''N/A'', ''N/A'', NULL, SUSER_SNAME(), GETDATE(), SUSER_SNAME(), GETDATE()
					FROM tmp_table
					
					SET IDENTITY_INSERT dbo.' + @NewTableName + ' OFF'

					EXECUTE sp_executesql @SQL
				
				-------------------------------- UPDATE TempListDomainTable  ---------------------------------------

					-- Create TempListDomainTable table in Config database if it doesn't already exist
					SET @SQL = 'IF OBJECT_ID(''TempListDomainTable'', ''U'') IS NULL
								BEGIN
									CREATE TABLE dbo.TempListDomainTable (TableType VARCHAR(50),
																							ListDomainTableName VARCHAR(100),
																							ReferencedTableName VARCHAR(50),
																							ReferencedColumnName VARCHAR(50),
																							DomainCatalogId INT,
																							DomainDescr VARCHAR(255)
																							)
								END'

					EXECUTE sp_executesql @SQL

					-- Insert entries for table and column in current loop iteration into TempListDomainTable
					IF (@FKColumnName IS NOT NULL)
					BEGIN 
						IF NOT EXISTS (SELECT 1 FROM TempListDomainTable WHERE TableType = 'Real' 
										AND ReferencedTableName = @FKTableName AND ReferencedColumnName = @FKColumnName
										AND ListDomainTableName = @NewTableName)
						BEGIN
			
							INSERT INTO TempListDomainTable
							SELECT 'Real',
									@NewTableName,
									@FKTableName,
									@FKColumnName,
									@DomainCatalogId,
									(SELECT DomainDescr FROM DomainCatalog WHERE Id = @DomainCatalogId)
						END
					END
					ELSE
					BEGIN
						IF NOT EXISTS (SELECT 1 FROM TempListDomainTable WHERE TableType = 'Real' 
									AND ListDomainTableName = @NewTableName)
						BEGIN
							INSERT INTO TempListDomainTable
							SELECT 'Real',
									@NewTableName,
									NULL,
									NULL,
									@DomainCatalogId,
									(SELECT DomainDescr FROM DomainCatalog WHERE Id = @DomainCatalogId)
						END
					END
				--------------------------- REMOVE FOREIGN KEYS FROM TABLES REFERENCING LISTDOMAIN TABLE -------------------------------
		
					SELECT @FKConstraintName = FKConstraint FROM ##NewDomainTableList
											WHERE FKTableName = @FKTableName
											AND FKColumnName = @FKColumnName

					-- Drop the foreign key on the domain child table if it references the ListDomain table
					IF EXISTS (SELECT 1 FROM sys.foreign_key_columns
								WHERE OBJECT_NAME(constraint_object_id) = @FKConstraintName
								AND OBJECT_NAME(referenced_object_id) = 'ListDomain') AND EXISTS (SELECT 1 FROM ##NewDomainTableList)
					BEGIN
						SET @SQL = 'ALTER TABLE ' + @FKTableName + ' DROP CONSTRAINT ' + @FKConstraintName;
						EXECUTE sp_executesql @SQL;	
					END;

				---------------------------------- RECREATE FOREIGN KEYS ON NEW LIST DOMAIN TABLES -------------------------------------------------------------
	
					-- recreate foreign keys on domain child table to reference new domain table
					IF OBJECT_ID(@FKConstraintName, 'F') IS NULL
					BEGIN
						SET @SQL = 'ALTER TABLE ' + @FKTableName + ' ADD CONSTRAINT ' + @FKConstraintName + ' FOREIGN KEY (' + @FKColumnName + ') 
									REFERENCES ' + @NewTableName + '(Id)';
						EXECUTE sp_executesql @SQL;
					END;
				
	
					FETCH NEXT FROM LDTables_Cursor INTO @FKTableName, @FKColumnName, @NewTableName, @DomainCatalogId

				END
				CLOSE LDTables_Cursor
				DEALLOCATE LDTables_Cursor

			END 

			/***************************************************************************************************
						 DROP all LD/GLD tables that do not have a foreign key referencing them 
			****************************************************************************************************/
			
			DECLARE DeleteTable_Cursor CURSOR FOR 
			SELECT 'IF OBJECT_ID(''' + SCHEMA_NAME(schema_id ) + '.' + name + ''', ''U'') IS NOT NULL
			BEGIN
				DROP TABLE ' + SCHEMA_NAME(schema_id ) + '.' + name  + '
			END'
			FROM sys.tables 
			WHERE (name like 'LD[_]%' OR name like 'GLD[_]%')
			AND name NOT IN (SELECT OBJECT_NAME(referenced_object_id) FROM sys.foreign_keys)
			AND name NOT LIKE '%PMM%Type%'
			AND name NOT IN (SELECT ListDomainTableName FROM TempListDomainTable WHERE TableType = 'Virtual')

			OPEN DeleteTable_Cursor
			FETCH NEXT FROM DeleteTable_Cursor INTO @SQL

			WHILE @@FETCH_STATUS = 0
			BEGIN
				EXECUTE sp_executesql @SQL
				FETCH NEXT FROM DeleteTable_Cursor INTO @SQL
			END

			CLOSE DeleteTable_Cursor
			DEALLOCATE DeleteTable_Cursor

			-- Check if all foreign keys referencing the ListDomain table have been dropped before continuing
			IF EXISTS (SELECT 1 FROM sys.foreign_key_columns fkc 
						WHERE OBJECT_NAME(referenced_object_id) = 'ListDomain'
						AND OBJECT_NAME(parent_object_id) NOT IN ('RememberedListDomainValues', 'ActionItemPropDCXRef', 'CategoryDataListDomainXRef'))
			BEGIN
				SET @SQL = 'THROW 51001, N''The script did not complete its execution due to existing foreign keys referencing the ListDomain table.' +
				CHAR(10) + 'Make sure the Virtual tables ListDomain script has been executed first'', 1;'
				EXECUTE sp_executesql @SQL
			END

			return
			/*************************************************************************************************
								CREATE New Tables for CategoryDataListDomainXRef Table
			**************************************************************************************************/
			select 'chept 1'
			IF COL_LENGTH('CategoryDataListDomainXRef', 'ListDomainTableName') IS NULL 
				AND OBJECT_ID('CategoryDataListDomainXRef') IS NOT NULL
			BEGIN
				--Save the data 
				IF OBJECT_ID('Temp_CategoryDataListDomainXRef') IS NOT NULL
				BEGIN
					DROP TABLE Temp_CategoryDataListDomainXRef;
				END

							select 'chept 2'
				SELECT cdl.Id,
					   (SELECT DISTINCT DomainCatalogId 
						FROM ##NewDomainTableList
					    WHERE DomainCatalogId = ld.DomainCatalogId
						AND ld.DomainCatalogId <> -1
					   ) AS ListDomainTableName,
					   ValueDomainId,
					   CategoryId,
					   NULL CreatedUser,
					   GetDate() CreatedDate,
					   cdl.LastModBYUserId,
					   cdl.LastModDateTime
				--INTO Temp_CategoryDataListDomainXRef 
				FROM CategoryDataListDomainXRef cdl
				JOIN ListDomain ld
					ON ld.Id = cdl.ValueDomainId
					order by VAlueDomainId, ListDomainTableName

				select * from CategoryDataListDomainXRef
				select * from listdomain where id = 25

				select DomainCatalogId, count(NewListDomainTable) from ##NewDomainTableList 
				group by DomainCatalogId having count(NewListDomainTable) > 1
							select 'chept 3'


				-- Delete foreign key constraints on the CategoryDataListDomainXRef table
				SELECT @SQL = STRING_AGG('ALTER TABLE ' + OBJECT_NAME(parent_object_id) 
						+ ' DROP CONSTRAINT ' + name, CHAR(10))
				FROM sys.foreign_keys 
				WHERE OBJECT_NAME(referenced_object_id) = 'CategoryDataListDomainXRef'


				EXECUTE sp_executesql @SQL

				-- Drop CategoryDataListDomainXRef table
				IF OBJECT_ID('CategoryDataListDomainXRef', 'U') IS NOT NULL
				BEGIN
					DROP TABLE CategoryDataListDomainXRef;
				END

				EXECUTE sp_rename 'dbo.Temp_CategoryDataListDomainXRef', 'CategoryDataListDomainXRef';

				--Add foreign key referencing Category table
				ALTER TABLE CategoryDataListDomainXRef WITH CHECK 
				ADD CONSTRAINT FK_CDLDXCategoryId FOREIGN KEY (CategoryId)
				REFERENCES Category(Id)

				--Add table default constraints
				SET @SQL = 'ALTER TABLE [dbo].[CategoryDataListDomainXRef] ADD  DEFAULT (SUSER_SNAME()) FOR [CreatedUser]
				ALTER TABLE [dbo].[CategoryDataListDomainXRef] ADD  DEFAULT (GETDATE()) FOR [CreatedDate]
				ALTER TABLE [dbo].[CategoryDataListDomainXRef] ADD  DEFAULT (SUSER_SNAME()) FOR [LastModByUserId]
				ALTER TABLE [dbo].[CategoryDataListDomainXRef] ADD  DEFAULT (GETDATE()) FOR [LastModDateTime]'

				EXECUTE sp_executesql @SQL

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

			--IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.columns WHERE Table_Name = 'RememberedListDomainValues'
			--				AND Column_Name = 'ListDomainTableName') AND OBJECT_ID('RememberedListDomainValues', 'U') IS NOT NULL
			--BEGIN

			--	IF OBJECT_ID('tempdb..##RememberedListDomainValues') IS NOT NULL
			--	BEGIN
			--		DROP TABLE ##RememberedListDomainValues;
			--	END

			--	-- Copy data from RememberedListDomainValues into temporary table
			--	SET @SQL = 'SELECT Id, 
			--		   DomainValue,
			--		   ListDomainId,
			--		   (SELECT TOP 1 NewListDomainTable FROM ##NewDomainTableList
			--			WHERE DomainCatalogId = rldv.DomainCatalogId) AS ListDomainTableName,
			--			CreatedUser,
			--			CreatedDate,
			--			LastModByUserId,
			--			LastModDateTime
			--	INTO ##RememberedListDomainValues
			--	FROM RememberedListDomainValues rldv'

			--	EXECUTE sp_executesql @SQL

			--	-- Drop the foreign keys referencing the RememberedListDomainValues table 
			--	SELECT @SQL = STRING_AGG('ALTER TABLE ' + OBJECT_NAME(parent_object_id) 
			--			+ ' DROP CONSTRAINT ' + name, CHAR(10))
			--	FROM sys.foreign_keys 
			--	WHERE OBJECT_NAME(referenced_object_id) = 'RememberedListDomainValues'

			--	EXECUTE sp_executesql @SQL

			--	-- Drop the RememberedListDomainValues
			--	IF OBJECT_ID ('RememberedListDomainValues', 'U') IS NOT NULL
			--	BEGIN
			--		DROP TABLE RememberedListDomainValues;
			--	END

			--	-- Recreate the RememberedListDomainValues table
			--	IF OBJECT_ID ('RememberedListDomainValues', 'U') IS NULL
			--	BEGIN
			--		SET @SQL = 'SELECT * INTO RememberedListDomainValues
			--					FROM ##RememberedListDomainValues
			--					ORDER BY 1

			--					ALTER TABLE [dbo].[RememberedListDomainValues] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]
			--					ALTER TABLE [dbo].[RememberedListDomainValues] ADD  DEFAULT (getdate()) FOR [CreatedDate]
			--					ALTER TABLE [dbo].[RememberedListDomainValues] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]
			--					ALTER TABLE [dbo].[RememberedListDomainValues] ADD  DEFAULT (getdate()) FOR [LastModDateTime]'

			--		EXECUTE sp_executesql @SQL

			--	END

			--	-- Recreate update trigger on RememberedListDomainValues table
			--	IF OBJECT_ID ('tu_RememberedListDomainValues', 'TR') IS NULL AND OBJECT_ID('RememberedListDomainValues', 'U') IS NOT NULL
			--	BEGIN
			--		SET @SQL = 'CREATE TRIGGER [dbo].[tu_RememberedListDomainValues] ON [dbo].[RememberedListDomainValues] FOR UPDATE AS 
			--		IF EXISTS(SELECT * FROM DELETED)
			--		BEGIN
			--			UPDATE dbo.RememberedListDomainValues
			--			SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
			--			FROM dbo.RememberedListDomainValues as t, DELETED as d
			--			WHERE t.Id=d.Id;
			--		END'

			--		EXECUTE sp_executesql @SQL
			--	END
			--END

			-------------------------------------- MODIFY ActionItemPropDCXRef TABLE --------------------------------
	
			--IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.columns WHERE Table_Name = 'ActionItemPropDCXRef'
			--				AND Column_Name = 'ListDomainTableName') AND OBJECT_ID('ActionItemPropDCXRef', 'U') IS NOT NULL
			--BEGIN
	
			--	IF OBJECT_ID ('tempdb..##ActionItemPropDCXRef', 'U') IS NULL 
			--	BEGIN
			--		-- Store data from ActionItemPropDCXRef into temporary table 
			--		SET @SQL = 'SELECT ActionItemPropertyId,
			--							(SELECT TOP 1 NewListDomainTable FROM ##NewDomainTableList
			--							WHERE DomainCatalogId = aip.DomainCatalogId) AS ListDomainTableName,
			--							CreatedUser,
			--							CreatedDate,
			--							LastModByUserId,
			--							LastModDateTime
			--					INTO ##ActionItemPropDCXRef 
			--					FROM ActionItemPropDCXRef aip'

			--		EXECUTE sp_executesql @SQL
			--	END  

			--	-- Drop foreign keys referencing the ActionItemPropDCXRef table
			--	SELECT @SQL = STRING_AGG('ALTER TABLE ' + OBJECT_NAME(parent_object_id) 
			--			+ ' DROP CONSTRAINT ' + name, CHAR(10))
			--	FROM sys.foreign_keys 
			--	WHERE OBJECT_NAME(referenced_object_id) = 'RememberedListDomainValues'

			--	EXECUTE(@SQL)

			--	-- Drop ActionItemPropDCXRef table
			--	IF OBJECT_ID ('ActionItemPropDCXRef', 'U') IS NOT NULL
			--	BEGIN
			--		DROP TABLE ActionItemPropDCXRef;
			--	END

			--	-- Recreate ActionItemPropDCXRef table
			--	IF OBJECT_ID ('ActionItemPropDCXRef', 'U') IS NULL 
			--	BEGIN
			--		SET @SQL = 'SELECT * INTO ActionItemPropDCXRef
			--					FROM ##ActionItemPropDCXRef
					
			--					ALTER TABLE [dbo].[ActionItemPropDCXRef] ADD  DEFAULT (suser_sname()) FOR [CreatedUser]
			--					ALTER TABLE [dbo].[ActionItemPropDCXRef] ADD  DEFAULT (getdate()) FOR [CreatedDate]
			--					ALTER TABLE [dbo].[ActionItemPropDCXRef] ADD  DEFAULT (suser_sname()) FOR [LastModByUserId]
			--					ALTER TABLE [dbo].[ActionItemPropDCXRef] ADD  DEFAULT (getdate()) FOR [LastModDateTime]'

			--		EXECUTE sp_executesql @SQL
			--	END

			--	RETURN

			--	-- Recreate update trigger on ActionItemPropDCXRef
			--	IF OBJECT_ID ('tu_ActionItemPropDCXRef', 'TR') IS NULL 
			--	BEGIN
			--		SET @SQL = 'CREATE TRIGGER [dbo].[tu_ActionItemPropDCXRef] ON [dbo].[ActionItemPropDCXRef] FOR UPDATE AS 
			--		IF EXISTS(SELECT * FROM DELETED)
			--		BEGIN
			--			UPDATE dbo.ActionItemPropDCXRef
			--			SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
			--			FROM dbo.ActionItemPropDCXRef as t, DELETED as d
			--			WHERE t.ActionItemPropertyId=d.ActionItemPropertyId;
			--		END'

			--		EXECUTE sp_executesql @SQL
			--	END

			--	-- Recreate Foreign key referencing the ActionItemProperty table
			--	IF NOT EXISTS (SELECT 1 FROM sys.foreign_key_columns WHERE OBJECT_NAME(parent_object_id) = 'ActionItemPropDCXRef'
			--					AND OBJECT_NAME(referenced_object_id) = 'ActionItemProperty')
			--	BEGIN
			--		SET @SQL = 'ALTER TABLE ActionItemPropDCXRef ADD CONSTRAINT FK_AtnItmPropDCXRef_AtnItmPrp 
			--		FOREIGN KEY (ActionItemPropertyId) REFERENCES ActionItemProperty (Id)'

			--		EXECUTE(@SQL)
			--	END

			--END

			------------------------------------------ DELETE OBSELETE TABLES ------------------------------------------------

			--/*
			--	Create copies of the DomainCatalog, and DomainCatalogColXRef tables then drop them if all foreign key constraints have been
			--	successfully transfered to the new domain tables
			--*/
			--IF OBJECT_ID('tempdb..##NewDomainTableList') IS NOT NULL
			--BEGIN
			--	IF NOT EXISTS (SELECT * FROM ##NewDomainTableList
			--					WHERE FKConstraint IN (SELECT OBJECT_NAME(constraint_object_id) AS fk_constraint
			--												FROM sys.foreign_key_columns
			--												WHERE OBJECT_NAME(constraint_object_id) IN (select FKConstraint FROM ##NewDomainTableList)
			--												AND OBJECT_NAME(referenced_object_id) = 'ListDomain'
			--												)
			--					)
			--	BEGIN
			--		-- Create copies of the DomainCatalog and DomainCatalogColXRef tables
			--		IF OBJECT_ID('Temp_DomainCatalogColXRef', 'U') IS NOT NULL AND OBJECT_ID('DomainCatalogColXRef', 'U') IS NOT NULL
			--		BEGIN
			--			DROP TABLE Temp_DomainCatalogColXRef;
			--		END

			--		IF OBJECT_ID('Temp_DomainCatalogColXRef') IS NULL
			--		BEGIN
			--			SELECT * INTO Temp_DomainCatalogColXRef FROM DomainCatalogColXRef;
			--		END

			--		IF OBJECT_ID('Temp_DomainCatalog') IS NOT NULL AND OBJECT_ID('DomainCatalog') IS NOT NULL
			--		BEGIN
			--			DROP TABLE Temp_DomainCatalog;
			--		END

			--		IF OBJECT_ID('Temp_DomainCatalog') IS NULL
			--		BEGIN
			--			SELECT * INTO Temp_DomainCatalog FROM DomainCatalog;
			--		END
					
			--		IF EXISTS (SELECT 1 FROM sys.foreign_key_columns
			--					WHERE OBJECT_NAME(referenced_object_id) = 'DomainCatalog')
			--		BEGIN
			--			DECLARE FKList_Cursor CURSOR FOR
			--			SELECT OBJECT_NAME(constraint_object_id) AS fk_constraint,
			--				   OBJECT_NAME(parent_object_id) AS fk_table
			--			FROM sys.foreign_key_columns
			--			WHERE OBJECT_NAME(referenced_object_id) = 'DomainCatalog';


			--			OPEN FKList_Cursor;
			--			FETCH NEXT FROM FKList_Cursor INTO @FKConstraintName, @FKTableName;

			--			WHILE @@FETCH_STATUS = 0
			--			BEGIN
			--				SET @SQL = 'ALTER TABLE ' + @FKTableName + ' DROP CONSTRAINT ' + @FKConstraintName;
			--				EXECUTE sp_executesql @SQL;

			--				FETCH NEXT FROM FKList_Cursor INTO @FKConstraintName, @FKTableName;
			--			END;

			--			CLOSE FKList_Cursor;
			--			DEALLOCATE FKList_Cursor;
			--		END;

			--		IF OBJECT_ID('DomainCatalog', 'U') IS NOT NULL
			--		BEGIN
			--			DROP TABLE DomainCatalog;
			--		END;

			--		IF OBJECT_ID('tempdb..##NewDomainTableList') IS NOT NULL
			--		BEGIN
			--			DROP TABLE ##NewDomainTableList;
			--			DROP TABLE IF EXISTS ##ListDomainInfo
			--		END;

			--	END;
			--END
			
			--UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 5, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640208 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 5
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640208 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 6
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 01
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650001', DBVersionComment = 'Service Pack DDL 6.5, Rel. 0, Updates 01', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

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
			SET DBVersion = '650002', DBVersionComment = 'Service Pack DDL 6.5, Rel. 0, Updates 02', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

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


-- POC_Rename_HCAType_Descr_Column.sql AND Rename the RCHCAReasonType.Description column to Descr. 
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
			SET DBVersion = '650003', DBVersionComment = 'Service Pack DDL 6.5, Rel. 0, Updates 03', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

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


-- Rename CreatedDate, CreatedUser, LastModByUserId, and LastModDateTime columns
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650003 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			--#########################################################################################################
			-- VARIABLE DECLARATION AND INITIALIZATION
			--#########################################################################################################

			-- Stores trigger info
			DECLARE @trigger_id AS INT
			DECLARE @trigger_name AS VARCHAR(150)
			DECLARE @trigger_def AS VARCHAR(MAX) 

			-- Stores name of column being searched for or replaced
			DECLARE @search_string AS NVARCHAR(100)
			DECLARE @replace_string AS NVARCHAR(100)

			-- Stores SQL queries and commands
			DECLARE @GetColumnCount AS NVARCHAR(1000)
			DECLARE @GetDefaultConst AS NVARCHAR(500)
			DECLARE @GetColumnList NVARCHAR(500)
			DECLARE @GetOldColList NVARCHAR(500)
			DECLARE @GetAddColumnList NVARCHAR(500)
			DECLARE @GetColModList NVARCHAR(500)
			DECLARE @GetTriggerModList NVARCHAR(800)

			--Stores table and column info
			DECLARE @column_name VARCHAR(70)
			DECLARE @table_name AS VARCHAR(150)
			DECLARE @column_count AS INT
			DECLARE @constraint_name NVARCHAR(200)
			DECLARE @default_constraint NVARCHAR(70)
			DECLARE @q_column_name NVARCHAR(800)
			DECLARE @data_type NVARCHAR(70)

			-- Stores counter values for while-loop
			DECLARE @row_count INT
			DECLARE @counter INT 
			DECLARE @sub_counter INT

			-- Stores list of column names 
			DECLARE @new_name_list VARCHAR(MAX);
			DECLARE @old_name_list VARCHAR(MAX)

			-- Stores result after search and replace operation
			DECLARE @snr_process_1 NVARCHAR(MAX)
			DECLARE @snr_process_2 NVARCHAR(MAX)

			-- counts occurrence of a word within a string
			DECLARE @word_count INT

			-- Stores modified trigger definition
			DECLARE @new_definition NVARCHAR(MAX)

			-- Stores position index within a string
			DECLARE @index_select_stmt INT
			DECLARE @index_insert_stmt INT
			DECLARE @index_update_stmt INT
			DECLARE @begin_phrase_index INT
			DECLARE @end_phrase_index INT
			DECLARE @index_case_func INT

			--Stores substrings
			DECLARE @update_stmt NVARCHAR(MAX)
			DECLARE @begin_stmt NVARCHAR(MAX)
			DECLARE @insert_stmt NVARCHAR(MAX)
			DECLARE @select_stmt NVARCHAR(MAX)
			DECLARE @insertNselect_stmt NVARCHAR(MAX)
			DECLARE @set_clause_limit NVARCHAR(MAX)

			------------------------------------------- TABLE DECLARATION/CREATION -------------------------------------------------------

			-- Table to store search and replace values for columns that need to be renamed
			DECLARE @SearchNReplace_tbl TABLE (id INT IDENTITY(1,1), searchString NVARCHAR(70), newString NVARCHAR(70), dataType NVARCHAR(70), default_const NVARCHAR(70))  
			INSERT INTO @SearchNReplace_tbl VALUES ('Create%User%','CreatedUser', 'VARCHAR(45)', 'SUSER_SNAME()');
			INSERT INTO @SearchNReplace_tbl VALUES ('LastMod%User%','LastModByUserId', 'VARCHAR(45)', 'SUSER_SNAME()');
			INSERT INTO @SearchNReplace_tbl VALUES ('Create%Date%','CreatedDate', 'DATETIME', 'GETDATE()');
			INSERT INTO @SearchNReplace_tbl VALUES ('LastMod%Date%','LastModDateTime', 'DATETIME', 'GETDATE()');

			-- Stores trigger info
			DECLARE @TriggerList_tbl TABLE (row_id INT IDENTITY(1,1), trigger_id INT, trigger_name NVARCHAR(100), table_name NVARCHAR(100), definitions NVARCHAR(MAX));

			-- Stores query to get the count of duplicate columns
			IF OBJECT_ID('tempdb..##ColumnCount_tbl') IS NOT NULL
					DROP TABLE ##ColumnCount_tbl;

			CREATE TABLE ##ColumnCount_tbl (id INT IDENTITY(1,1), table_name NVARCHAR(100), column_count INT)

			-- Stores list of tables that do not have a column with the specified column name. The column(s) will be added to the tables in this list
			DECLARE @AddColumnList_tbl TABLE (id INT IDENTITY(1,1), table_name NVARCHAR(100))

			-- Table to store list of columns that need to be renamed
			DECLARE @RenameColList_tbl TABLE (id INT IDENTITY(1,1), table_name NVARCHAR(100), column_name NVARCHAR(100))

			-- Store list of of tables with duplicate columns
			IF OBJECT_ID('tempdb..##DuplicateColumnList_tbl') IS NOT NULL
					DROP TABLE ##DuplicateColumnList_tbl;

			CREATE TABLE ##DuplicateColumnList_tbl (id INT IDENTITY(1,1), table_name NVARCHAR(100), column_name NVARCHAR(100))

			-- Stores list of old column names with the corresponding new name that will replace it
			DECLARE @OldColNames_tbl TABLE (oldColName NVARCHAR(500), newColName NVARCHAR(500));

			--####################################################################################################################################
			-- INITIALIZE SOME VARIABLES
			--#####################################################################################################################################

			-- Stores new column names (with quotes) in a comma-seperated list 
			SELECT @new_name_list = COALESCE(@new_name_list + ', ''', '''') + CONVERT(VARCHAR(100), newString) + ''''
			FROM @SearchNReplace_tbl;

			-- Use loop to load temporary table with a list of old column names (that need to be changed) with the corresponding new column name that will replace them
			SET @counter = 1;
			SELECT @row_count = COUNT(*) FROM @SearchNReplace_tbl;

			WHILE @counter <= @row_count
			BEGIN
				SELECT @search_string = searchString FROM @SearchNReplace_tbl
				WHERE id = @counter;
				SELECT @replace_string = newString FROM @SearchNReplace_tbl
				WHERE id = @counter;

				SET @GetOldColList = 'DECLARE @result_tbl TABLE (oldColName NVARCHAR(100), newColName NVARCHAR(100))
				INSERT INTO @result_tbl
				SELECT DISTINCT(col.name), ' + 'N''' + @replace_string + '''' + '
				FROM sys.columns col
				JOIN sys.triggers trig
				ON trig.parent_id = col.object_id
				WHERE col.name LIKE N' + '''' + @search_string + '''
				AND col.name != N' + '''' + @replace_string + '''' + ';
				SELECT * FROM @result_tbl;'

				INSERT INTO @OldColNames_tbl
				EXECUTE(@GetOldColList)

				SET @counter += 1;
			END

			-- Stores quoted old column names in a comma-seperated list
			SELECT @old_name_list = COALESCE(@old_name_list + ', ''', '''') + CONVERT(VARCHAR(100), oldColName) + ''''
			FROM @OldColNames_tbl;

			-- The 'LastUpgradeDate' column exists in a trigger but does not exist in a table and needs to be changed to match the column name in tables 
			INSERT INTO @OldColNames_tbl VALUES ('LastUpgradeDate', 'LastUpgradeDateTime');

			--##################################################################################################################################
			-- RENAMING COLUMNS, ADDING COLUMNS, AND REMOVING DUPLICATED COLUMNS
			--##################################################################################################################################

			-- Cursor to store list of search and replacement values for column names
			DECLARE Search_replace_cursor CURSOR FOR
			SELECT searchString, newString, dataType, default_const FROM @SearchNReplace_tbl;

			-- Open cursor that stores list of regEx search string and replacement column name
			OPEN Search_replace_cursor;
			FETCH NEXT FROM Search_replace_cursor INTO @search_string, @replace_string, @data_type, @default_constraint

			-- Loop through Search_replace_cursor. For each column search-string and replacement string pair do the following...
			WHILE @@FETCH_STATUS = 0
			BEGIN

			------------------------------------------- ADD THE COLUMNS TO EVERY TABLE THAT DOES NOT HAVE THEM--------------------------------------------
	
			PRINT CHAR (10) + 'ADDING DATA TRACKING COLUMNS TO TABLES THAT ARE MISSING THEM...'

				-- Get the report on tables that do not have a column with a name that matches the current search-string
				SET @GetAddColumnList = 'DECLARE @result_tbl TABLE (table_name NVARCHAR(100));
				INSERT INTO @result_tbl
				SELECT table_name FROM INFORMATION_SCHEMA.TABLES 
				WHERE table_type = ''BASE TABLE''
				EXCEPT
				SELECT name FROM sys.TABLES 
				WHERE name LIKE ''GDB%'' OR
						name LIKE ''SDE%'' OR
						name LIKE ''i[0-9]%'' OR
						temporal_type = 1
				EXCEPT
				SELECT DISTINCT(table_name) 
				FROM INFORMATION_SCHEMA.COLUMNS isc
				WHERE column_name LIKE '+ '''' + @search_string + '''' + ';
				SELECT * FROM @result_tbl'

				-- Insert the report result into a table
				INSERT INTO @AddColumnList_tbl
				EXECUTE(@GetAddColumnList)

				-- For every table in the report result add the column
				SET @counter = 1
				SELECT @row_count = COUNT(*) FROM @AddColumnList_tbl
				DECLARE @ddl_statment NVARCHAR(100) 
	
				WHILE @counter <= @row_count
				BEGIN
					SELECT @table_name = table_name FROM @AddColumnList_tbl
					WHERE id = @counter
					SET @ddl_statment = CONCAT('ALTER TABLE ', @table_name, ' ADD ', @replace_string, ' ', @data_type, ' DEFAULT ', @default_constraint, ';' )

					IF NOT EXISTS(SELECT column_name FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = @table_name AND column_name = @replace_string)
					BEGIN
						-- The 'LastUpgradeDateTime' column does not need to be added to every table
						IF(@replace_string != 'LastUpgradeDateTime')
							EXECUTE(@ddl_statment);
					END;
					
					SET @counter += 1
				END

			-------------------------------------------- DELETE DUPLICATE COLUMNS--------------------------------------------------------------

			PRINT CHAR(10) + 'DELETING DUPLICATE COLUMNS..'

				-- Stores command to create table to store column count for each table (to find duplicate columns)
				SET @GetColumnCount = 'DECLARE @result TABLE (table_name NVARCHAR(100), column_count INT)
				INSERT INTO @result
				SELECT table_name, COUNT(column_name) AS column_count
				FROM INFORMATION_SCHEMA.COLUMNS
				WHERE column_name LIKE N' + '''' + @search_string + '''' +
				' GROUP BY table_name 
				HAVING COUNT(column_name) > 1;
				SELECT * FROM @result;'

				TRUNCATE TABLE ##ColumnCount_tbl;
				TRUNCATE TABLE ##DuplicateColumnList_tbl;


				INSERT INTO ##ColumnCount_tbl
				EXECUTE sp_executesql @GetColumnCount;

				SET @counter = 1
				SELECT @row_count = COUNT(*) FROM ##ColumnCount_tbl;

				-- Store the columns to be deleted (all but 1 column) in a temporary table
				WHILE @counter <= @row_count
				BEGIN
		
					SELECT @table_name = table_name FROM ##ColumnCount_tbl
					WHERE id = @counter;

					SELECT @column_count = column_count FROM ##ColumnCount_tbl
					WHERE id = @counter;

					-- Stores query to populate a table variable with the list of duplicated columns for a given table
					SET @GetColumnList = 'DECLARE @result TABLE (table_name NVARCHAR(100), column_name NVARCHAR(100));
					INSERT INTO @result
					SELECT TOP '+ CAST((@column_count - 1) AS NVARCHAR) +'table_name, column_name
					FROM INFORMATION_SCHEMA.COLUMNS
					WHERE column_name LIKE N' + '''' + @search_string + '''' + 
					'	AND table_name = N' + '''' + @table_name + ''';'
					+ ' SELECT * FROM @result;'

					-- Get the list of columns that fit the search-string and store them in a table variable
					INSERT INTO ##DuplicateColumnList_tbl
					EXECUTE(@GetColumnList);

					SET @counter += 1;
				END

				-- Delete columns from table list
				SET @counter = 1
				SELECT @row_count = COUNT(*) FROM ##DuplicateColumnList_tbl;

				WHILE @counter <= @row_count
				BEGIN
					SELECT @table_name = table_name FROM ##DuplicateColumnList_tbl
					WHERE id = @counter;

					SELECT @column_name = column_name FROM ##DuplicateColumnList_tbl
					WHERE id = @counter;

					-- Find and drop the default constraint on the column
					SET @GetDefaultConst = 'SELECT @result = cons.name FROM sys.default_constraints cons
					WHERE parent_object_id = OBJECT_ID(N' + '''' + QUOTENAME(@table_name) + '''' + ')
					AND parent_column_id IN (SELECT column_id FROM sys.columns col
											WHERE col.name LIKE N' + '''' + @column_name + '''' +
											' AND object_id = OBJECT_ID(N' + '''' + QUOTENAME(@table_name) + '''' +')
											)'
					EXECUTE sp_executesql @GetDefaultConst, N'@result NVARCHAR(100) OUT', @constraint_name OUT;

					-- Drop default constraint if it exists
					IF EXISTS(SELECT * FROM sys.objects WHERE TYPE_DESC =  'DEFAULT_CONSTRAINT' AND NAME = @constraint_name)
						EXECUTE ('ALTER TABLE ' + @table_name + ' DROP CONSTRAINT ' + @constraint_name)

						-- Drop the column if it exists
					IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE column_name = @column_name AND table_name = @table_name)
						EXECUTE('ALTER TABLE ' + @table_name + ' DROP COLUMN ' + @column_name)

					SET @counter += 1;
				END

			-------------------------------------------------------------- RENAME COLUMNS ------------------------------------------------------------------------------------

			PRINT CHAR(10) + 'RENAMING COLUMNS'

				-- Stores statment to get report on tables that need to be renamed
				SET @GetColModList = N'DECLARE @result TABLE (table_name NVARCHAR(100), column_name NVARCHAR(100))
				INSERT INTO @result 
				SELECT tab.name, col.name
				FROM sys.tables tab
				JOIN sys.columns col
				ON tab.object_id = col.object_id
				WHERE col.name IN (N' + @old_name_list +');
				SELECT * FROM @result;'

				-- Insert report into table
				INSERT INTO @RenameColList_tbl 
				EXECUTE(@GetColModList)

				SET @counter = 1 
				SELECT @row_count = COUNT(*) FROM @RenameColList_tbl;

				-- Loop through the tables stored in table variable and rename columns
				WHILE @counter <= @row_count
				BEGIN
					SELECT @column_name = column_name FROM @RenameColList_tbl
					WHERE id = @counter;

					SELECT @table_name = table_name FROM @RenameColList_tbl
					WHERE id = @counter;

					SELECT @replace_string = newColName FROM @OldColNames_tbl
					WHERE oldColName = @column_name

					-- Gets the qualified column name for the unique remaining column
					SET @q_column_name = CONCAT('sp_rename ''', @table_name , '.' + @column_name, '''', ', ', '''', @replace_string, '''', ', ''COLUMN'';')
		
					-- Renames the column with the replacement-string
					IF NOT EXISTS(SELECT column_name FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = @table_name AND column_name = @replace_string)
						EXECUTE(@q_column_name);

					SET @counter += 1;
				END

				-- Fetch the next search-string, replacement-string pair
				FETCH NEXT FROM Search_replace_cursor INTO @search_string, @replace_string, @data_type, @default_constraint
			END -- End of Search_replace_cursor
			CLOSE Search_replace_cursor ;
			DEALLOCATE Search_replace_cursor; 

			--#####################################################################################################################################
			-- SAVE AND MODIFY TRIGGER DEFINITIONS FOR ALL AFFECTED TRIGGERS
			--#####################################################################################################################################

			--------------------------------------------------SAVE TRIGGER DEFINTIONS IN A TEMPORARY TABLE -----------------------------------------------

			PRINT 'MODIFYING TRIGGER DEFINITIONS...' + CHAR(10)

			-- Stores query to generate report of triggers that will be affected
			SET @GetTriggerModList = 'DECLARE @result_tbl TABLE (trigger_id NVARCHAR(100), trigger_name NVARCHAR(100), table_name NVARCHAR(100), definitions NVARCHAR(MAX))
			SELECT DISTINCT(trig.object_id) AS trigger_id, 
					name AS trigger_name, 
					subq.table_name,
					OBJECT_DEFINITION(trig.object_id)
			FROM sys.triggers trig
			JOIN 
			(SELECT trig.object_id AS trig_id,
					trig.name AS trigger_name,
					isc.table_name, 
					isc.column_name
			FROM INFORMATION_SCHEMA.COLUMNS isc
			INNER JOIN sys.triggers trig
				ON OBJECT_ID(isc.table_name) = trig.parent_id
			WHERE column_name IN (N' + @new_name_list + ')
			) subq
			ON subq.trig_id = trig.object_id;

			SELECT * FROM @result_tbl;'

			-- Insert query results into a local temporary table
			DELETE FROM @TriggerList_tbl;

			INSERT INTO @TriggerList_tbl
			EXECUTE(@GetTriggerModList)

			------------------------------------------------- MODIFY TRIGGER DEFINITIONS -----------------------------------------------------------

			-- Create cursor to loop through each old-column name
			DECLARE string_replace CURSOR FOR
			SELECT * FROM @OldColNames_tbl
			ORDER BY 1 DESC;

			OPEN string_replace
			FETCH NEXT FROM string_replace INTO @search_string, @replace_string

			-- Break up the definition of each trigger into smaller sections for processing. Loop through each column name that needs to be replaced
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @counter = 1
				SELECT @row_count = COUNT(*) FROM @TriggerList_tbl

				-- Loop through each trigger definition
				WHILE @counter <= @row_count
				BEGIN

					SELECT @trigger_def = definitions
					FROM @TriggerList_tbl
					WHERE row_id = @counter

					--Get the position index of the INSERT INTO statement
					SET @index_insert_stmt = CHARINDEX('INSERT INTO', @trigger_def)

					-- Stores beginning of CREATE TRIGGER statement. ELSE statement is for trigger definitions without an INSERT INTO or SELECT clause
					IF (@index_insert_stmt = 0)
						SELECT @begin_stmt = definitions
						FROM @TriggerList_tbl
						WHERE row_id = @counter;
					ELSE
					BEGIN
						-- Stores beginning of CREATE TRIGGER STATEMENT including UPDATE clause
						SELECT @begin_stmt = SUBSTRING(definitions, 0, @index_insert_stmt)
						FROM @TriggerList_tbl
						WHERE row_id = @counter;

						-- Store both the INSERT INTO and SELECT statements
						SELECT @insertNselect_stmt = SUBSTRING(definitions, @index_insert_stmt, LEN(definitions))
						FROM @TriggerList_tbl
						WHERE row_id = @counter

						-- Stores the position index for where the SELECT statement begins
						SELECT @index_select_stmt = CHARINDEX('SELECT', @insertNselect_stmt)
						FROM @TriggerList_tbl
						WHERE row_id = @counter;

						--Store the INSERT INTO statement
						SELECT @insert_stmt = SUBSTRING(@insertNselect_stmt, 0, @index_select_stmt);

						--Store the SELECT statement
						SELECT @select_stmt = SUBSTRING(@insertNselect_stmt, @index_select_stmt, LEN(@insertNselect_stmt))
						FROM @TriggerList_tbl
						WHERE row_id = @counter;
					END -- End of ELSE statement

					------------------------------------PROCESS BEGINNING OF CREATE TRIGGER STATEMENT------------------------------------

					-- Replace every occurrence of the new column name with the old column name so that all the names are uniform for a given column
					SELECT @snr_process_1 = REPLACE(@begin_stmt, @replace_string, @search_string)

					--Replace the old column name with the new column name
					SELECT @snr_process_2 = REPLACE(@snr_process_1, @search_string, @replace_string)

					-- Stores the index for the beginning of the UPDATE clause
					SET @index_update_stmt = CHARINDEX('UPDATE', @snr_process_2);

					-- if there is an UPDATE clause the following block of code is executed
					IF (@index_update_stmt > 0)
					BEGIN

						-- Save first part of CREATE TRIGGER statement (the section before UPDATE clause)
						SET @new_definition = SUBSTRING(@snr_process_2, 0, @index_update_stmt);

						-- Store Update statement for processing
						SET @update_stmt = SUBSTRING(@snr_process_2, @index_update_stmt, LEN(@snr_process_2));

						-- Get the index of the first CASE function. column names mentioned in a CASE function will remain untouched
						SET @index_case_func = PATINDEX('%CASE%WHEN%', @update_stmt)

						-- Get the portion of the SET clause that comes before the first CASE function
						IF @index_case_func <> 0
						BEGIN
							SET @set_clause_limit = SUBSTRING(@update_stmt, 0, @index_case_func)
						END
						ELSE
						BEGIN
							SET @set_clause_limit = SUBSTRING(@update_stmt, 0, CHARINDEX('FROM',@update_stmt))
						END

						-- Get the number of occurrence of the replacement string (new column name) within the UPDATE statement (for UPDATE clauses with and without CASE functions)
						IF (@index_case_func = 0)
							SELECT @word_count = (LEN(@update_stmt) - LEN(REPLACE(@update_stmt, @replace_string, '')))/LEN(@replace_string)
						ELSE
							SELECT @word_count = (LEN(@set_clause_limit) - LEN(REPLACE(@set_clause_limit, @replace_string, '')))/LEN(@replace_string)

							-- Delete repeated column name if it is repeated more than once within the SET clause of the UPDATE statement
							SET @sub_counter = 1;
							WHILE @sub_counter < @word_count
							BEGIN 
		
								-- Get start and end index of the section of the SET clause that includes the replacement string (new column name) 
								SET @begin_phrase_index = CHARINDEX( @replace_string, @update_stmt);
								SET @end_phrase_index = CHARINDEX(',', @update_stmt, @begin_phrase_index);

								-- Exit if it encounters a SET clause
								IF (@begin_phrase_index >= @index_case_func AND @index_case_func > 0)
								BEGIN
									BREAK
								END

								-- Delete duplicate column name in the SET clause
								IF (@index_case_func <> 0)
								BEGIN
									SET @update_stmt = STUFF(@update_stmt, @begin_phrase_index, (@end_phrase_index - @begin_phrase_index) + 1, '');
								END

								SET @sub_counter += 1;

							END --End of While-loop

						SET @new_definition += @update_stmt;

					END --End of IF-statement;
					ELSE 
						SET @new_definition = @snr_process_2;

					------------------------------------- PROCESS INSERT STATEMENT-----------------------------------------------

					-- For trigger definitions that have a INSERT INTO and SELECT statements
					IF (@index_insert_stmt > 0)
					BEGIN

						-- Perform 2 search and replace operations like before
						SELECT @snr_process_1 = REPLACE(@insert_stmt, @replace_string, @search_string)
						SELECT @snr_process_2 = REPLACE(@snr_process_1, @search_string, @replace_string)
			
						-- Get the number of occurrence of a column name
						SELECT @word_count = (LEN(@snr_process_2) - LEN(REPLACE(@snr_process_2, @replace_string, '')))/LEN(@replace_string)

						-- Delete repeated column name if it is repeated more than once
						SET @sub_counter = 1
						WHILE @sub_counter < @word_count
						BEGIN
							-- Get start and end index of the section of the SET clause that includes the replacement string (new column name) 
							SET @snr_process_2 = STUFF(@snr_process_2, CHARINDEX(@replace_string, @snr_process_2) - 1, LEN(@replace_string) + 2, '');

							SET @sub_counter += 1;
						END
		
						SET @new_definition += @snr_process_2
						---------------------------------------------- PROCESS SELECT STATEMENT -------------------------------------------------------------

						-- Perform 2 search and replace operations
						SELECT @snr_process_1 = REPLACE(@select_stmt, @replace_string, @search_string)
						SELECT @snr_process_2 = REPLACE(@snr_process_1, @search_string, @replace_string)

						-- Get the number of occurrence of a column name
						SELECT @word_count = (LEN(@snr_process_2) - LEN(REPLACE(@snr_process_2, @replace_string, '')))/LEN(@replace_string)

						-- Delete repeated column name if needed
						SET @sub_counter = 1
						WHILE @sub_counter < @word_count
						BEGIN
		
							-- Get start and end index of the section of the SET clause that includes the replacement string (new column name) 
							SET @snr_process_2 = STUFF(@snr_process_2, CHARINDEX(@replace_string, @snr_process_2) - 1, LEN(@replace_string) + 2, '');

							SET @sub_counter += 1;
						END
		
						SET @new_definition += @snr_process_2
					END -- End of IF statement

					-- Update the trigger definintion for the trigger currently being processed 
					UPDATE @TriggerList_tbl
					SET definitions = @new_definition
					WHERE row_id = @counter
		
					SET @counter += 1;

				END -- End of While-loop

				FETCH NEXT FROM string_replace INTO @search_string, @replace_string;

			END -- End of Cursor While-loop

			CLOSE string_replace;
			DEALLOCATE string_replace;

			--#########################################################################################################################################################
			-- RECREATE TRIGGERS
			--#########################################################################################################################################################

			PRINT 'RECREATED TRIGGERS WITH MODIFIED DEFINITIONS' + CHAR(10)

			-- Table to store triggers that failed to be recreated
			IF OBJECT_ID('FailedRecreatedTriggers') IS NOT NULL
				DROP TABLE FailedRecreatedTriggers;

			CREATE TABLE FailedRecreatedTriggers (trigger_name NVARCHAR(60),  error_msg NVARCHAR(MAX), definitions NVARCHAR(MAX));

			TRUNCATE TABLE FailedRecreatedTriggers;

			-- Create cursor to loop through each trigger 
			DECLARE trigger_list_cursor CURSOR FOR
			SELECT trigger_name, definitions FROM @TriggerList_tbl;

			-- for storing ddl statements
			DECLARE @create_statement NVARCHAR(MAX);
			DECLARE @drop_statement VARCHAR(500);

			-- Stores error message
			DECLARE @error_msg VARCHAR(500);

			IF EXISTS (SELECT * FROM @TriggerList_tbl)
			BEGIN
				OPEN trigger_list_cursor
				FETCH NEXT FROM trigger_list_cursor INTO @trigger_name, @trigger_def

				WHILE @@FETCH_STATUS = 0
				BEGIN
					-- Get the DDL statement to drop and recreate the trigger
					SET @drop_statement = N'DROP TRIGGER ' +  @trigger_name + ';';
					SET @create_statement = @trigger_def;

					-- Drop and recreate the trigger
					BEGIN TRY
						EXECUTE(@drop_statement);
						EXECUTE (@create_statement);
					END TRY 
					BEGIN CATCH
						-- Stores error message to be displayed
						SET @error_msg = 'Failed to recreate trigger: ' + @trigger_name

						-- displays the error message stored in @error_msg if an error is raised
						RAISERROR(@error_msg, -1, -1)

						-- Stores triggers that failed to be recreated in a global temporary table
						INSERT INTO FailedRecreatedTriggers
						VALUES(@trigger_name,  ERROR_MESSAGE(), @trigger_def)

					END CATCH 
		
					FETCH NEXT FROM trigger_list_cursor INTO @trigger_name, @trigger_def;
				END
				CLOSE trigger_list_cursor;
			END
			DEALLOCATE trigger_list_cursor;

			IF EXISTS (SELECT * FROM FailedRecreatedTriggers)
			BEGIN
				PRINT CHAR(10) + 'THE DEFINITIONS FOR THE ' + CAST(@counter AS VARCHAR) + ' TRIGGERS THAT FAILED TO BE RECREATED CAN BE FOUND WITH THE FOLLOWING SELECT STATEMENT...';
				PRINT CHAR(10) + 'SELECT definitions FROM FailedRecreatedTriggers';

				PRINT CHAR(10) + 'A MORE DETAILED ERROR MESSAGE CAN BE FOUND WITH THE FOLLOWING SELECT STATEMENT...';
				PRINT CHAR(10) +'SELECT trigger_name, error_msg FROM FailedRecreatedTriggers';
			END
			ELSE 
				DROP TABLE FailedRecreatedTriggers;
		
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


-- 5_Modify_View_Definitions.sql
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650003 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			-- 5_Modify_View_Definitions.sql
			/*

			This script updates the view definitions for views referencing the former ListDomain to reference the 
			new 'LD_' and 'GLD_' tables. Must be executed on the target database

			*/
			DECLARE @SQL NVARCHAR(MAX)
			DECLARE @ObjectDefinition NVARCHAR(MAX)
			DECLARE @FromClause NVARCHAR(300)
			DECLARE @JoinClause NVARCHAR(300)
			DECLARE @TableName NVARCHAR(100)
			DECLARE @StartIndex INT
			DECLARE @EndIndex INT
			DECLARE @ClauseStartIndex INT
			DECLARE @NextClauseIndex INT
			DECLARE @TableAlias NVARCHAR(100)
			DECLARE @MultiSpaceExists INT
			DECLARE @StrLength INT
			DECLARE @PreviousIndex INT
			DECLARE @ColumnName NVARCHAR(100)
			DECLARE @ViewName NVARCHAR(100)
			DECLARE @Type NVARCHAR(100)
			DECLARE @NewTableName NVARCHAR(100)
			DECLARE @Count INT
			DECLARE @ExemptTableList NVARCHAR(500)
			-------------------------------------- Table Declaration/Creation -------------------------

			IF OBJECT_ID ('tempdb..##SQLClauseTab') IS NOT NULL
			BEGIN
				DROP TABLE ##SQLClauseTab
			END

			IF OBJECT_ID ('tempdb..##SQLClauseTab') IS NULL
			BEGIN
				CREATE TABLE ##SQLClauseTab (StartIndex INT,
											 Type VARCHAR(20),
											 TableName NVARCHAR(100),
											 TableAlias NVARCHAR(100),
											 ColumnName NVARCHAR(100),
											 NewLDTableName VARCHAR(100))

			END


			DECLARE ViewListCursor CURSOR FOR
			SELECT table_name FROM INFORMATION_SCHEMA.tables
			WHERE table_type = 'VIEW'
			--AND table_name = 'PipeSegmentVw'

			OPEN ViewListCursor
			FETCH NEXT FROM ViewListCursor INTO @ViewName

			set @count = 0
			WHILE @@FETCH_STATUS = 0
			BEGIN

				DELETE FROM ##SQLClauseTab
				SET @ExemptTableList = '''ListDomain'''

			---------------------- Remove multispacing from view definitions (double space, triple space, etc) ----------------------

				SET @ObjectDefinition = NULL

				SELECT @ObjectDefinition = OBJECT_DEFINITION (OBJECT_ID(N'dbo.' + @ViewName + ''));  

				SELECT @MultiSpaceExists = CHARINDEX('  ', @ObjectDefinition)

				WHILE @MultiSpaceExists <> 0
				BEGIN
					SELECT @ObjectDefinition = REPLACE(@ObjectDefinition, '  ', ' ') 
 					SELECT @MultiSpaceExists = CHARINDEX('  ', @ObjectDefinition)
				END

				IF (CHARINDEX('ListDomain', @ObjectDefinition) <> 0)
				BEGIN

			-------------------------------- Find All FROM Clauses -----------------------------------

					SELECT @StrLength = LEN(@ObjectDefinition)
		 
					SET @StartIndex = 1

					WHILE @StartIndex < @StrLength
					BEGIN
						-- Get table name
						SELECT @ClauseStartIndex = CHARINDEX('FROM', @ObjectDefinition, @StartIndex)

						IF (@ClauseStartIndex = 0)
						BEGIN
							BREAK
						END

						SELECT @StartIndex = CHARINDEX(' ', @ObjectDefinition, @ClauseStartIndex) + 1

						IF (CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex) < CHARINDEX(' ', @ObjectDefinition, @StartIndex))
						BEGIN
							SELECT @EndIndex = CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex)
						END
						ELSE
						BEGIN
							SELECT @EndIndex = CHARINDEX(' ', @ObjectDefinition, @StartIndex)
						END

						SELECT @Tablename = SUBSTRING(@ObjectDefinition, @StartIndex, @EndIndex - @StartIndex)
						SELECT @Tablename = REPLACE(REPLACE(@Tablename, CHAR(13), ''), CHAR(10), '')

						-- Get table alias name
						SELECT @StartIndex = CHARINDEX(' ', @ObjectDefinition, @EndIndex) + 1
			
						IF (CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex) < CHARINDEX(' ', @ObjectDefinition, @StartIndex))
						BEGIN
							SELECT @EndIndex = CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex)
						END
						ELSE
						BEGIN
							SELECT @EndIndex = CHARINDEX(' ', @ObjectDefinition, @StartIndex)
						END

						SELECT @TableAlias = SUBSTRING(@ObjectDefinition, @StartIndex, @EndIndex  - @StartIndex)
						SELECT @TableAlias = REPLACE(REPLACE(@TableAlias, CHAR(13), ''), CHAR(10), '')

						INSERT INTO ##SQLClauseTab
						VALUES (@ClauseStartIndex, 
								'FROM', 
								@TableName, 
								@TableAlias, 
								NULL, 
								NULL)

						IF (PATINDEX('%With ' + @TableName + '%', @ObjectDefinition)) <> 0
							AND (CHARINDEX(@TableName, @ExemptTableList)) = 0
						BEGIN
							SET @ExemptTableList += ', ''' + @TableName+ ''''
						END

						SET @StartIndex = @EndIndex + 1

					END
		
			------------------------------------ Find All JOIN clauses ---------------------------------
	
					SET @StartIndex = 1

					WHILE @StartIndex < @StrLength
					BEGIN
						-- Get table name
						SELECT @ClauseStartIndex = CHARINDEX('JOIN ', @ObjectDefinition, @StartIndex) 

						SET @StartIndex = @ClauseStartIndex 

						IF (@StartIndex = 0)
						BEGIN
							BREAK
						END

						SELECT @StartIndex = CHARINDEX(' ', @ObjectDefinition, @StartIndex) + 1
			
						IF (CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex) < CHARINDEX(' ', @ObjectDefinition, @StartIndex))
						BEGIN
							SELECT @EndIndex = CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex)
						END
						ELSE
						BEGIN
							SELECT @EndIndex = CHARINDEX(' ', @ObjectDefinition, @StartIndex)
						END

						SELECT @Tablename = SUBSTRING(@ObjectDefinition, @StartIndex, @EndIndex - @StartIndex)
						SELECT @Tablename = REPLACE(REPLACE(@Tablename, CHAR(13), ''), CHAR(10), '')

						-- Get table alias name
						SELECT @StartIndex = CHARINDEX(' ', @ObjectDefinition, @EndIndex) + 1
			
						IF (CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex) < CHARINDEX(' ', @ObjectDefinition, @StartIndex))
						BEGIN
							SELECT @EndIndex = CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex)
						END
						ELSE
						BEGIN
							SELECT @EndIndex = CHARINDEX(' ', @ObjectDefinition, @StartIndex)
						END

						SELECT @TableAlias = SUBSTRING(@ObjectDefinition, @StartIndex, @EndIndex - @StartIndex)
						SELECT @TableAlias = REPLACE(REPLACE(@TableAlias, CHAR(13), ''), CHAR(10), '')

						INSERT INTO ##SQLClauseTab
						VALUES (@ClauseStartIndex, 
								'JOIN', 	
								@TableName, 
								@TableAlias, 
								NULL, 
								NULL)

						IF (PATINDEX('%With ' + @TableName + '%', @ObjectDefinition)) <> 0
							AND (CHARINDEX(@TableName, @ExemptTableList)) = 0
						BEGIN
							SET @ExemptTableList += ', ''' + @TableName+ ''''
						END

						SET @StartIndex = @EndIndex + 1
					END
		
			-------------------------------- Find all table-qualified columns within a View definition --------------------------------

			/*Find all table-qualifed columns within the view definition and match it with the start position of a JOIN operation.
			 This will match the arguments in the 
			*/

					DECLARE ColumnList_Cursor CURSOR FOR
					SELECT DISTINCT TableAlias FROM ##SQLClauseTab
					WHERE TableAlias IS NOT NULL AND TableAlias <> ' '

					OPEN ColumnList_Cursor
					FETCH NEXT FROM ColumnList_Cursor INTO @TableAlias

					WHILE @@FETCH_STATUS = 0
					BEGIN

						SELECT @StartIndex = MIN(StartIndex) FROM ##SQLClauseTab
						WHERE Type = 'JOIN'
			
						WHILE @StartIndex < @StrLength
						BEGIN
				
							SELECT @StartIndex = CHARINDEX(@TableAlias + '.', @ObjectDefinition, @StartIndex) 	

							IF (@StartIndex = 0)
							BEGIN
								BREAK
							END

							SELECT @ClauseStartIndex = MAX(StartIndex) FROM ##SQLClauseTab
							WHERE StartIndex < @StartIndex
							AND Type = 'JOIN'

							-- Get table alias and column name on left side of equal sign in the ON clause
							SELECT @StartIndex = CHARINDEX('.', @ObjectDefinition, @StartIndex) + 1

							IF (CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex) < CHARINDEX(' ', @ObjectDefinition, @StartIndex))
							BEGIN
								SELECT @EndIndex = CHARINDEX(CHAR(13), @ObjectDefinition, @StartIndex)
							END
							ELSE
							BEGIN
								SELECT @EndIndex = CHARINDEX(' ', @ObjectDefinition, @StartIndex)
							END

							SELECT @ColumnName = SUBSTRING(@ObjectDefinition, @StartIndex, @EndIndex - @StartIndex)
							SELECT @ColumnName = REPLACE(REPLACE(@ColumnName, CHAR(13), ''), CHAR(10), '')

							INSERT INTO ##SQLClauseTab
							VALUES (@ClauseStartIndex, 
									'COLUMN', 
									(SELECT TOP 1 TableName FROM ##SQLClauseTab WHERE TableAlias = @TableAlias 
									AND TableName IS NOT NULL), 
									@TableAlias, 
									@ColumnName,
									NULL) 

							IF (PATINDEX('%With ' + @TableName + '%', @ObjectDefinition)) <> 0
								AND (CHARINDEX(@TableName, @ExemptTableList)) = 0
							BEGIN
								SET @ExemptTableList += ', ''' + @TableName+ ''''
							END
						
							SET @StartIndex = @EndIndex + 1
						END
			
						FETCH NEXT FROM ColumnList_Cursor INTO @TableAlias
					END

					CLOSE ColumnList_Cursor
					DEALLOCATE ColumnList_Cursor

			--------------- Match ListDomain entries in View Definition to new ListDomain tables ------------------------	

			-- Use the starting index of the JOIN operations to match the ListDomain Id column with the 

					SET @SQL = 'WITH tmpQuery AS (
								SELECT SCT.*, tmp.ListDomainTableName 
								FROM ##SQLClauseTab SCT
								JOIN TempListDomainTable tmp
								ON tmp.ReferencedColumnName = SCT.ColumnName
								AND tmp.ReferencedTableName = SCT.TableName
								WHERE SCT.StartIndex IN (SELECT StartIndex FROM ##SQLClauseTab
													WHERE TableName = ''ListDomain'')
								AND ColumnName IS NOT NULL
								)
								UPDATE ##SQLClauseTab
								SET NewLDTableName = Tab2.ListDomainTableName
								FROM ##SQLClauseTab Tab1
								JOIN tmpQuery Tab2
								ON Tab1.StartIndex = Tab2.StartIndex
								WHERE Tab1.TableName = ''ListDomain'''

					EXECUTE sp_executesql @SQL
		
			----------------------- Store views that contain missing tables in a tmp table --------------------

				SET @Count = 0

				IF OBJECT_ID('tmp_InvalidViews') IS NULL
				BEGIN
					CREATE TABLE tmp_InvalidViews (ViewName NVARCHAR(100),
													Definition NVARCHAR(MAX),
													DropCommand NVARCHAR(100))

				END

				SET @SQL = '
				IF OBJECT_ID(''tempdb..##Result'') IS NOT NULL
				BEGIN
					DROP TABLE ##Result
				END 

				SELECT DISTINCT(TableName) 
				INTO ##Result
				FROM ##SQLClauseTab
				WHERE TableName NOT IN (' + @ExemptTableList + ')
				AND TableName NOT IN (SELECT name FROM sys.tables)'

				EXECUTE sp_executesql @SQL

				SELECT @Count = COUNT(*) FROM ##Result

				IF (@Count <> 0)
				BEGIN

					IF NOT EXISTS (SELECT 1 FROM tmp_InvalidViews WHERE ViewName = @ViewName)
					BEGIN
						INSERT INTO tmp_InvalidViews
						SELECT @ViewName, 
								'EXEC sp_helptext N''dbo.' + @ViewName + '''',
								'DROP VIEW ' + @ViewName + ''
					
					END

					EXECUTE sp_executesql @SQL

				END
		
			--/*********************************************************************************************************
			--		                            Modify View Definiion 
			--**********************************************************************************************************/

			----------------------------------- Modify View Definition ----------------------------

					DECLARE SearchNReplaceCursor CURSOR FOR
					SELECT StartIndex, Type, TableName, TableAlias, NewLDTableName 
					FROM ##SQLClauseTab
					WHERE StartIndex IN (SELECT StartIndex FROM ##SQLClauseTab
										WHERE TableName = 'ListDomain')
					AND TableName = 'ListDomain'
					AND NewLDTableName IS NOT NULL
					--ORDER BY 1, 2

					OPEN SearchNReplaceCursor
					FETCH NEXT FROM SearchNReplaceCursor INTO @StartIndex, @Type, @TableName, @TableAlias, @NewTableName

					-- Replace ListDomain table wherever it is mentioned with the new list domain table name
					WHILE @@FETCH_STATUS = 0
					BEGIN

						SELECT @ObjectDefinition = REPLACE (@ObjectDefinition, 
										@TableName + ' ' + @TableAlias,
										@NewTableName + ' ' + @TableAlias)
													
						FETCH NEXT FROM SearchNReplaceCursor INTO @StartIndex, @Type, @TableName, @TableAlias, @NewTableName
					END 
	
					CLOSE SearchNReplaceCursor
					DEALLOCATE SearchNReplaceCursor


			-------------------------------------- Recreate View -------------------------------------------
		
					SELECT @ObjectDefinition = REPLACE(@ObjectDefinition, 'Create View', 'CREATE OR ALTER VIEW')

					IF NOT EXISTS (SELECT 1 FROM tmp_InvalidViews WHERE ViewName =  @ViewName)
					BEGIN
						EXECUTE (@ObjectDefinition)
					END

				END

				FETCH NEXT FROM ViewListCursor INTO @ViewName

			END

			CLOSE ViewListCursor
			DEALLOCATE ViewListCursor

			IF OBJECT_ID ('tmp_InvalidViews') IS NOT NULL
			BEGIN
				IF EXISTS (SELECT 1 FROM tmp_InvalidViews) 
				BEGIN
					PRINT 'The following Views could not be modified due to invalid tables in the view definition'
					SELECT * FROM tmp_InvalidViews
				END
				ELSE
				BEGIN
					DROP TABLE tmp_InvalidViews
				END
			END
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


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650003 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 04
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650004', DBVersionComment = 'Service Pack DDL 6.5, Rel. 0, Updates 04', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

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


-- Drop ListDomain table and create Temp_ListDomain table
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650004 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN

		IF OBJECT_ID ('Temp_ListDomain', 'U') IS NOT NULL AND OBJECT_ID ('LIstdomain', 'U') IS NOT NULL
		BEGIN
			DROP TABLE Temp_ListDomain
		END

		IF OBJECT_ID ('Temp_ListDomain', 'U') IS NULL
		BEGIN
			SELECT * INTO Temp_ListDomain FROM ListDomain
		END

		--Drop Listdomain table
		IF OBJECT_ID('ListDomain', 'U') IS NOT NULL
		BEGIN
			DROP TABLE ListDomain;
		END;

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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650004 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 05
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650005', DBVersionComment = 'Service Pack DDL 6.5, Rel. 0, Updates 05', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

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


--Modify EarthQuakeArea table definition
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650005 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			ALTER TABLE EarthQuakeArea ALTER COLUMN EarthQuakeAreaMin numeric(12,2) NULL
			ALTER TABLE EarthQuakeArea ALTER COLUMN EarthQuakeAreaMax numeric(12,2) NULL

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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650005 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 06
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650006', DBVersionComment = 'Service Pack DDL 6.5, Rel. 0, Updates 06', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

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


-- 50033_CreateILIComments_StageDBScript.sql
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650006 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- 50033_CreateILIComments_StageDBScript.sql
			/*******************************************
			 * For Backlog Item 50033: Creating Inline Inspection Comments Column in Inline Inspection Table
			 *
			 * This stage DB script will be adding a new column for adding comments to the InlineInspection table.
			 *******************************************/

			 -- Check if the column exists in the table before we add it.
			 IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS c WHERE c.TABLE_NAME = 'InlineInspection' AND c.COLUMN_NAME = 'ILIComments')
			 BEGIN
				-- Add a column that is 500 characters long.
				ALTER TABLE InlineInspection
				ADD ILIComments VARCHAR(500) NULL
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650006 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 07
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650007', DBVersionComment = 'Service Pack DDL 6.5, Rel. 0, Updates 07', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

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


-- Modify HCAVw View
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650007 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			DECLARE @sql nvarchar(max)

			SET @sql = 'ALTER view [dbo].[HCAVw] as
			  SELECT LL.Id AS LineLoopId,
			  LL.LineName,
			  S1.MLVSectionName                                                           AS StartMLVSectionName,
			  S2.MLVSectionName                                                           AS EndMLVSectionName,
			  CAST(TT.BeginStationNum * C1.MultiplierNum + C1.FactorNum AS NUMERIC(13,3)) AS StartDisplayChainage,
			  CAST (TT.EndStationNum  * C2.MultiplierNum + C2.FactorNum AS NUMERIC(13,3)) AS EndDisplayChainage,
			  TT.BeginStationSeriesId,
			  TT.BeginStationNum,
			  TT.EndStationSeriesId,
			  TT.EndStationNum,
			  R.RCHCAReasonTypeId AS HCATypeDomainID,
			  RT.Descr      AS HCAType,
			  TT.HCAName,
			  TT.HCAConfirmDate,
			  TT1.RCHCACALCSEGPIR AS HCAImpactDistance,
			  TT.HCAComment
			FROM HCACFR TT
			JOIN HCACFRSeg TT1 ON TT.BeginStationSeriesId = TT1.BeginStationSeriesId AND TT.EndStationSeriesId  = TT1.EndStationSeriesId AND ((TT.BeginStationNum BETWEEN TT1.BeginStationNum AND TT1.EndStationNum) OR (TT.BeginStationNum BETWEEN TT1.EndStationNum AND TT1.BeginStationNum))
			JOIN HCAReasons R ON R.HCACFRSEGID        = TT1.ID AND R.RCHCAReasonTypeId > 0 
			JOIN RCHCAREASONTYPE RT ON R.RCHCAREASONTYPEID = RT.ID
			JOIN (SELECT StationSeriesId,
				mlv.BeginStationNum,
				mlv.EndStationNum,
				MIN(FactorNum)     AS FactorNum,
				MIN(MultiplierNum) AS MultiplierNum,
				MIN(MLVSectionId)  AS MLVSectionId
			  FROM StationSeries ss
			  INNER JOIN MLVCorrection mlv
			  ON mlv.StationSeriesId = ss.Id
			  GROUP BY StationSeriesId,
				mlv.BeginStationNum,
				mlv.EndStationNum) C1 ON TT.BeginStationSeriesId = C1.StationSeriesId AND ((TT.BeginStationNum BETWEEN C1.BeginStationNum AND C1.EndStationNum) OR (TT.BeginStationNum BETWEEN C1.EndStationNum AND C1.BeginStationNum))
			JOIN (SELECT StationSeriesId,
				mlv.BeginStationNum,
				mlv.EndStationNum,
				MIN(FactorNum)     AS FactorNum,
				MIN(MultiplierNum) AS MultiplierNum,
				MIN(MLVSectionId)  AS MLVSectionId
			  FROM StationSeries ss
			  INNER JOIN MLVCorrection mlv
			  ON mlv.StationSeriesId = ss.Id
			  GROUP BY StationSeriesId,
				mlv.BeginStationNum,
				mlv.EndStationNum) C2 ON TT.EndStationSeriesId = C2.StationSeriesId AND ((TT.EndStationNum BETWEEN C2.BeginStationNum AND C2.EndStationNum) OR (TT.EndStationNum BETWEEN C2.EndStationNum AND C2.BeginStationNum))
			JOIN MLVSection S1  ON C1.MLVSectionId = S1.Id
			JOIN MLVSection S2 ON C2.MLVSectionId = S2.Id
			JOIN StationSeries SS ON TT.BeginStationSeriesId = SS.Id
			JOIN LineLoop LL ON SS.LineLoopId           = LL.ID
			WHERE TT.EffectiveEndDate IS NULL'
			
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


--AddingMissingColumnsToLoadTables.sql
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650007 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			--AddingMissingColumnsToLoadTables.sql
			DECLARE @SQL NVARCHAR(MAX)

			DECLARE AlterTable_Cursor CURSOR FOR
			SELECT 'ALTER TABLE ' + QUOTENAME(table_schema) + '.[Load_' + table_name + '] ADD ' + column_name + 
			(CASE 
				WHEN data_type = 'numeric' THEN ' NUMERIC(' + CAST(numeric_precision AS NVARCHAR) + ', ' 
						+ CAST(numeric_scale AS NVARCHAR) + ')'
				WHEN data_type = 'varchar' THEN ' VARCHAR(' + CAST(character_maximum_length AS NVARCHAR) + ')'
				WHEN data_type LIKE 'date%' THEN ' ' + data_type
			END)
			FROM INFORMATION_SCHEMA.columns tab1
			WHERE table_name IN (SELECT REPLACE(table_name, 'Load_', '') 
								FROM INFORMATION_SCHEMA.tables WHERE table_name like 'Load[_]%'
								)
			 AND column_name NOT IN (SELECT column_name 
									 FROM INFORMATION_SCHEMA.columns WHERE table_name = 'Load_' + tab1.table_name)

			OPEN AlterTable_Cursor
			FETCH NEXT FROM AlterTable_Cursor INTO @SQL

			WHILE @@FETCH_STATUS = 0
			BEGIN
				EXECUTE sp_executesql @SQL
				FETCH NEXT FROM AlterTable_Cursor INTO @SQL
			END

			CLOSE AlterTable_Cursor
			DEALLOCATE AlterTable_Cursor

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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650007 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 08
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650008', DBVersionComment = 'Service Pack DDL 6.5, Rel. 0, Updates 08', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

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
