/********************************* SET THE STAGE DB NAME *********************************/
DECLARE @SQL NVARCHAR(MAX)
DECLARE @flag INT
DECLARE @StageDatabaseName NVARCHAR(100) 
DECLARE @ErrorMsg NVARCHAR(600)

SET @StageDatabaseName = ''

/******************************************************************************************/

BEGIN
	IF (SELECT COUNT(*) FROM sys.databases WHERE name = @StageDatabaseName) = 0
	BEGIN
		SET @ErrorMsg = 'Stage database not found. Please enter a correct stage database name before running this script.' + CHAR(10);
		THROW 51001, @ErrorMsg, 1;  
	END
	ELSE IF SUBSTRING(DB_NAME(), 0, CHARINDEX('_IRAS', DB_NAME())) <>  SUBSTRING(@StageDatabaseName, 0, CHARINDEX('_IRAS', @StageDatabaseName)) 
	BEGIN
		SET @ErrorMsg = 'The stage and config database client names do not appear to match' + CHAR(10);
		THROW 51000, @ErrorMsg, 1
	END
	ELSE
	BEGIN
		EXEC sp_set_session_context N'StageDatabaseName', @StageDatabaseName;
	END

	SET @SQL = 'SELECT @Result = COUNT(*) FROM ' + @StageDatabaseName + '.dbo.SystemPreferences 
				WHERE ParameterName = ''DatabaseType'' AND Value <> ''Stage'''

	EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @flag OUTPUT

	IF @flag = 1
	BEGIN
		SET @ErrorMsg = 'The selected stage database appears to be either a link or a config database.' + CHAR(10);
		THROW 51000, @ErrorMsg, 1;   
	END

	SET @SQL = 'SELECT @Result = COUNT(*) FROM ' + @StageDatabaseName + '.dbo.VersionInfo 
				WHERE DBVersion < 650000'

	EXECUTE sp_executesql @SQL, N'@Result INT OUTPUT', @flag OUTPUT

	IF @flag = 1 
	BEGIN
		SET @ErrorMsg = 'The stage database needs to be upgraded to the latest 6.5.0 version of IRAS before upgrading the config database.' + CHAR(10);
		THROW 51000, @ErrorMsg, 1
	END

	IF NOT EXISTS (SELECT * FROM dbo.SystemPreferences sp WHERE sp.ParameterName = 'DatabaseType' AND sp.Value = 'Config')
	BEGIN
		RAISERROR( 'The target database is not a Config database. This is a Config database upgrade script.', 11, 0)
	END
END

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640206 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0  
		BEGIN
			

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 1, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion VARCHAR(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint VARCHAR(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	SET @ErrorMsg = (10) + CHAR(10) + 'Error Message: ' + ERROR_MESSAGE()
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640206 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			-- CONFIG_FixVariableDataTypes_44376.sql
			-- Correct the DataType of ili import field and its variable
			UPDATE DataSourceField SET DataTypeId = (SELECT Id FROM DataType WHERE Name = 'Text') 
			WHERE Id IN (SELECT f.Id FROM DataSourceField f JOIN DataType d on d.Id = f.DataTypeId WHERE FieldName = 'ILIFacNumber' and d.Name = 'Number')
	
			UPDATE Variable SET DataTypeId = (SELECT Id FROM DataType WHERE Name = 'Text') 
			WHERE Id IN (SELECT v.Id FROM Variable v 
							JOIN VariableFieldXRef x on x.VariableId = v.Id 
							JOIN DataSourceField f on f.Id = x.DataSourceFieldId
							JOIN DataType d on d.Id = v.DataTypeId 
						 WHERE FieldName = 'ILIFacNumber' and d.Name = 'Number')

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

-- CONFIG_ImportFieldValidation_NoAppDB_44376.sql, -- Setup the string Lengths, and decimal Precision and Min/Max, -- Ili import config
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640206 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			-- CONFIG_ImportFieldValidation_NoAppDB_44376.sql
			-- Setup the string Lengths, and decimal Precision and Min/Max
			-- Ili import config
			UPDATE DataSourceFieldMetaData SET Precision = 5, MaxValue = '0.9999', MinValue = '-0.9999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ILINCDStrain')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 15, MaxValue = '9.99999999999999', MinValue = '-9.99999999999999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('POE')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 5, MaxValue = '99.999', MinValue = '-99.999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ILICBFPR', 'ILICBFPRtc', 'ILIFRupturePressureRatio', 'ILICARupturePressureRatio', 'ILIBSPitch', 'ILIBSYaw', 'ILIBSRoll')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 6, MaxValue = '99.9999', MinValue = '-99.9999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ILICBERF', 'ILICAGrowthRateDepth', 'ILICAESF')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 8, MaxValue = '99.999999', MinValue = '-99.999999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ILIBSVerticalStrain', 'ILIBSHorizontalStrain', 'ILIBSTotalStrain', 'ILIBSHorizontalStrainAtPeak', 'ILIBSVerticalStrainAtPeak', 
				'ILIBSMaxTotalStrainDif', 'ILIBSMaxHorizontalStrainDif', 'ILIBSMaxVerticalStrainDif', 'ILIBSHorizonStrainDifAtPeak', 'ILIBSVerticalStrainDifAtPeak')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 9, MaxValue = '99.9999999', MinValue = '-99.9999999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('GrowthRate', 'GrowthRateLength')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 11, MaxValue = '99.999999999', MinValue = '-99.999999999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ILICBLatitude', 'ILIFLatitude', 'ILICALatitude', 'ILIFacLatitude', 'ILIJointLatitude', 'ILINCDLatitude')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 5, MaxValue = '999.99', MinValue = '-999.99'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ILIBSOrientation', 'ILIBSPeakStrainOrientation')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 6, MaxValue = '999.999', MinValue = '-999.999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ILICBOrientation', 'ILIFOrientation', 'ILICAOrientation', 'ILIJointSeamOrientation', 'ILINCDOrientation', 'ILIASSensorP1Orientation', 'ILIASSensorP2Orientation', 'ILIASSensorP3Orientation', 'ILIASSensorP4Orientation', 'ILIASSensorP5Orientation', 'ILIASSensorP6Orientation', 'ILIASSensorP7Orientation', 'ILIASSensorP8Orientation')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 8, MaxValue = '999.99999', MinValue = '-999.99999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ILICBDepthPct', 'ILIFPeakDepthPct', 'ILIFLAPADepthPct', 'ILICADepthPct', 'ILINCDDepthPctNPS', 'ILINCDDepthPct')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 12, MaxValue = '999.999999999', MinValue = '-999.999999999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ILICBLongitude', 'ILIFLongitude', 'ILICALongitude', 'ILIFacLongitude', 'ILIJointLongitude', 'ILINCDLongitude', 'ILIBSLatitude', 'ILIBSLongitude', 'ILIASLatitude', 'ILIASLongitude')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 4, MaxValue = '9999', MinValue = '-9999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ILIFBoxCount')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 7, MaxValue = '9999.999', MinValue = '-9999.999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ILICBRupturePressureRatio', 'ILIFToolSpeed', 'ILIBSMaxTotalPipeMove', 'ILIBSMaxHorizontalPipeMove', 'ILIBSMaxVerticalPipeMove', 'ILIASSensorP1Strain', 'ILIASSensorP2Strain', 'ILIASSensorP3Strain', 'ILIASSensorP4Strain', 'ILIASSensorP5Strain', 'ILIASSensorP6Strain', 'ILIASSensorP7Strain', 'ILIASSensorP8Strain', 'ILIASAxialStrain')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 8, MaxValue = '9999.9999', MinValue = '-9999.9999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ILIJToolSpeed', 'ILIJDetectableLength', 'ILINCDHardness')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 9, MaxValue = '9999.99999', MinValue = '-9999.99999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ILIJointWallThickness', 'ILIJointDiameter', 'ILIJointMeasuredWallThickness')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 8, MaxValue = '99999.999', MinValue = '-99999.999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ILICBDepthTolerance', 'ILICBDepthToleranceStdDev', 'ILIFDepthTolerance', 'ILIFDepthToleranceStdDev', 'ILICADepthTolerance', 'ILICADepthToleranceStdDev', 'ILINCDDepthTolerance', 'ILINCDDepthToleranceStdDev')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 9, MaxValue = '99999.9999', MinValue = '-99999.9999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('MOP', 'DPP')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 10, MaxValue = '99999.99999', MinValue = '-99999.99999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ILIJointGrade')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 10, MaxValue = '9999999.999', MinValue = '-9999999.999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ILICBOdometer', 'ILICBZ', 'ILICBLength', 'ILICBWidth', 'ILICBLengthTolerance', 'ILICBLengthToleranceStdDev', 'ILICBWidthTolerance', 'ILICBWidthToleranceStdDev', 'ILIFOdometer', 'ILIFZ', 'ILIFLength', 'ILIFWidth', 'ILIFLAPALength', 'ILIFFPR', 'ILIFFPRtc', 'ILIFERF', 'ILIFLengthTolerance', 'ILIFLengthToleranceStdDev', 'ILIFWidthTolerance', 'ILIFWidthToleranceStdDev', 'ILICAOdometer', 'ILICAZ', 'ILICALength', 'ILICALargestIndividualInd', 'ILICAWidth', 'ILICAFPR', 'ILICAFPRtc', 'ILICALengthTolerance', 'ILICALengthToleranceStdDev', 'ILICAWidthTolerance', 'ILICAWidthToleranceStdDev', 'ILIFacOdometer', 'ILIFacZ', 'ILIRStartOdometer', 'ILIREndOdometer', 'ILIJointGirthWeldOdometer', 'ILIJointZ', 'ILINCDOdometer', 'ILINCDZ', 'ILINCDLength', 'ILINCDWidth', 'ILINCDLengthTolerance', 'ILINCDLengthToleranceStdDev', 'ILINCDWidthTolerance', 'ILINCDWidthToleranceStdDev', 'ILIBSOdometer', 'ILIBSZ', 'ILIASOdometer', 'ILIASZ', 'ILIASDistanceFromGirthWeld', 'ILIASDistanceFromGirthWeldDS')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 11, MaxValue = '99999999.999', MinValue = '-99999999.999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ILIBSPeakStrainOdometer', 'ILIBSPeakStrainDifOdometer')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 13, MaxValue = '99999999.99999', MinValue = '-99999999.99999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ILIBSLength')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 12, MaxValue = '999999999.999', MinValue = '-999999999.999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ILICBX', 'ILICBY', 'ILIFX', 'ILIFY', 'ILICAX', 'ILICAY', 'ILIFacX', 'ILIFacY', 'ILIJointX', 'ILIJointY', 'ILINCDX', 'ILINCDY', 'ILIBSX', 'ILIBSY', 'ILIASX', 'ILIASY')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 16, MaxValue = '999999999999.9999', MinValue = '-999999999999.9999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ILICBFailurePressure', 'ILIFFailurePressure', 'ILICAFailurePressure')
				)
			UPDATE DataSourceFieldMetaData SET Length = 1
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ILICBManualSizedInd', 'ILICAAnomalyType', 'SeamType', 'ILIASAreaOfInterest')
				)
			UPDATE DataSourceFieldMetaData SET Length = 2
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ILICBSurfaceInd', 'ILIFSurfaceInd', 'ILICASurfaceInd', 'ILINCDSurfaceInd')
				)
			UPDATE DataSourceFieldMetaData SET Length = 10
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ILICBVendorPackageCode', 'ILIFVendorPackageCode', 'RelativePosition', 'ILINCDVendorPackageCode')
				)
			UPDATE DataSourceFieldMetaData SET Length = 15
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ILICBCrsnCallBoxNumber', 'ILIFFeatureNumber', 'ILICAAnomalyNumber', 'ILICAAnomalyDepth', 'ILINCDFeatureNumber', 
				'ILIBSFeatureIdentifier', 'ILIASFeatureIdentifier')
				)
			UPDATE DataSourceFieldMetaData SET Length = 20
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('SpecVersion')
				)
			UPDATE DataSourceFieldMetaData SET Length = 25
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('SystemOfMeasure', 'ILIRCoordDatum', 'ILIJointGirthWeldNum', 'ILIJointGirthWeldNumPrevious', 'ILIASGirthWeldNum', 'ILIASGirthWeldNumDS')
				)
			UPDATE DataSourceFieldMetaData SET Length = 30
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ILIFacNumber')
				)
			UPDATE DataSourceFieldMetaData SET Length = 50
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('MetalLossType', 'ILICAVendorPackageCode', 'ILIName', 'MeasuredFrom', 'ILIRHeightDatum')
				)
			UPDATE DataSourceFieldMetaData SET Length = 255
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ILIDescr', 'ILIRDescr', 'ILIJointComment', 'ILIBSComments', 'ILIASComments')
				)

			-- Excavation import config
			UPDATE DataSourceFieldMetaData SET Precision = 1, MaxValue = '9', MinValue = '-9'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('GirthWeldReferenceFlg')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 11, MaxValue = '99.999999999', MinValue = '-99.999999999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ExcavationLatitude')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 8, MaxValue = '999.99999', MinValue = '-999.99999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ESCADepthPct')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 12, MaxValue = '999.999999999', MinValue = '-999.999999999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ExcavationLongitude')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 5, MaxValue = '99999', MinValue = '-99999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('PSPPipeReadingOFF', 'PSPPipeReadingON')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 10, MaxValue = '9999999.999', MinValue = '-9999999.999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('DistFromReference')
				)
			UPDATE DataSourceFieldMetaData SET Precision = 10, MaxValue = '9999999999', MinValue = '-9999999999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ExcavationSiteId', 'InlineInspectionFeatureId')
				)
			UPDATE DataSourceFieldMetaData SET Length = 15
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ESCAAnomalyDepth')
				)
			UPDATE DataSourceFieldMetaData SET Length = 25
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('GirthWeldNum')
				)
			UPDATE DataSourceFieldMetaData SET Length = 100
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ExcavationSiteName')
				)
			UPDATE DataSourceFieldMetaData SET Length = 255
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('ExcavationSiteDescription', 'ExcavationSiteComment', 'ExcavationReason', 'CoatCondComment')
				)
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 3, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640206 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 3
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.4 Release 3 Updates 1
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '640301', DBVersionComment = 'Config Service Pack DDL 6.4, Rel. 3, Updates 1', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

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

-- CONFIG_ImportMappingToVariableILIJointDiameter_43800.sql
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640301 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- CONFIG_ImportMappingToVariableILIJointDiameter_43800.sql
			-- Correct the import configuration to use existing variables rather than field names for destination mapping

			-- Set the stage mapping to existing variables rather than fields.
			-- Update the specific table fields (Catches both ILI and Stg_ILI tables where fieldnames are the same).
			UPDATE StageDestinationXRef SET FieldName = (
				SELECT v.Name FROM Variable v 
					JOIN VariableFieldXRef x on x.VariableId = v.Id
					JOIN DataSourceField f on f.Id = x. DataSourceFieldId AND f.FieldName = StageDestinationXRef.FieldName
				)
			WHERE FieldName in ( -- Using specific list to avoid overwriting existing or running into problems with duplicates.
				'ILIJointDiameter'
				)

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


-- Insert_DataSourceTable_For_IRASCustomTable.sql
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640301 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			-- Insert_DataSourceTable_For_IRASCustomTable.sql
			-- Script to add the missing data source configuration for all the IRASCustomData tables.

			BEGIN TRY
				BEGIN TRAN

				-- Variables for table and column list.
				DECLARE @table_list TABLE (TableName NVARCHAR(100));
				DECLARE @column_list TABLE (ColumnName NVARCHAR(100));
				DECLARE @ext_column_list TABLE (ColumnName NVARCHAR(100));
		
				-- Populate the table_list and column_list with the table and column names
				INSERT INTO @table_list (TableName) VALUES ('IRASCustomData1'), ('IRASCustomData2'), ('IRASCustomData3'), ('IRASCustomData4'), ('IRASCustomData5'), ('IRASCustomData6'), ('IRASCustomData7'), ('IRASCustomData8'), ('IRASCustomData9'), ('IRASCustomData11');
				INSERT INTO @column_list (ColumnName) VALUES ('Field_1_Date'), ('Field_2_Date'), ('Field_3_Date'), ('Field_4_Date'), ('Field_5_Date'), 
				('Field_1_Float'), ('Field_2_Float'), ('Field_3_Float'), ('Field_4_Float'), ('Field_5_Float'), 
				('Field_1_Ind'), ('Field_2_Ind'), ('Field_3_Ind'), ('Field_4_Ind'), ('Field_5_Ind'),
				('Field_1_DomainId'), ('Field_2_DomainId'), ('Field_3_DomainId'), ('Field_4_DomainId'), ('Field_5_DomainId'),
				('Field_1_String'), ('Field_2_String'), ('Field_3_String'), ('Field_4_String'), ('Field_5_String');

				INSERT INTO @ext_column_list (ColumnName) VALUES 
				('Field_6_Date'), ('Field_7_Date'), ('Field_8_Date'), ('Field_9_Date'), ('Field_10_Date'), ('Field_11_Date'), ('Field_12_Date'), ('Field_13_Date'), ('Field_14_Date'), ('Field_15_Date'), ('Field_16_Date'), ('Field_17_Date'), ('Field_18_Date'), ('Field_19_Date'), ('Field_20_Date'),
				('Field_6_Float'), ('Field_7_Float'), ('Field_8_Float'), ('Field_9_Float'), ('Field_10_Float'), ('Field_11_Float'), ('Field_12_Float'), ('Field_13_Float'), ('Field_14_Float'), ('Field_15_Float'), ('Field_16_Float'), ('Field_17_Float'), ('Field_18_Float'), ('Field_19_Float'), ('Field_20_Float'),
				('Field_6_Ind'), ('Field_7_Ind'), ('Field_8_Ind'), ('Field_9_Ind'), ('Field_10_Ind'), ('Field_11_Ind'), ('Field_12_Ind'), ('Field_13_Ind'), ('Field_14_Ind'), ('Field_15_Ind'), ('Field_16_Ind'), ('Field_17_Ind'), ('Field_18_Ind'), ('Field_19_Ind'), ('Field_20_Ind'),
				('Field_6_DomainId'), ('Field_7_DomainId'), ('Field_8_DomainId'), ('Field_9_DomainId'), ('Field_10_DomainId'), ('Field_11_DomainId'), ('Field_12_DomainId'), ('Field_13_DomainId'), ('Field_14_DomainId'), ('Field_15_DomainId'), ('Field_16_DomainId'), ('Field_17_DomainId'), ('Field_18_DomainId'), ('Field_19_DomainId'), ('Field_20_DomainId'),
				('Field_6_String'), ('Field_7_String'), ('Field_8_String'), ('Field_9_String'), ('Field_10_String'), ('Field_11_String'), ('Field_12_String'), ('Field_13_String'), ('Field_14_String'), ('Field_15_String'), ('Field_16_String'), ('Field_17_String'), ('Field_18_String'), ('Field_19_String'), ('Field_20_String');
			
				-- Variables for iteration
				DECLARE @v_table_name NVARCHAR(100);
				DECLARE @v_column_name NVARCHAR(100);
				DECLARE @v_field_data_type INT;
				DECLARE @v_field_id numeric(18, 0);
				DECLARE @v_LastInsertedIdTable TABLE (
					Id numeric(18, 0));

				-- Loop through the table names
				WHILE EXISTS (SELECT 1 FROM @table_list)
				BEGIN
					SELECT TOP 1 @v_table_name = TableName FROM @table_list;
					DELETE FROM @table_list WHERE TableName = @v_table_name;

					IF EXISTS (SELECT 1 from DataSourceTable WHERE Name = @v_table_name)
					BEGIN
						CONTINUE;
					END

					-- Insert into DataSourceTable
					DELETE FROM @v_LastInsertedIdTable;

					INSERT INTO DataSourceTable
					(DataSourceId, Name, TableType, AppRoles, DisplayName)
					OUTPUT INSERTED.Id
					INTO @v_LastInsertedIdTable
					VALUES
					(1, @v_table_name, 1, 0, @v_table_name);
			  
					DECLARE @v_table_id numeric(18, 0) = (SELECT TOP 1 Id FROM @v_LastInsertedIdTable);

					-- Cursor to loop through the column_list
					DECLARE column_cursor CURSOR FOR
					SELECT ColumnName FROM @column_list;

					OPEN column_cursor;

					FETCH NEXT FROM column_cursor INTO @v_column_name;

					WHILE @@FETCH_STATUS = 0
					BEGIN
				
						IF RIGHT(@v_column_name, LEN('Date')) = 'Date'
						BEGIN
							SET @v_field_data_type = 4;
						END
						ELSE IF RIGHT(@v_column_name, LEN('Float')) = 'Float'
						BEGIN
							SET @v_field_data_type = 2;
						END
						ELSE IF RIGHT(@v_column_name, LEN('Ind')) = 'Ind'
						BEGIN
							SET @v_field_data_type = 3;
						END
						ELSE IF RIGHT(@v_column_name, LEN('DomainId')) = 'DomainId'
						BEGIN
							SET @v_field_data_type = 5;
						END
						ELSE 
						BEGIN
							SET @v_field_data_type = 1;
						END
				
						DELETE FROM @v_LastInsertedIdTable;

						INSERT INTO DataSourceField
						(FieldName, DataTypeId, TableId)
						OUTPUT INSERTED.Id
						INTO @v_LastInsertedIdTable
						VALUES
						(@v_column_name, @v_field_data_type, @v_table_id)
				
						SET @v_field_id = (SELECT TOP 1 Id FROM @v_LastInsertedIdTable);

						INSERT INTO DataSourceFieldMetadata
						(FieldId, FieldAppRole)
						VALUES
						(@v_field_id, 0);

						FETCH NEXT FROM column_cursor INTO @v_column_name;
					END;

					CLOSE column_cursor;
					DEALLOCATE column_cursor;

					-- Additional columns for IRASCustomData11
					IF @v_table_name = 'IRASCustomData11'
					BEGIN
						DECLARE ext_column_cursor CURSOR FOR
						SELECT ColumnName FROM @ext_column_list;

						OPEN ext_column_cursor;

						FETCH NEXT FROM ext_column_cursor INTO @v_column_name;

						WHILE @@FETCH_STATUS = 0
						BEGIN
					
							IF RIGHT(@v_column_name, LEN('Date')) = 'Date'
							BEGIN
								SET @v_field_data_type = 4;
							END
							ELSE IF RIGHT(@v_column_name, LEN('Float')) = 'Float'
							BEGIN
								SET @v_field_data_type = 2;
							END
							ELSE IF RIGHT(@v_column_name, LEN('Ind')) = 'Ind'
							BEGIN
								SET @v_field_data_type = 3;
							END
							ELSE IF RIGHT(@v_column_name, LEN('DomainId')) = 'DomainId'
							BEGIN
								SET @v_field_data_type = 5;
							END
							ELSE 
							BEGIN
								SET @v_field_data_type = 1;
							END
					
							DELETE FROM @v_LastInsertedIdTable;

							INSERT INTO DataSourceField
							(FieldName, DataTypeId, TableId)
							OUTPUT INSERTED.Id
							INTO @v_LastInsertedIdTable
							VALUES
							(@v_column_name, @v_field_data_type, @v_table_id)
					
							SET @v_field_id = (SELECT TOP 1 Id FROM @v_LastInsertedIdTable);

							INSERT INTO DataSourceFieldMetadata
							(FieldId, FieldAppRole)
							VALUES
							(@v_field_id, 0);

							FETCH NEXT FROM ext_column_cursor INTO @v_column_name;
						END;
						CLOSE ext_column_cursor;
						DEALLOCATE ext_column_cursor;
					END;
			
					-- Id Column
					DELETE FROM @v_LastInsertedIdTable;

					INSERT INTO DataSourceField
					(FieldName, DataTypeId, TableId)
					OUTPUT INSERTED.Id
					INTO @v_LastInsertedIdTable
					VALUES
					('Id', 2, @v_table_id);

					SET @v_field_id = (SELECT TOP 1 Id FROM @v_LastInsertedIdTable);

					INSERT INTO DataSourceFieldMetadata
					(FieldId, FieldAppRole)
					VALUES
					(@v_field_id, 8193);

					-- EffectiveEndDate Column
					DELETE FROM @v_LastInsertedIdTable;

					INSERT INTO DataSourceField
					(FieldName, DataTypeId, TableId)
					OUTPUT INSERTED.Id
					INTO @v_LastInsertedIdTable
					VALUES
					('EffectiveEndDate', 4, @v_table_id);

					SET @v_field_id = (SELECT TOP 1 Id FROM @v_LastInsertedIdTable);

					INSERT INTO DataSourceFieldMetadata
					(FieldId, FieldAppRole)
					VALUES
					(@v_field_id, 4096);

					-- EffectiveStartDate Column
					DELETE FROM @v_LastInsertedIdTable;

					INSERT INTO DataSourceField
					(FieldName, DataTypeId, TableId)
					OUTPUT INSERTED.Id
					INTO @v_LastInsertedIdTable
					VALUES
					('EffectiveStartDate', 4, @v_table_id);

					SET @v_field_id = (SELECT TOP 1 Id FROM @v_LastInsertedIdTable);

					INSERT INTO DataSourceFieldMetadata
					(FieldId, FieldAppRole)
					VALUES
					(@v_field_id, 0);

					-- BeginStationSeriesId Column
					DELETE FROM @v_LastInsertedIdTable;

					INSERT INTO DataSourceField
					(FieldName, DataTypeId, TableId)
					OUTPUT INSERTED.Id
					INTO @v_LastInsertedIdTable
					VALUES
					('BeginStationSeriesId', 2, @v_table_id);

					SET @v_field_id = (SELECT TOP 1 Id FROM @v_LastInsertedIdTable);

					INSERT INTO DataSourceFieldMetadata
					(FieldId, FieldAppRole)
					VALUES
					(@v_field_id, 35);

					-- BeginStationNum Column
					DELETE FROM @v_LastInsertedIdTable;

					INSERT INTO DataSourceField
					(FieldName, DataTypeId, TableId)
					OUTPUT INSERTED.Id
					INTO @v_LastInsertedIdTable
					VALUES
					('BeginStationNum', 2, @v_table_id);

					SET @v_field_id = (SELECT TOP 1 Id FROM @v_LastInsertedIdTable);

					INSERT INTO DataSourceFieldMetadata
					(FieldId, FieldAppRole)
					VALUES
					(@v_field_id, 37);

					-- EndStationSeriesId Column
					DELETE FROM @v_LastInsertedIdTable;

					INSERT INTO DataSourceField
					(FieldName, DataTypeId, TableId)
					OUTPUT INSERTED.Id
					INTO @v_LastInsertedIdTable
					VALUES
					('EndStationSeriesId', 2, @v_table_id);

					SET @v_field_id = (SELECT TOP 1 Id FROM @v_LastInsertedIdTable);

					INSERT INTO DataSourceFieldMetadata
					(FieldId, FieldAppRole)
					VALUES
					(@v_field_id, 41);

					-- EndStationNum Column
					DELETE FROM @v_LastInsertedIdTable;

					INSERT INTO DataSourceField
					(FieldName, DataTypeId, TableId)
					OUTPUT INSERTED.Id
					INTO @v_LastInsertedIdTable
					VALUES
					('EndStationNum', 2, @v_table_id);

					SET @v_field_id = (SELECT TOP 1 Id FROM @v_LastInsertedIdTable);

					INSERT INTO DataSourceFieldMetadata
					(FieldId, FieldAppRole)
					VALUES
					(@v_field_id, 49);
				END;
				COMMIT;
			END TRY
			BEGIN CATCH
				PRINT 'An error occurred: ' + ERROR_MESSAGE();
				ROLLBACK;
			END CATCH
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640301 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.4 Release 3 Updates 2
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '640302', DBVersionComment = 'Config Service Pack DDL 6.4, Rel. 3, Updates 2', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

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


-- CONFIG_FixCoordImportFieldIsListDomainSetting_45989.sql
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640302 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- CONFIG_FixCoordImportFieldIsListDomainSetting_45989.sql
			-- Correct import field LD config for coordinate projection. This is not a list domain.
			-- note: not set in other dbs so assume I was testing and forgot to reset.
			UPDATE ImportField SET IsListDomain = 0 
			WHERE Id in (SELECT  f.Id FROM ImportTable t
							JOIN ConfigurationSet c on c.Id = t.ConfigurationSetId AND c.ConfigurationSetName = 'ImportConfiguration'
							JOIN DataSourceTable d on t.DestinationTableId = d.Id
							LEFT JOIN ImportField f on f.importTableId = t.Id
							LEFT JOIN Variable v on f.VariableId = v.Id
							LEFT JOIN InternalField i on f.InternalFIeldId = i.Id
							LEFT JOIN UnitOfMeasure mu on mu.Id = f.MetricUnitOfMeasureId
							LEFT JOIN UnitOfMeasure iu on iu.Id = f.ImperialUnitOfMeasureId
							Where d.Name = 'InlineInspection' AND InternalFieldName = 'CoordinateProjection')
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


-- CONFIG_MoreImportFieldValidation_NoAppDB_45990.sql
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640302 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			-- CONFIG_MoreImportFieldValidation_NoAppDB_45990.sql
			-- Missed Excavation import config validation for import, no application database
			-- TODO, once orientation fields are updated, this should be precision 6, +-999.999 (scale = precision - sig digs of max/min)
			UPDATE DataSourceFieldMetaData SET Precision = 3, MaxValue = '999', MinValue = '-999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('PSPPipeOrientation', 'MechDmgOrientation', 'MetalLossOrientation', 'ESCAOrientation')
				)

			UPDATE DataSourceFieldMetaData SET Precision = 8, MaxValue = '999.99999', MinValue = '-999.99999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  in ('MetalLossMaxDepthPct', 'MechDmgDepthPct'))

			UPDATE DataSourceFieldMetaData SET Precision = 10, MaxValue = '9999999.999', MinValue = '-9999999.999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE v.Name Like '%Dist%_From_Girth_Weld' -- expect 10
				)

			UPDATE DataSourceFieldMetaData SET Precision = 9, MaxValue = '9999999.99', MinValue = '-9999999.99'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE v.Name in ('Excavation_Site_Crack_Anomaly_Length',
								 'Excavation_Site_Crack_Anomaly_Width',
								 'Mechanical_Damage_Length',
								 'Mechanical_Damage_Width',
								 'Metal_Loss_Length',
								 'Metal_Loss_Width')
				)

			UPDATE DataSourceFieldMetaData SET Precision = 9, MaxValue = '9999.99999', MinValue = '-9999.99999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE v.Name  = 'Pipe_Condition_Wall_Thickness'
				)

			UPDATE DataSourceFieldMetaData SET Precision = 8, MaxValue = '9999.9999', MinValue = '-9999.9999'
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE v.Name  = 'Pipe_Condition_Outsite_Diameter'
				);

			-- Associate the mapped destination field variables with the importfields where not already assigned.
			-- Import field variable used to validate import data if no app db.
			WITH ImportVars AS (
				SELECT sv.Id as varId, f.Id as importFieldId
					from StageDestinationXRef x
					JOIN variable sv on sv.Name = x.FieldName
					JOIN StageDestinationMap m on m.Id = x.StageDestinationMapId
					JOIN DataSourceTable dt on dt.Name = m.DestinationTableName
					Join ImportTable t on t.DestinationTableId = dt.Id
					Join ImportField f on f.InternalFieldId = x.InternalFieldId AND f.ImportTableId = t.Id 
						AND f.VariableId is null  AND IsListDomain = 0 AND IsCalculated = 0)
			UPDATE ImportField Set VariableId = (Select varId FROM ImportVars WHERE importFieldId = Id)
			WHERE Id in (Select ImportFieldId From ImportVars)

			-- Note excavation anomaly FeatureIdentifier and ExcavationSite SystemOfMeasurement fields do not require validation.
			-- Not validating ClusterId for Callbox since is validated in cluster.
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640302 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN


			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 3, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640302 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 3
		BEGIN
			
			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 4, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640302 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 4
		BEGIN


			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 5, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640302 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 5
		BEGIN


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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640302 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 6
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.4 Release 3 Updates 3
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '640303', DBVersionComment = 'Config Service Pack DDL 6.4, Rel. 3, Updates 3', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640303 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640303 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN

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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640303 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.4 Release 3 Updates 4
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '640304', DBVersionComment = 'Config Service Pack DDL 6.4, Rel. 3, Updates 4', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

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


-- CONFIG_FixImportVariableConfig_44376.sql
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640304 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- CONFIG_FixImportVariableConfig_44376.sql
			-- Correct wrong variable used for crack growth rate.
			UPDATE StageDestinationXRef SET FieldName = 'ILI_Crack_Growth_Rate' 
			WHERE ID =
				(SELECT mx.Id from StageDestinationMap m
				join StageDestinationXRef mx on mx.StageDestinationMapId = m.Id
				Join Variable v on v.name = mx.FieldName
				Join VariableFieldXRef vx on vx.VariableId = v.Id
				Join DataSourceField f on f.Id = vx.DataSourceFieldId
				Join DataSourceTable t on t.Id = f.TableId
				WHERE t.Name <> m.DestinationTableName AND m.DestinationTableName <> m.StagingTableName 
				 AND mx.FieldName = 'GrowthRate' And m.DestinationTableName = 'InlineInspectionCrackAnomaly')

			UPDATE ImportField SET VariableId = (SELECT Id FROM Variable WHERE Name = 'ILI_Crack_Growth_Rate') 
			WHERE ID = 
				(SELECT impf.Id FROM ImportField impf
					Join Variable v on v.Id = impf.VariableId
					Join VariableFieldXRef vx on vx.VariableId = v.Id
					Join DataSourceField f on f.Id = vx.DataSourceFieldId
					JOIN ImportTable impt on impt.Id = impf.ImportTableId AND impt.DestinationTableId <> f.TableId
					Join DataSourceTable t on t.Id = impt.DestinationTableId
				WHERE v.Name = 'GrowthRate' And t.Name = 'InlineInspectionCrackAnomaly')

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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640304 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.4 Release 3 Updates 5
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '640305', DBVersionComment = 'Config Service Pack DDL 6.4, Rel. 3, Updates 5', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

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


-- CONFIG_RemoveRangeVariablesFromILIImportConfig_46537.sql
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640305 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- CONFIG_RemoveRangeVariablesFromILIImportConfig_46537.sql
			-- Clear out the improper variable association of range variables to inline inspection fields
			-- Setup the range import field with all the appropriate data
			WITH IliData AS (
				SELECT f.Id AS iliRId, f2.FriendlyName AS DisplayName, f2.ColumnDescription As colDesc FROM ImportField f
				Join ImportField f2 on f2.Id != f.Id AND f2.InternalFieldId = f.InternalFieldId AND f2.VariableId = f.VariableId
					AND f2.ImportTableId = (SELECT t.Id FROM ImportTable t JOIN DataSourceTable dt on dt.Id = t.DestinationTableId AND dt.Name = 'InlineInspection')
					AND f.ImportTableId = (SELECT t.Id FROM ImportTable t JOIN DataSourceTable dt on dt.Id = t.DestinationTableId AND dt.Name = 'InlineInspectionRange')
			)
			UPDATE ImportField SET FriendlyName = (SELECT DisplayName FROM IliData WHERE iliRId = Id),
								   ColumnDescription = (SELECT colDesc FROM IliData WHERE iliRId = Id)
			WHERE Id in (SELECT iliRId FROM IliData);

			-- Get rid of the extra ili import fields properly represented by the range fields setup for the range table.
			WITH IliData AS (
				SELECT f2.Id AS iliId FROM ImportField f
				Join ImportField f2 on f2.Id != f.Id AND f2.InternalFieldId = f.InternalFieldId AND f2.VariableId = f.VariableId
					AND f2.ImportTableId = (SELECT t.Id FROM ImportTable t JOIN DataSourceTable dt on dt.Id = t.DestinationTableId AND dt.Name = 'InlineInspection')
					AND f.ImportTableId = (SELECT t.Id FROM ImportTable t JOIN DataSourceTable dt on dt.Id = t.DestinationTableId AND dt.Name = 'InlineInspectionRange')
			)
			DELETE FROM ImportField WHERE Id in (SELECT iliId FROM IliData WHERE iliId = Id);

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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640305 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.4 Release 3 Updates 6
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '640306', DBVersionComment = 'Config Service Pack DDL 6.4, Rel. 3, Updates 6', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

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


-- CONFIG_MoreImportFieldCorrections_46676.sql
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640306 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- CONFIG_MoreImportFieldCorrections_46676.sql
			-- No App Db corrections
			--    Correct facility orientation db validation configuration
			UPDATE DataSourceFieldMetaData SET Precision = 6, MaxValue = '999.999', MinValue = '-999.999'
			WHERE Id = (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName  = 'ILIFacOrientation' AND Precision <> 6
				)

			--    Correct import field requried states for dig import
			UPDATE ImportField Set IsRequired = 0 WHERE Id = (SELECT Id FROM ImportField WHERE IsRequired = 1 AND ColumnDescription = 'ExcavationSite Description')
			UPDATE ImportField Set IsRequired = 1 WHERE Id = (SELECT Id FROM ImportField WHERE IsRequired = 0 AND ColumnDescription = 'ExcavationSite Date')

			-- Correct import field required states for ili import
			UPDATE ImportField Set IsRequired = 0 WHERE Id = (SELECT f.Id FROM ImportField f
				 JOIN InternalField inf on f.IsRequired = 1 AND inf.Id = f.InternalFieldId AND inf.InternalFieldName = 'SpecVersion')
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 640306 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 1
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650001', DBVersionComment = 'Config Service Pack DDL 6.5, Rel. 0, Updates 1', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

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


-- POC_Fix_VirtualTable_Config.sql
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650001 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- POC_Fix_VirtualTable_Config.sql
			-- Declare the table to retrieve the data source field contains a mismatched data type.
			DECLARE @StageDatabaseName VARCHAR(100)
			DECLARE @SQL NVARCHAR(max)

			SET @StageDatabaseName = CAST(SESSION_CONTEXT(N'StageDatabaseName') as VARCHAR(100));

			-- For Oracle Stage databases
			IF @StageDatabaseName LIKE '%[_]OWNR'
			BEGIN
				SET @SQL = 'DECLARE @v_MismatchedTableType TABLE (VirtualColumnFieldId numeric(18, 0), FieldDataTypeId numeric(18, 0));
							INSERT INTO @v_MismatchedTableType
							(VirtualColumnFieldId, FieldDataTypeId)
							SELECT df.Id, 
								CASE
									WHEN vc.VirtualColumnDataTypeInd = ''f'' THEN 3
									WHEN vc.VirtualColumnDataTypeInd = ''i'' THEN 6
									WHEN vc.VirtualColumnDataTypeInd = ''n'' THEN 2
									WHEN vc.VirtualColumnDataTypeInd = ''d'' THEN 4
									ELSE 1
								END
							FROM DataSourceTable dt
							INNER JOIN DataSourceField df
								ON df.TableId = dt.Id
							INNER JOIN (SELECT * FROM OPENQUERY(' + QUOTENAME(@StageDatabaseName) + ', ''SELECT * FROM VirtualTable''))vt
								ON vt.VirtualTableName = dt.Name
							INNER JOIN (SELECT * FROM OPENQUERY(' + QUOTENAME(@StageDatabaseName) + ', ''SELECT * FROM VirtualColumn'')) vc
								ON vt.Id = vc.VirtualTableId
							WHERE vc.VirtualColumnDataTypeInd <> ''l''
							AND dt.TableType = 3
							AND df.DataTypeId = 5;
		
							-- Variables for iteration.
							DECLARE @v_field_id numeric(18, 0);
							DECLARE @v_field_data_type numeric(18, 0);

							-- Cursor to loop through the column_list.
							DECLARE mapping_cursor CURSOR FOR
							SELECT VirtualColumnFieldId, FieldDataTypeId FROM @v_MismatchedTableType;

							OPEN mapping_cursor;

							-- Fetch the table to be fixed.
							FETCH NEXT FROM mapping_cursor INTO @v_field_id, @v_field_data_type;
							WHILE @@FETCH_STATUS = 0
							BEGIN
								UPDATE DataSourceField
								SET DataTypeId = @v_field_data_type
								WHERE Id = @v_field_id;

								FETCH NEXT FROM mapping_cursor INTO @v_field_id, @v_field_data_type;
							END;

							CLOSE mapping_cursor;
							DEALLOCATE mapping_cursor;'
			END
			-- for SQL Server stage database
			ELSE
			BEGIN
				SET @sql = 'DECLARE @v_MismatchedTableType TABLE (VirtualColumnFieldId numeric(18, 0), FieldDataTypeId numeric(18, 0));
							INSERT INTO @v_MismatchedTableType
							(VirtualColumnFieldId, FieldDataTypeId)
							SELECT df.Id, 
								CASE
									WHEN vc.VirtualColumnDataTypeInd = ''f'' THEN 3
									WHEN vc.VirtualColumnDataTypeInd = ''i'' THEN 6
									WHEN vc.VirtualColumnDataTypeInd = ''n'' THEN 2
									WHEN vc.VirtualColumnDataTypeInd = ''d'' THEN 4
									ELSE 1
								END
							FROM DataSourceTable dt
							INNER JOIN DataSourceField df
								ON df.TableId = dt.Id
							INNER JOIN [' + @stageDatabaseName + '].dbo.VirtualTable vt
								ON vt.VirtualTableName = dt.Name
							INNER JOIN [' + @stageDatabaseName + '].dbo.VirtualColumn vc
								ON vt.Id = vc.VirtualTableId
							WHERE vc.VirtualColumnDataTypeInd <> ''l''
							AND dt.TableType = 3
							AND df.DataTypeId = 5;
		
							-- Variables for iteration.
							DECLARE @v_field_id numeric(18, 0);
							DECLARE @v_field_data_type numeric(18, 0);

							-- Cursor to loop through the column_list.
							DECLARE mapping_cursor CURSOR FOR
							SELECT VirtualColumnFieldId, FieldDataTypeId FROM @v_MismatchedTableType;

							OPEN mapping_cursor;

							-- Fetch the table to be fixed.
							FETCH NEXT FROM mapping_cursor INTO @v_field_id, @v_field_data_type;
							WHILE @@FETCH_STATUS = 0
							BEGIN
								UPDATE DataSourceField
								SET DataTypeId = @v_field_data_type
								WHERE Id = @v_field_id;

								FETCH NEXT FROM mapping_cursor INTO @v_field_id, @v_field_data_type;
							END;

							CLOSE mapping_cursor;
							DEALLOCATE mapping_cursor;'
			END

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


-- POC_ListDomain_DataModel.sql
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650001 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			-- POC_ListDomain_DataModel.sql
			-- Create the DataSourceTableDomainCatalog table
			DECLARE @StageDatabaseName  VARCHAR(100)
			DECLARE @SQL NVARCHAR(max)

			SET @StageDatabaseName = CAST(SESSION_CONTEXT(N'StageDatabaseName') as VARCHAR(100));

			IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DataSourceTableDomainCatalog]') AND type = 'U')
			BEGIN
				CREATE TABLE DataSourceTableDomainCatalog (
					[Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
					DataSourceTableId NUMERIC(18, 0) NOT NULL,
					DomainCatalog NVARCHAR(255) NOT NULL,
					DomainCatalogSourceId Numeric(18, 0) NOT NULL,
					[LastModByUserId] varchar(45) DEFAULT (suser_sname()) NOT NULL,
					[LastModDateTime] datetime DEFAULT (getdate()) NOT NULL,
					[CreatedUser] varchar(45) DEFAULT (suser_sname()) NOT NULL,
					[CreatedDate] datetime DEFAULT (getdate()) NOT NULL,
					CONSTRAINT PK_DataSourceTableDomainCatalog Primary Key (Id),
					CONSTRAINT UQ_DataSourceTableDomainCatalog UNIQUE (DataSourceTableId, DomainCatalogSourceId),
					CONSTRAINT FK_DataSourceTableDomainCatalog_DataSourceTableId
						FOREIGN KEY (DataSourceTableId)
						REFERENCES DataSourceTable(Id)
				);
			END
			
			SET @SQL = 'CREATE TRIGGER dbo.tu_DataSourceTableDomainCatalog ON dbo.DataSourceTableDomainCatalog FOR UPDATE AS 
			IF EXISTS(SELECT * FROM DELETED)
			BEGIN
				UPDATE dbo.DataSourceTableDomainCatalog
				SET LastModByUserId = suser_sname(), LastModDateTime = getdate() 
				FROM dbo.DataSourceTableDomainCatalog as t, DELETED as d
				WHERE t.Id=d.Id;
			END'
			
			EXECUTE (@SQL) 

			-- Insert the new list domain table type.
			IF NOT EXISTS (SELECT 1 FROM TableType WHERE Name = 'ListDomain')
			BEGIN
				SET IDENTITY_INSERT TableType ON;
				INSERT INTO TableType
				(Id, Name, Description)
				VALUES
				(4, 'ListDomain', 'A list domain table');
				SET IDENTITY_INSERT TableType OFF;
			END

			-- Delete ListDomain field meta data.
			DELETE FROM DataSourceFieldMetaData 
			WHERE FieldId IN (
				SELECT Id FROM DataSourceField WHERE TableId = (
					SELECT Id FROM DataSourceTable WHERE Name = 'ListDomain'
				)
			);
			-- Delete ListDomain field.
			DELETE FROM DataSourceField WHERE TableId = (
				SELECT Id FROM DataSourceTable WHERE Name = 'ListDomain'
			);
			-- Delete ListDomain table.
			DELETE FROM DataSourceTable WHERE Name = 'ListDomain';

			-- Declare the variables to store the last inserted ID.
			DECLARE @lastInsertedIdTable TABLE (Id numeric(18, 0));
			DECLARE @lastInsertedTableId numeric(18, 0);
			DECLARE @lastInsertedFieldId numeric(18, 0);

			-- Configure the HCA Reason Type table.
			SET @lastInsertedTableId = (SELECT Id FROM DataSourceTable WHERE Name = 'RCHCAReasonType');
			IF @lastInsertedTableId IS NULL
				BEGIN
					-- Create the data source table for the type.
					INSERT INTO DataSourceTable 
					(DataSourceId, Name, Description, TableType, DisplayName)
					OUTPUT INSERTED.Id
					INTO @lastInsertedIdTable
					VALUES
					(1, 'RCHCAReasonType', 'RCHCAReasonType', 4, 'RCHCAReasonType');

					SET @lastInsertedTableId = (SELECT TOP 1 Id FROM @lastInsertedIdTable);
					DELETE FROM @lastInsertedIdTable;
				END
			ELSE 
				BEGIN
					UPDATE DataSourceTable 
					SET TableType = 4
					WHERE Id = @lastInsertedTableId;
				END
		
			SET @lastInsertedFieldId = (SELECT Id FROM DataSourceField WHERE FieldName = 'Id' AND TableId = @lastInsertedTableId);
			IF @lastInsertedFieldId IS NULL
			BEGIN
				-- Create the data source field for the type.
				INSERT INTO DataSourceField
				(FieldName, DataTypeId, Description, TableId)
				OUTPUT INSERTED.Id
				INTO @lastInsertedIdTable
				VALUES
				('Id', 2, 'Id', @lastInsertedTableId);

				SET @lastInsertedFieldId = (SELECT TOP 1 Id FROM @lastInsertedIdTable);
				DELETE FROM @lastInsertedIdTable;

				INSERT INTO DataSourceFieldMetaData
				(FieldId, FieldAppRole)
				VALUES
				(@lastInsertedFieldId, 8193);
			END
		
			-- Declare the variable to store the child field ID.
			DECLARE @childFieldId numeric(18, 0);

			-- Insert the data relation.
			SET @childFieldId = (
				SELECT df.Id
				FROM DataSourceField df
				INNER JOIN DataSourceTable dt
					ON df.TableId = dt.Id
				WHERE dt.Name = 'HCACFRSeg'
				AND df.FieldName = 'RCReasonTypeId');

			IF (@childFieldId IS NOT NULL)  AND (NOT EXISTS (SELECT 1 from DataRelation WHERE ParentFieldId = @lastInsertedFieldId AND ChildFieldId = @childFieldId))
			BEGIN
				INSERT INTO DataRelation
				(Id, ParentFieldId, ChildFieldId, Comments)
				SELECT MAX(Id) + 1, @lastInsertedFieldId, @childFieldId, 'RCHCAReasonType -> HCACFRSeg'
				FROM DataRelation;
			END
			
			-- Update the description data source field.
			UPDATE DataSourceField
			SET FieldName = 'Descr'
			WHERE TableId = @lastInsertedTableId
			AND FieldName = 'Description';
			
			-- Populate the DataSource tables and columns if the TempListDomainTable exists.

			IF @stageDatabaseName = ''
			BEGIN
				THROW 51000, 'Missing @stageDatabaseName. Please enter the stage database before running this.', 1;  
			END
			ELSE IF (@StageDatabaseName LIKE '%[_]OWNR')
			BEGIN
				SET @SQL = 'IF EXISTS (SELECT * FROM OPENQUERY([' + @StageDatabaseName + '], ''SELECT 1 FROM user_tables WHERE UPPER(table_name) = UPPER(''''TempListDomainTable'''')''))
							BEGIN 
					
								-- Cursor to loop through the TempListDomainTable.
								DECLARE mapping_cursor CURSOR FOR
								SELECT TableType, LDTableName, TableName, ColumnName, DomainDescr, DomainCatalogId 
								FROM OPENQUERY([' + @StageDatabaseName + '],''SELECT * FROM TempListDomainTable'');

								OPEN mapping_cursor;

								-- Variables for iteration.
								DECLARE @tableType VARCHAR(255);
								DECLARE @listDomainTableName VARCHAR(255);
								DECLARE @TableName VARCHAR(255);
								DECLARE @ColumnName VARCHAR(255);
								DECLARE @domainCatalogName VARCHAR(255);
								DECLARE @domainCatalogSourceId NUMERIC(18, 0);
								DECLARE @lastInsertedTableId numeric(18, 0);
								DECLARE @lastInsertedIdTable TABLE (Id numeric(18, 0));
								DECLARE @lastInsertedFieldId numeric(18, 0);
								DECLARE @childFieldId numeric(18, 0);
			
								-- Fetch mapping.
								FETCH NEXT FROM mapping_cursor INTO @tableType, @listDomainTableName, @TableName, @ColumnName, @domainCatalogName, @domainCatalogSourceId;
								WHILE @@FETCH_STATUS = 0
								BEGIN
									SET @lastInsertedTableId = (SELECT Id FROM DataSourceTable WHERE Name = @listDomainTableName);
									IF @lastInsertedTableId IS NULL
									BEGIN
										-- Create the data source table for the type.
										INSERT INTO DataSourceTable 
										(DataSourceId, Name, Description, TableType, DisplayName)
										OUTPUT INSERTED.Id
										INTO @lastInsertedIdTable
										VALUES
										(1, @listDomainTableName, COALESCE(@domainCatalogName, @listDomainTableName), 4, @listDomainTableName);

										SET @lastInsertedTableId = (SELECT TOP 1 Id FROM @lastInsertedIdTable);
										DELETE FROM @lastInsertedIdTable;
									END

									-- Populate the DataSourceTableDomainCatalog table.
									IF NOT EXISTS (SELECT * FROM DataSourceTableDomainCatalog WHERE DataSourceTableId = @lastInsertedTableId AND DomainCatalog = @domainCatalogName) 
										AND @domainCatalogName IS NOT NULL
										AND @domainCatalogSourceId IS NOT NULL
										AND @tableType = ''Real''
									BEGIN
										INSERT INTO DataSourceTableDomainCatalog
										(DataSourceTableId, DomainCatalog, DomainCatalogSourceId)
										VALUES
										(@lastInsertedTableId, @domainCatalogName, @domainCatalogSourceId);
									END

									SET @lastInsertedFieldId = (SELECT Id FROM DataSourceField WHERE FieldName = ''Id'' AND TableId = @lastInsertedTableId);
									IF @lastInsertedFieldId IS NULL
									BEGIN
										-- Create the data source field for the type.
										INSERT INTO DataSourceField
										(FieldName, DataTypeId, Description, TableId)
										OUTPUT INSERTED.Id
										INTO @lastInsertedIdTable
										VALUES
										(''Code'', 1, ''Code'', @lastInsertedTableId);

										SET @lastInsertedFieldId = (SELECT TOP 1 Id FROM @lastInsertedIdTable);
										DELETE FROM @lastInsertedIdTable;
				
										INSERT INTO DataSourceFieldMetaData
										(FieldId, FieldAppRole)
										VALUES
										(@lastInsertedFieldId, 1);

										INSERT INTO DataSourceField
										(FieldName, DataTypeId, Description, TableId)
										OUTPUT INSERTED.Id
										INTO @lastInsertedIdTable
										VALUES
										(''Descr'', 1, ''Descr'', @lastInsertedTableId);

										SET @lastInsertedFieldId = (SELECT TOP 1 Id FROM @lastInsertedIdTable);
										DELETE FROM @lastInsertedIdTable;
				
										INSERT INTO DataSourceFieldMetaData
										(FieldId, FieldAppRole)
										VALUES
										(@lastInsertedFieldId, 1);

										INSERT INTO DataSourceField
										(FieldName, DataTypeId, Description, TableId)
										OUTPUT INSERTED.Id
										INTO @lastInsertedIdTable
										VALUES
										(''Id'', 2, ''Id'', @lastInsertedTableId);

										SET @lastInsertedFieldId = (SELECT TOP 1 Id FROM @lastInsertedIdTable);
										DELETE FROM @lastInsertedIdTable;

										INSERT INTO DataSourceFieldMetaData
										(FieldId, FieldAppRole)
										VALUES
										(@lastInsertedFieldId, 8193);
									END

									SET @childFieldId = (SELECT df.Id
									FROM DataSourceField df
									INNER JOIN DataSourceTable dt
										ON df.TableId = dt.Id
									WHERE dt.Name = @TableName
									AND df.FieldName = @ColumnName);

									IF (@childFieldId IS NOT NULL)  AND (NOT EXISTS (SELECT 1 from DataRelation WHERE ParentFieldId = @lastInsertedFieldId AND ChildFieldId = @childFieldId))
									BEGIN
										INSERT INTO DataRelation
										(Id, ParentFieldId, ChildFieldId, Comments)
										SELECT MAX(Id) + 1, @lastInsertedFieldId, @childFieldId, @listDomainTableName + N'' -> '' + @TableName
										FROM DataRelation;
									END

									FETCH NEXT FROM mapping_cursor INTO @tableType, @listDomainTableName, @TableName, @ColumnName, @domainCatalogName, @domainCatalogSourceId;
								END;

								CLOSE mapping_cursor;
								DEALLOCATE mapping_cursor;
							END'
			
			END
			ELSE
			BEGIN
				SET @SQL = 'IF object_id(''' + @StageDatabaseName + '.dbo.TempListDomainTable'') IS NOT NULL
				BEGIN 
					
					-- Cursor to loop through the TempListDomainTable.
					DECLARE mapping_cursor CURSOR FOR
					SELECT TableType, LDTableName, TableName, ColumnName, DomainDescr, DomainCatalogId FROM ' + @StageDatabaseName + '.dbo.TempListDomainTable;

					OPEN mapping_cursor;

					-- Variables for iteration.
					DECLARE @tableType VARCHAR(255);
					DECLARE @listDomainTableName VARCHAR(255);
					DECLARE @TableName VARCHAR(255);
					DECLARE @ColumnName VARCHAR(255);
					DECLARE @domainCatalogName VARCHAR(255);
					DECLARE @domainCatalogSourceId NUMERIC(18, 0);
					DECLARE @lastInsertedTableId numeric(18, 0);
					DECLARE @lastInsertedIdTable TABLE (Id numeric(18, 0));
					DECLARE @lastInsertedFieldId numeric(18, 0);
					DECLARE @childFieldId numeric(18, 0);
			
					-- Fetch mapping.
					FETCH NEXT FROM mapping_cursor INTO @tableType, @listDomainTableName, @TableName, @ColumnName, @domainCatalogName, @domainCatalogSourceId;
					WHILE @@FETCH_STATUS = 0
					BEGIN
						SET @lastInsertedTableId = (SELECT Id FROM DataSourceTable WHERE Name = @listDomainTableName);
						IF @lastInsertedTableId IS NULL
						BEGIN
							-- Create the data source table for the type.
							INSERT INTO DataSourceTable 
							(DataSourceId, Name, Description, TableType, DisplayName)
							OUTPUT INSERTED.Id
							INTO @lastInsertedIdTable
							VALUES
							(1, @listDomainTableName, COALESCE(@domainCatalogName, @listDomainTableName), 4, @listDomainTableName);

							SET @lastInsertedTableId = (SELECT TOP 1 Id FROM @lastInsertedIdTable);
							DELETE FROM @lastInsertedIdTable;
						END

						-- Populate the DataSourceTableDomainCatalog table.
						IF NOT EXISTS (SELECT * FROM DataSourceTableDomainCatalog WHERE DataSourceTableId = @lastInsertedTableId AND DomainCatalog = @domainCatalogName) 
							AND @domainCatalogName IS NOT NULL
							AND @domainCatalogSourceId IS NOT NULL
							AND @tableType = ''Real''
						BEGIN
							INSERT INTO DataSourceTableDomainCatalog
							(DataSourceTableId, DomainCatalog, DomainCatalogSourceId)
							VALUES
							(@lastInsertedTableId, @domainCatalogName, @domainCatalogSourceId);
						END

						SET @lastInsertedFieldId = (SELECT Id FROM DataSourceField WHERE FieldName = ''Id'' AND TableId = @lastInsertedTableId);
						IF @lastInsertedFieldId IS NULL
						BEGIN
							-- Create the data source field for the type.
							INSERT INTO DataSourceField
							(FieldName, DataTypeId, Description, TableId)
							OUTPUT INSERTED.Id
							INTO @lastInsertedIdTable
							VALUES
							(''Code'', 1, ''Code'', @lastInsertedTableId);

							SET @lastInsertedFieldId = (SELECT TOP 1 Id FROM @lastInsertedIdTable);
							DELETE FROM @lastInsertedIdTable;
				
							INSERT INTO DataSourceFieldMetaData
							(FieldId, FieldAppRole)
							VALUES
							(@lastInsertedFieldId, 1);

							INSERT INTO DataSourceField
							(FieldName, DataTypeId, Description, TableId)
							OUTPUT INSERTED.Id
							INTO @lastInsertedIdTable
							VALUES
							(''Descr'', 1, ''Descr'', @lastInsertedTableId);

							SET @lastInsertedFieldId = (SELECT TOP 1 Id FROM @lastInsertedIdTable);
							DELETE FROM @lastInsertedIdTable;
				
							INSERT INTO DataSourceFieldMetaData
							(FieldId, FieldAppRole)
							VALUES
							(@lastInsertedFieldId, 1);

							INSERT INTO DataSourceField
							(FieldName, DataTypeId, Description, TableId)
							OUTPUT INSERTED.Id
							INTO @lastInsertedIdTable
							VALUES
							(''Id'', 2, ''Id'', @lastInsertedTableId);

							SET @lastInsertedFieldId = (SELECT TOP 1 Id FROM @lastInsertedIdTable);
							DELETE FROM @lastInsertedIdTable;

							INSERT INTO DataSourceFieldMetaData
							(FieldId, FieldAppRole)
							VALUES
							(@lastInsertedFieldId, 8193);
						END

						SET @childFieldId = (SELECT df.Id
						FROM DataSourceField df
						INNER JOIN DataSourceTable dt
							ON df.TableId = dt.Id
						WHERE dt.Name = @TableName
						AND df.FieldName = @ColumnName);

						IF (@childFieldId IS NOT NULL)  AND (NOT EXISTS (SELECT 1 from DataRelation WHERE ParentFieldId = @lastInsertedFieldId AND ChildFieldId = @childFieldId))
						BEGIN
							INSERT INTO DataRelation
							(Id, ParentFieldId, ChildFieldId, Comments)
							SELECT MAX(Id) + 1, @lastInsertedFieldId, @childFieldId, @listDomainTableName + N'' -> '' + @TableName
							FROM DataRelation;
						END

						FETCH NEXT FROM mapping_cursor INTO @tableType, @listDomainTableName, @TableName, @ColumnName, @domainCatalogName, @domainCatalogSourceId;
					END;

					CLOSE mapping_cursor;
					DEALLOCATE mapping_cursor;
				END'
			
			END

			EXEC sp_executesql @sql

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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650001 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 2
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650002', DBVersionComment = 'Config Service Pack DDL 6.5, Rel. 0, Updates 2', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650002 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
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
			AND table_schema = 'dbo'

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

				IF (SELECT COUNT(*) FROM INFORMATION_SCHEMA.columns WHERE column_name LIKE 'Create%Date%' AND table_name = @TableName) > 1
				BEGIN

					SELECT TOP 1 @OldColumn = column_name FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName
					AND column_name LIKE 'Create%Date%' AND column_name <> 'CreatedDate'

					SET @SQL = 'UPDATE ' + @TableName + ' SET CreatedDate = ' + @OldColumn
					EXECUTE (@SQL)

				END
				
				IF (SELECT COUNT(*) FROM INFORMATION_SCHEMA.columns WHERE column_name LIKE 'LastMod%Date%' AND table_name = @TableName) > 1
				BEGIN

					SELECT TOP 1 @OldColumn = column_name FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName
					AND column_name LIKE 'LastMod%Date%' AND column_name <> 'LastModDateTime'

					SET @SQL = 'UPDATE ' + @TableName + ' SET LastModDateTime = ' + @OldColumn
					EXECUTE (@SQL)

				END		
				
				IF (SELECT COUNT(*) FROM INFORMATION_SCHEMA.columns WHERE column_name LIKE 'Create%User%' AND table_name = @TableName) > 1
				BEGIN

					SELECT TOP 1 @OldColumn = column_name FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName
					AND column_name LIKE 'Create%User%' AND column_name <> 'CreatedUser'

					SET @SQL = 'UPDATE ' + @TableName + ' SET CreatedUser = ' + @OldColumn
					EXECUTE (@SQL)

				END
				
				IF (SELECT COUNT(*) FROM INFORMATION_SCHEMA.columns WHERE column_name LIKE 'LastMod%User%' AND table_name = @TableName) > 1
				BEGIN

					SELECT TOP 1 @OldColumn = column_name FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName
					AND column_name LIKE 'LastMod%User%'  AND column_name <> 'LastModByUserId'

					SET @SQL = 'UPDATE ' + @TableName + ' SET LastModByUserId = ' + @OldColumn
					EXECUTE (@SQL)

				END

				------------------------------------------- Recreate Update Triggers on table -----------------------------------------------
				
				IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.columns WHERE table_name = @TableName AND column_name LIKE 'LastMod%' 
							AND column_name NOT IN ('LastModByUserId', 'LastModDateTime'))
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
	PRINT CHAR(10) + 'Suspected Failed SQL Statement: ' + CHAR(10) + CHAR(10) + @SQL + CHAR(10)
	RAISERROR('An error occured while applying upgrade at Version %s, Checkpoint %s.%s', 11, 0, @dbVersion, @checkPoint, @ErrorMsg)
	ROLLBACK TRAN
END CATCH
GO

BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650002 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 3
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650003', DBVersionComment = 'Config Service Pack DDL 6.5, Rel. 0, Updates 3', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 0, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
		END
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion varchar(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint varchar(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	RAISERROR( 'There is error occurred when applying upgrade at version %s, %s', 11, 0, @dbVersion, @checkPoint)
	ROLLBACK TRAN
END CATCH
GO


BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650003 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650003 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 4
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650004', DBVersionComment = 'Config Service Pack DDL 6.5, Rel. 0, Updates 4', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650004 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			-- CONFIG_50033_CreateILIComments_ConfigDBScript.sql
			/*******************************************
			 * For Backlog Item 50033: Creating Inline Inspection Comments Column in Inline Inspection Table
			 *
			 * This config DB script will be adding the configuration needed to map to the new ILIComments column
			 * that will be added to the InlineInspection table in the Stage Database.
			 *******************************************/

			-- Check if the ILIComments field exists in the DataSourceField table.
			IF NOT EXISTS (SELECT * FROM DataSourceField WHERE TableId = (SELECT TOP 1 Id FROM DataSourceTable WHERE Name = 'InlineInspection')
														   AND FieldName = 'ILIComments')
			BEGIN
				-- Create the ILIComments field if it does not exist.
				INSERT INTO DataSourceField
				(
					FieldName,
					DataTypeId,
					TableId
				)
				VALUES
				(
					'ILIComments',
					(SELECT Id FROM DataType WHERE Name = 'Text'),
					(SELECT Id FROM DataSourceTable WHERE Name = 'InlineInspection')
				);
			END

			-- Check if the metadata exists for the field.
			IF NOT EXISTS (SELECT * FROM DataSourceFieldMetadata WHERE FieldId = (SELECT TOP 1 Id FROM DataSourceField WHERE FieldName = 'ILIComments'
																														 AND TableId = (SELECT TOP 1 Id FROM DataSourceTable WHERE Name = 'InlineInspection')))
			BEGIN
				-- Create the meatadata for the ILIComments field.
				-- It will just indicate it can be 500 characters long.
				-- It has no special role.
				INSERT INTO DataSourceFieldMetadata
				(
					FieldId,
					Length,
					FieldAppRole
				)
				VALUES
				(
					(SELECT TOP 1 Id FROM DataSourceField WHERE FieldName = 'ILIComments' AND TableId = (SELECT TOP 1 Id FROM DataSourceTable WHERE Name = 'InlineInspection')),
					500,
					0
				);
			END

			-- Check if the variable for the ILI Comments exists.
			IF NOT EXISTS (SELECT * FROM Variable WHERE Name = 'Inline_Inspection_Comments')
			BEGIN
				-- Add the variable if it does not exist.
				-- We'll add it as part of the inline inspection group.
				INSERT INTO Variable
				(
					CategoryId,
					Name,
					DisplayText,
					DataTypeId,
					GroupId,
					AvailableApplication
				)
				VALUES
				(
					(SELECT Id FROM VariableCategory WHERE Name = 'Inline Inspection Range'),
					'Inline_Inspection_Comments',
					'Inline Inspection Comments',
					(SELECT Id FROM DataType WHERE Name = 'Text'),
					(SELECT Id FROM VariableGroup WHERE Name = 'Inline Inspection'),
					127 -- Allow for all applications
				)
			END

			-- Check if the variable has metadata associated with it, and add it if it doesn't.
			IF NOT EXISTS (SELECT * FROM VariableMetadata WHERE VariableId = (SELECT TOP 1 Id FROM Variable WHERE Name = 'Inline_Inspection_Comments'))
			BEGIN
				INSERT INTO VariableMetadata
				(
					VariableId,
					DecimalPlaceCount
				)
				VALUES
				(
					(SELECT Id FROM Variable WHERE Name = 'Inline_Inspection_Comments'),
					0
				);
			END

			-- Now, map the variable to the data source field.
			IF NOT EXISTS (SELECT * FROM VariableFieldXRef WHERE VariableId = (SELECT Id FROM Variable WHERE Name = 'Inline_Inspection_Comments'
															 AND DataSourceFieldId = (SELECT Id FROM DataSourceField WHERE FieldName = 'ILIComments'
																													   AND TableId = (SELECT Id FROM DataSourceTable WHERE Name = 'InlineInspection'))))
			BEGIN
				-- Insert the record that will map the field to the variable.
				INSERT INTO VariableFieldXRef
				(
					VariableId,
					DataSourceFieldId,
					DataSourceId
				)
				VALUES
				(
					(SELECT Id FROM Variable WHERE Name = 'Inline_Inspection_Comments'),
					(SELECT Id FROM DataSourceField WHERE FieldName = 'ILIComments'
													  AND TableId = (SELECT Id FROM DataSourceTable WHERE Name = 'InlineInspection')),
					1 -- Use 1 for the default datasource.
				)
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650004 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			-- CONFIG_ChangeCoatingConditionTypeLDTable_49577.sql
			-- Change the CoatingCondition 'CoatingCondLineTypeId' listdomain table to match the Coating 'CoatingTypeDomainId' listdomain table.
			-- so same types are used for both.
			DECLARE @OldCoatingConditionTypeLDTableFieldId INT
			DECLARE @CoatingTypeLDTableFieldId INT
			DECLARE @CoatingConditionTypeFieldId INT

			SET @CoatingConditionTypeFieldId = (
				Select Id from DataSourceField 
				WHERE FieldName = 'CoatingCondLineTypeLd' AND TableId = (Select Id From DataSourceTable WHERE Name = 'CoatingCondition')
			)

			SET @OldCoatingConditionTypeLDTableFieldId = (
				Select dr.ParentFieldId from DataRelation dr WHERE dr.ChildFieldId = @CoatingConditionTypeFieldId
			)

			SET @CoatingTypeLDTableFieldId = (
				Select dr.ParentFieldId from DataRelation dr 
				Join DataSourceField cf on cf.id = dr.ChildFieldId AND cf.FieldName = 'CoatingLineDomainId'
				Join DataSourceTable ct on cf.TableId = ct.Id and ct.Name = 'Coating'
				Join DataSourceField pf on pf.id = dr.ParentFieldId
				Join DataSourceTable pt on pf.TableId = pt.Id
			)

			IF @OldCoatingConditionTypeLDTableFieldId <> @CoatingTypeLDTableFieldId
			BEGIN
				UPDATE DataRelation Set ParentFieldId = @CoatingTypeLDTableFieldId
				WHERE ParentFieldId = @OldCoatingConditionTypeLDTableFieldId AND ChildFieldId = @CoatingConditionTypeFieldId
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


-- CONFIG_ImportFieldValidationFixSiteAnomalyOrientation_50221.sql
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650004 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 2
		BEGIN
			-- CONFIG_ImportFieldValidationFixSiteAnomalyOrientation_50221.sql
			-- Correct the orientation field precision and max/mins used for import validation by no app db.
			UPDATE DataSourceFieldMetaData SET Precision = 6, MaxValue = 999.999, MinValue = -999.999
			WHERE Id IN (
				SELECT Distinct fm.Id FROM DataSourceFieldMetaData fm 
					JOIN DataSourceField f on f.Id = fm.FieldId
					LEFT JOIN VariableFieldXRef vx on vx.DataSourceFieldId = f.Id
					LEFT JOIN Variable v on v.Id = vx.VariableId
					JOIN StageDestinationXRef sx on (sx.FieldName = f.FieldName OR sx.FieldName = v.Name)
				WHERE f.FieldName like '%Orientation' and Precision = 3
				)

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 3, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
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


-- CONFIG_RequireImportFieldSiteExposedPipeWT_49999.sql
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650004 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 3
		BEGIN
			-- CONFIG_RequireImportFieldSiteExposedPipeWT_49999.sql
			-- Correct Excavation site ExposedPipe (PipeCondition) wall thickness importField to be required
			DECLARE @importFieldId AS INT

			SET @importFieldId = (SELECT Id FROM ImportField 
				WHERE ImportTableId = (SELECT Id FROM ImportTable WHERE SourceTableName = 'ExposedPipes')
					AND InternalFieldId = (SELECT Id FROM InternalField WHERE InternalFieldName = 'WallThickness')
					)
			IF @importFieldId IS NOT NULL AND (SELECT IsRequired FROM ImportField WHERE Id = @importFieldId) = 0 
			BEGIN
				Update ImportField SET IsRequired = 1 WHERE Id = @importFieldId
			END

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 4, LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650004 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 4
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 5
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650005', DBVersionComment = 'Config Service Pack DDL 6.5, Rel. 0, Updates 5', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

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


--Config_FixVariableType_Bug50338.sql
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650005 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			--Config_FixVariableType_Bug50338.sql
			IF EXISTS(SELECT DataTypeId FROM Variable V INNER JOIN DataType D ON V.DataTypeId = D.Id WHERE V.Name = 'OF_Frost_Depth' AND D.Name = 'Lookup')
			BEGIN
				UPDATE [dbo].[Variable] SET DataTypeId = (SELECT Id FROM DataType WHERE Name = 'Number') WHERE Name = 'OF_Frost_Depth'
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
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) = 650005 AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 1
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.5 Release 0 Updates 6
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '650006', DBVersionComment = 'Config Service Pack DDL 6.5, Rel. 0, Updates 6', LastUpgradeDateTime = getdate(), LastUpgradeUserId = suser_sname(), LastUpgradeType = 'FULL'

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

/*
	Everything below this should remain at the end of this script. Any added code should be placed above
	this section and the @FinalDBVersion variable should be changed to the last DBVersion within this script
*/
BEGIN
	DECLARE @FinalDBVersion INT 
	DECLARE @DBVersion INT 
	DECLARE @CheckPoint INT
	DECLARE @ErrorMsg NVARCHAR(600)

	SET @FinalDBVersion = 650006

	SELECT @DBVersion = DBVersion, @CheckPoint = DBVersionCheckPoint
	FROM Versioninfo

	IF EXISTS (SELECT * FROM dbo.VersionInfo WHERE DBVersion BETWEEN 640206 AND @FinalDBVersion)
		AND @DBVersion <> @FinalDBVersion AND @CheckPoint <> 0
	BEGIN

		SET @ErrorMsg = 'The database upgrade did not complete. The database is currently at DBVersion ' 
		+ CAST(@DBVersion AS NVARCHAR) + ', Checkpoint ' + CAST(@CheckPoint AS NVARCHAR);
		
		THROW 51001, @ErrorMsg, 1
	END
	ELSE
	BEGIN
		PRINT 'This database is currently at DBVersion ' + CAST(@DBVersion AS NVARCHAR) 
		+ ', Checkpoint ' + CAST(@CheckPoint AS NVARCHAR) + '.'
		+ CHAR(10) + 'This script upgrades IRAS databases from DBVersion 640206 to ' + CAST(@FinalDBVersion AS NVARCHAR);
	END
END
GO