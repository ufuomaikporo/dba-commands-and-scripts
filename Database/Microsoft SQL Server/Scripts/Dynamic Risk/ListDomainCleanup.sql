/*

NOTE**:	Any singular UPDATE statement within this script that affects multiple rows will not be run automatically.
	These UPDATE statements will be printed out with an accompanying query to find the rows that will be
	affected by the statemtent. 
	
ACTION: After running the script, use the printed queries below to check the rows that will be affected before 
		manually running the printed UPDATE statements below
*/

IF OBJECT_ID('tempdb..##ManualRun') IS NOT NULL
BEGIN
	DROP TABLE ##ManualRun
END

IF OBJECT_ID('tempdb..##ManualRun') IS NULL
BEGIN
	CREATE TABLE ##ManualRun (Query NVARCHAR(MAX), cmd NVARCHAR(MAX));
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Winter' AND Descr = 'Winter' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Construction Season'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Pipe Construction Season')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Pipe Construction Season')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Winter', 
			'Winter', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Construction Season'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'United Pacific Projects' AND Descr = 'United Pacific Projects' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'ILI Company')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'ILI Company')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'United Pacific Projects', 
			'United Pacific Projects', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Ultra Sonic Metal Loss' AND Descr = 'Ultra Sonic Metal Loss' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'ILI Tool')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Ultra Sonic Metal Loss', 
			'Ultra Sonic Metal Loss', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Tilt Inspection' AND Descr = 'Tilt Inspection' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'MPI Contractor'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'MPI Contractor')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'MPI Contractor')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Tilt Inspection', 
			'Tilt Inspection', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'MPI Contractor'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Team Industrial Services - TISI Canada' AND Descr = 'Team Industrial Services - TISI Canada' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'MPI Contractor'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'MPI Contractor')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'MPI Contractor')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Team Industrial Services - TISI Canada', 
			'Team Industrial Services - TISI Canada', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'MPI Contractor'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Spring' AND Descr = 'Spring' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Construction Season'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Pipe Construction Season')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Pipe Construction Season')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Spring', 
			'Spring', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Construction Season'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Sand Blast' AND Descr = 'Sand Blast' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Surface Preparation Method'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Surface Preparation Method')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Surface Preparation Method')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Sand Blast', 
			'Sand Blast', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Surface Preparation Method'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Relief' AND Descr = 'Relief' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Type'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Valve Type')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Valve Type')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Relief', 
			'Relief', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Type'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Quest' AND Descr = 'Quest' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Call Box Interaction rule'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'ILI Call Box Interaction rule')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'ILI Call Box Interaction rule')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Quest', 
			'Quest', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Call Box Interaction rule'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Q-inline' AND Descr = 'Q-inline' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Defect Status'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'ILI Defect Status')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'ILI Defect Status')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Q-inline', 
			'Q-inline', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Defect Status'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Pneumatic' AND Descr = 'Pneumatic' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Operator Type'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Valve Operator Type')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Valve Operator Type')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Pneumatic', 
			'Pneumatic', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Operator Type'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Pipetel' AND Descr = 'Pipetel' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'ILI Company')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'ILI Company')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Pipetel', 
			'Pipetel', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Pipecare' AND Descr = 'Pipecare' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Status'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'ILI Status')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'ILI Status')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Pipecare', 
			'Pipecare', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Status'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Pinnacle Integrity Engineering' AND Descr = 'Pinnacle Integrity Engineering' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'MPI Contractor'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'MPI Contractor')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'MPI Contractor')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Pinnacle Integrity Engineering', 
			'Pinnacle Integrity Engineering', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'MPI Contractor'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'PAUT' AND Descr = 'PAUT' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'MPI Method'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'MPI Method')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'MPI Method')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'PAUT', 
			'PAUT', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'MPI Method'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'other' AND Descr = 'other' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Failure Pressure Algorithm'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Failure Pressure Algorithm')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Failure Pressure Algorithm')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'other', 
			'other', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Failure Pressure Algorithm'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Opportunisitc ' AND Descr = 'Opportunisitc ' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Excavation Type'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Excavation Type')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Excavation Type')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Opportunisitc ', 
			'Opportunisitc ', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Excavation Type'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Not Applicable' AND Descr = 'Not Applicable' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Coordinate System')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Not Applicable', 
			'Not Applicable', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Not Applicable' AND Descr = 'Not Applicable' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Axial Strain Available Analysis Type'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Axial Strain Available Analysis Type')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Axial Strain Available Analysis Type')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Not Applicable', 
			'Not Applicable', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Axial Strain Available Analysis Type'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'North Field' AND Descr = 'North Field' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'District / Division Name'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'District / Division Name')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'District / Division Name')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'North Field', 
			'North Field', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'District / Division Name'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'NG-18' AND Descr = 'NG-18' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Failure Pressure Algorithm'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Failure Pressure Algorithm')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Failure Pressure Algorithm')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'NG-18', 
			'NG-18', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Failure Pressure Algorithm'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'NAD 83 UTM Zone 17N' AND Descr = 'NAD 83 UTM Zone 17N' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Coordinate System')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'NAD 83 UTM Zone 17N', 
			'NAD 83 UTM Zone 17N', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'NAD 83 UTM Zone 16N' AND Descr = 'NAD 83 UTM Zone 16N' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Coordinate System')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'NAD 83 UTM Zone 16N', 
			'NAD 83 UTM Zone 16N', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'NAD 83 UTM Zone 15N' AND Descr = 'NAD 83 UTM Zone 15N' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Coordinate System')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'NAD 83 UTM Zone 15N', 
			'NAD 83 UTM Zone 15N', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'NAD 83 UTM Zone 14N' AND Descr = 'NAD 83 UTM Zone 14N' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Coordinate System')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'NAD 83 UTM Zone 14N', 
			'NAD 83 UTM Zone 14N', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'NAD 83 UTM Zone 13N' AND Descr = 'NAD 83 UTM Zone 13N' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Coordinate System')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'NAD 83 UTM Zone 13N', 
			'NAD 83 UTM Zone 13N', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'NAD 83 UTM Zone 12N' AND Descr = 'NAD 83 UTM Zone 12N' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Coordinate System')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'NAD 83 UTM Zone 12N', 
			'NAD 83 UTM Zone 12N', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'NAD 83 UTM Zone 11N' AND Descr = 'NAD 83 UTM Zone 11N' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Coordinate System')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'NAD 83 UTM Zone 11N', 
			'NAD 83 UTM Zone 11N', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'NAD 1983 10TM AEP Resource' AND Descr = 'NAD 1983 10TM AEP Resource' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Coordinate System')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'NAD 1983 10TM AEP Resource', 
			'NAD 1983 10TM AEP Resource', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'mod NG-18 (mod Ln Sec)' AND Descr = 'mod NG-18 (mod Ln Sec)' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Failure Pressure Algorithm'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Failure Pressure Algorithm')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Failure Pressure Algorithm')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'mod NG-18 (mod Ln Sec)', 
			'mod NG-18 (mod Ln Sec)', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Failure Pressure Algorithm'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'MFL-C/MFL/Geo/USCD' AND Descr = 'MFL-C/MFL/Geo/USCD' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'ILI Tool')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'MFL-C/MFL/Geo/USCD', 
			'MFL-C/MFL/Geo/USCD', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'MFL-C/MFL' AND Descr = 'MFL-C/MFL' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'ILI Tool')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'MFL-C/MFL', 
			'MFL-C/MFL', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'MFL-C/Geometry' AND Descr = 'MFL-C/Geometry' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'ILI Tool')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'MFL-C/Geometry', 
			'MFL-C/Geometry', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'MFL-C' AND Descr = 'MFL-C' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'ILI Tool')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'MFL-C', 
			'MFL-C', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Material Verification' AND Descr = 'Material Verification' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Excavation Type'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Excavation Type')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Excavation Type')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Material Verification', 
			'Material Verification', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Excavation Type'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Manual' AND Descr = 'Manual' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Operator Type'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Valve Operator Type')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Valve Operator Type')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Manual', 
			'Manual', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Operator Type'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Maintenance' AND Descr = 'Maintenance' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Excavation Type'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Excavation Type')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Excavation Type')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Maintenance', 
			'Maintenance', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Excavation Type'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Kmax' AND Descr = 'Kmax' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Failure Pressure Algorithm'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Failure Pressure Algorithm')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Failure Pressure Algorithm')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Kmax', 
			'Kmax', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Failure Pressure Algorithm'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Intero' AND Descr = 'Intero' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'ILI Type')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'ILI Type')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Intero', 
			'Intero', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Integrity' AND Descr = 'Integrity' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Excavation Type'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Excavation Type')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Excavation Type')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Integrity', 
			'Integrity', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Excavation Type'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'ILI Verification' AND Descr = 'ILI Verification' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Excavation Type'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Excavation Type')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Excavation Type')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'ILI Verification', 
			'ILI Verification', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Excavation Type'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Halfwave' AND Descr = 'Halfwave' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'ILI Facility Type')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Halfwave', 
			'Halfwave', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Gear' AND Descr = 'Gear' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Operator Type'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Valve Operator Type')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Valve Operator Type')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Gear', 
			'Gear', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Operator Type'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Full Integrity Inspection' AND Descr = 'Full Integrity Inspection' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'MPI Method'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'MPI Method')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'MPI Method')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Full Integrity Inspection', 
			'Full Integrity Inspection', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'MPI Method'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Full 360 MPI' AND Descr = 'Full 360 MPI' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'MPI Method'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'MPI Method')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'MPI Method')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Full 360 MPI', 
			'Full 360 MPI', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'MPI Method'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Fall' AND Descr = 'Fall' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Construction Season'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Pipe Construction Season')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Pipe Construction Season')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Fall', 
			'Fall', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Construction Season'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'failure' AND Descr = 'failure' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Excavation Type'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Excavation Type')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Excavation Type')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'failure', 
			'failure', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Excavation Type'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Exploritory' AND Descr = 'Exploritory' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Excavation Type'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Excavation Type')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Excavation Type')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Exploritory', 
			'Exploritory', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Excavation Type'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Entegra' AND Descr = 'Entegra' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'ILI Company')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'ILI Company')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Entegra', 
			'Entegra', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Enduro' AND Descr = 'Enduro' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'ILI Company')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'ILI Company')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Enduro', 
			'Enduro', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'EMAT/MFL-C/Geo' AND Descr = 'EMAT/MFL-C/Geo' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'ILI Tool')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'EMAT/MFL-C/Geo', 
			'EMAT/MFL-C/Geo', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'EMAT/MFL/Geo' AND Descr = 'EMAT/MFL/Geo' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'ILI Tool')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'EMAT/MFL/Geo', 
			'EMAT/MFL/Geo', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'EMAT/MFL' AND Descr = 'EMAT/MFL' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'ILI Tool')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'EMAT/MFL', 
			'EMAT/MFL', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'EMAT/Geo' AND Descr = 'EMAT/Geo' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'ILI Tool')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'EMAT/Geo', 
			'EMAT/Geo', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Construction' AND Descr = 'Construction' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Excavation Type'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Excavation Type')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Excavation Type')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Construction', 
			'Construction', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Excavation Type'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Color Contrast - Water Based' AND Descr = 'Color Contrast - Water Based' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'MPI Method'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'MPI Method')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'MPI Method')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Color Contrast - Water Based', 
			'Color Contrast - Water Based', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'MPI Method'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Circumferential Ultrasonic Crack' AND Descr = 'Circumferential Ultrasonic Crack' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'ILI Tool')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Circumferential Ultrasonic Crack', 
			'Circumferential Ultrasonic Crack', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Check Valve' AND Descr = 'Check Valve' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Operator Type'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Valve Operator Type')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Valve Operator Type')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Check Valve', 
			'Check Valve', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Operator Type'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Casing' AND Descr = 'Casing' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'ILI Facility Type')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Casing', 
			'Casing', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Canada_Albers_Equal_Area_Conic' AND Descr = 'Canada_Albers_Equal_Area_Conic' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Coordinate System')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Canada_Albers_Equal_Area_Conic', 
			'Canada_Albers_Equal_Area_Conic', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Bend Strain' AND Descr = 'Bend Strain' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'ILI Tool')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Bend Strain', 
			'Bend Strain', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Badger Construction & Associates Inc' AND Descr = 'Badger Construction & Associates Inc' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'MPI Contractor'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'MPI Contractor')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'MPI Contractor')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Badger Construction & Associates Inc', 
			'Badger Construction & Associates Inc', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'MPI Contractor'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Axial Ultrasonic Crack Detection (USCD)' AND Descr = 'Axial Ultrasonic Crack Detection (USCD)' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'ILI Tool')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Axial Ultrasonic Crack Detection (USCD)', 
			'Axial Ultrasonic Crack Detection (USCD)', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Axial Strain' AND Descr = 'Axial Strain' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'ILI Tool')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Axial Strain', 
			'Axial Strain', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'API 5L GR.B' AND Descr = 'API 5L GR.B' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Pipe Specification')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'API 5L GR.B', 
			'API 5L GR.B', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = 'Above Ground Marker' AND Descr = 'Above Ground Marker' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'ILI Facility Type')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'Above Ground Marker', 
			'Above Ground Marker', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = '75000' AND Descr = '75000' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Pipe Specification')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'75000', 
			'75000', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = '70000' AND Descr = '70000' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Pipe Specification')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'70000', 
			'70000', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = '65000' AND Descr = '65000' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Pipe Specification')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'65000', 
			'65000', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = '60000' AND Descr = '60000' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Pipe Specification')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'60000', 
			'60000', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = '56000' AND Descr = '56000' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Pipe Specification')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'56000', 
			'56000', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = '551' AND Descr = '551' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Pipe Specification')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'551', 
			'551', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = '52000' AND Descr = '52000' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Pipe Specification')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'52000', 
			'52000', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = '483' AND Descr = '483' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Pipe Specification')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'483', 
			'483', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = '46000' AND Descr = '46000' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Pipe Specification')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'46000', 
			'46000', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = '448' AND Descr = '448' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Pipe Specification')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'448', 
			'448', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = '42000' AND Descr = '42000' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Pipe Specification')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'42000', 
			'42000', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = '414' AND Descr = '414' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Pipe Specification')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'414', 
			'414', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = '3T x 3T' AND Descr = '3T x 3T' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Call Box Interaction rule'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'ILI Call Box Interaction rule')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'ILI Call Box Interaction rule')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'3T x 3T', 
			'3T x 3T', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Call Box Interaction rule'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = '386' AND Descr = '386' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Pipe Specification')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'386', 
			'386', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = '35000' AND Descr = '35000' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Pipe Specification')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'35000', 
			'35000', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = '317' AND Descr = '317' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Pipe Specification')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'317', 
			'317', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = '30000' AND Descr = '30000' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Pipe Specification')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'30000', 
			'30000', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = '290' AND Descr = '290' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'Pipe Specification')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'290', 
			'290', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE Code = '1in x 6t' AND Descr = '1in x 6t' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Call Box Interaction rule'))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE DomainDescr = 'ILI Call Box Interaction rule')
	BEGIN
		SET IDENTITY_INSERT dbo.DomainCatalog ON
		INSERT INTO DomainCatalog (Id, DomainDescr) VALUES ((SELECT MAX(Id) + 1 FROM DomainCatalog), 'ILI Call Box Interaction rule')
		SET IDENTITY_INSERT dbo.DomainCatalog OFF
	END

	SET IDENTITY_INSERT dbo.ListDomain ON
	INSERT INTO ListDomain (Id, Code, Descr, DomainCatalogId) 
			VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 
			'1in x 6t', 
			'1in x 6t', 
			(SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Call Box Interaction rule'))
	SET IDENTITY_INSERT dbo.ListDomain OFF
END

IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Y-70' AND Descr = 'Y-70'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Y-70' AND Descr = 'Y-70' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Y-70'' AND Descr = ''Y-70'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Y-70'' AND Descr = ''Y-70'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Y-65' AND Descr = 'Y-65'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Y-65' AND Descr = 'Y-65' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Y-65'' AND Descr = ''Y-65'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Y-65'' AND Descr = ''Y-65'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Y56/60' AND Descr = 'Y56/60'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Y56/60' AND Descr = 'Y56/60' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Y56/60'' AND Descr = ''Y56/60'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Y56/60'' AND Descr = ''Y56/60'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Y-52' AND Descr = 'Y-52'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Y-52' AND Descr = 'Y-52' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Y-52'' AND Descr = ''Y-52'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Y-52'' AND Descr = ''Y-52'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'X-70' AND Descr = 'X-70'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'X-70' AND Descr = 'X-70' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''X-70'' AND Descr = ''X-70'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''X-70'' AND Descr = ''X-70'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'X-65' AND Descr = 'X-65'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'X-65' AND Descr = 'X-65' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''X-65'' AND Descr = ''X-65'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''X-65'' AND Descr = ''X-65'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'X-60' AND Descr = 'X-60'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'X-60' AND Descr = 'X-60' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''X-60'' AND Descr = ''X-60'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''X-60'' AND Descr = ''X-60'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'X52' AND Descr = 'X52'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'X52' AND Descr = 'X52' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''X52'' AND Descr = ''X52'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''X52'' AND Descr = ''X52'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'X-52' AND Descr = 'X-52'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'X-52' AND Descr = 'X-52' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''X-52'' AND Descr = ''X-52'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''X-52'' AND Descr = ''X-52'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'X-49' AND Descr = 'X-49'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'X-49' AND Descr = 'X-49' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''X-49'' AND Descr = ''X-49'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''X-49'' AND Descr = ''X-49'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'X-46' AND Descr = 'X-46'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'X-46' AND Descr = 'X-46' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''X-46'' AND Descr = ''X-46'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''X-46'' AND Descr = ''X-46'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'X-42' AND Descr = 'X-42'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'X-42' AND Descr = 'X-42' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''X-42'' AND Descr = ''X-42'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''X-42'' AND Descr = ''X-42'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'X-30' AND Descr = 'X-30'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'X-30' AND Descr = 'X-30' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''X-30'' AND Descr = ''X-30'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''X-30'' AND Descr = ''X-30'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'WPHY-65' AND Descr = 'WPHY-65'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'WPHY-65' AND Descr = 'WPHY-65' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''WPHY-65'' AND Descr = ''WPHY-65'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''WPHY-65'' AND Descr = ''WPHY-65'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'WPHY-60' AND Descr = 'WPHY-60'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'WPHY-60' AND Descr = 'WPHY-60' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''WPHY-60'' AND Descr = ''WPHY-60'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''WPHY-60'' AND Descr = ''WPHY-60'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'WPHY-52' AND Descr = 'WPHY-52'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'WPHY-52' AND Descr = 'WPHY-52' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''WPHY-52'' AND Descr = ''WPHY-52'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''WPHY-52'' AND Descr = ''WPHY-52'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'WPHY-42' AND Descr = 'WPHY-42'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'WPHY-42' AND Descr = 'WPHY-42' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''WPHY-42'' AND Descr = ''WPHY-42'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''WPHY-42'' AND Descr = ''WPHY-42'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Widespread Circum. Corrosion' AND Descr = 'Widespread Circum. Corrosion'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Widespread Circum. Corrosion' AND Descr = 'Widespread Circum. Corrosion' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Widespread Circum. Corrosion'' AND Descr = ''Widespread Circum. Corrosion'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Widespread Circum. Corrosion'' AND Descr = ''Widespread Circum. Corrosion'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Widespread Circum. Corrosion' AND Descr = 'Widespread Circum. Corrosion'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Widespread Circum. Corrosion' AND Descr = 'Widespread Circum. Corrosion' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Widespread Circum. Corrosion'' AND Descr = ''Widespread Circum. Corrosion'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Widespread Circum. Corrosion'' AND Descr = ''Widespread Circum. Corrosion'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Weld-Anomaly' AND Descr = 'Weld-Anomaly'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Weld-Anomaly' AND Descr = 'Weld-Anomaly' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Weld-Anomaly'' AND Descr = ''Weld-Anomaly'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Weld-Anomaly'' AND Descr = ''Weld-Anomaly'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Weld Indication' AND Descr = 'Weld Indication'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Weld Indication' AND Descr = 'Weld Indication' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Weld Indication'' AND Descr = ''Weld Indication'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Weld Indication'' AND Descr = ''Weld Indication'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'WELD' AND Descr = 'WELD'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'WELD' AND Descr = 'WELD' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''WELD'' AND Descr = ''WELD'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''WELD'' AND Descr = ''WELD'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'W.T. CHANGE' AND Descr = 'W.T. CHANGE'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'W.T. CHANGE' AND Descr = 'W.T. CHANGE' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''W.T. CHANGE'' AND Descr = ''W.T. CHANGE'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Facility Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''W.T. CHANGE'' AND Descr = ''W.T. CHANGE'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Facility Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Vetco' AND Descr = 'Vetco'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Vetco' AND Descr = 'Vetco' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Vetco'' AND Descr = ''Vetco'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Company'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Vetco'' AND Descr = ''Vetco'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Company'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'USCD' AND Descr = 'Ultrasonic Crack Detection / Ultrasonic Technology Crack'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'USCD' AND Descr = 'Ultrasonic Crack Detection / Ultrasonic Technology Crack' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''USCD'' AND Descr = ''Ultrasonic Crack Detection / Ultrasonic Technology Crack'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''USCD'' AND Descr = ''Ultrasonic Crack Detection / Ultrasonic Technology Crack'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'USCD' AND Descr = 'Ultrasonic Crack Detection / Ultrasonic Technology Crack'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'USCD' AND Descr = 'Ultrasonic Crack Detection / Ultrasonic Technology Crack' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''USCD'' AND Descr = ''Ultrasonic Crack Detection / Ultrasonic Technology Crack'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Tool'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''USCD'' AND Descr = ''Ultrasonic Crack Detection / Ultrasonic Technology Crack'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Tool'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Unknown ID anomaly' AND Descr = 'Unknown ID anomaly'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Unknown ID anomaly' AND Descr = 'Unknown ID anomaly' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Unknown ID anomaly'' AND Descr = ''Unknown ID anomaly'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Unknown ID anomaly'' AND Descr = ''Unknown ID anomaly'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Unknown defect' AND Descr = 'Unknown defect'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Unknown defect' AND Descr = 'Unknown defect' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Unknown defect'' AND Descr = ''Unknown defect'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Unknown defect'' AND Descr = ''Unknown defect'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Unknown' AND Descr = 'Unknown2'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Non Crsn Dfct Status')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Unknown' AND Descr = 'Unknown2' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Non Crsn Dfct Status')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Unknown'' AND Descr = ''Unknown2'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Non Crsn Dfct Status'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Unknown'' AND Descr = ''Unknown2'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Non Crsn Dfct Status'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Unknown' AND Descr = 'Unknown'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Unknown' AND Descr = 'Unknown' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Unknown'' AND Descr = ''Unknown'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Unknown'' AND Descr = ''Unknown'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Unknown' AND Descr = 'Unknown'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Unknown' AND Descr = 'Unknown' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Unknown'' AND Descr = ''Unknown'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Unknown'' AND Descr = ''Unknown'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Unknown' AND Descr = 'Unknown'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Unknown' AND Descr = 'Unknown' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Unknown'' AND Descr = ''Unknown'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Unknown'' AND Descr = ''Unknown'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Unknown' AND Descr = 'Unknown'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Unknown' AND Descr = 'Unknown' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Unknown'' AND Descr = ''Unknown'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Area Name'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Unknown'' AND Descr = ''Unknown'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Area Name'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Ultra Sonic' AND Descr = 'Ultrasonic Thickness'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Ultra Sonic' AND Descr = 'Ultrasonic Thickness' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Ultra Sonic'' AND Descr = ''Ultrasonic Thickness'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Ultra Sonic'' AND Descr = ''Ultrasonic Thickness'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Ultra Sonic' AND Descr = 'Ultrasonic Thickness'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Ultra Sonic' AND Descr = 'Ultrasonic Thickness' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Ultra Sonic'' AND Descr = ''Ultrasonic Thickness'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Tool'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Ultra Sonic'' AND Descr = ''Ultrasonic Thickness'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Tool'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'TFL (TFI)' AND Descr = 'TFL (TFI)'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'TFL (TFI)' AND Descr = 'TFL (TFI)' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''TFL (TFI)'' AND Descr = ''TFL (TFI)'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''TFL (TFI)'' AND Descr = ''TFL (TFI)'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'TFL (TFI)' AND Descr = 'TFL (TFI)'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'TFL (TFI)' AND Descr = 'TFL (TFI)' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''TFL (TFI)'' AND Descr = ''TFL (TFI)'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Tool'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''TFL (TFI)'' AND Descr = ''TFL (TFI)'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Tool'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Test1' AND Descr = 'Test1'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Test1' AND Descr = 'Test1' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Test1'' AND Descr = ''Test1'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Facility Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Test1'' AND Descr = ''Test1'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Facility Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Test' AND Descr = 'Test'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Test' AND Descr = 'Test' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Test'' AND Descr = ''Test'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Test'' AND Descr = ''Test'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'TEEINDICATION' AND Descr = 'TEEINDICATION'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'TEEINDICATION' AND Descr = 'TEEINDICATION' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''TEEINDICATION'' AND Descr = ''TEEINDICATION'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''TEEINDICATION'' AND Descr = ''TEEINDICATION'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Tee CL' AND Descr = 'Tee CL'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Tee CL' AND Descr = 'Tee CL' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Tee CL'' AND Descr = ''Tee CL'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Facility Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Tee CL'' AND Descr = ''Tee CL'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Facility Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Tape' AND Descr = 'Tape'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Tape' AND Descr = 'Tape' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Tape'' AND Descr = ''Tape'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Tape'' AND Descr = ''Tape'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Tap CL' AND Descr = 'Tap CL'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Tap CL' AND Descr = 'Tap CL' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Tap CL'' AND Descr = ''Tap CL'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Facility Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Tap CL'' AND Descr = ''Tap CL'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Facility Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Take Off G12' AND Descr = 'Take Off G12'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Take Off G12' AND Descr = 'Take Off G12' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Take Off G12'' AND Descr = ''Take Off G12'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Valve Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Take Off G12'' AND Descr = ''Take Off G12'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Valve Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Steelman' AND Descr = 'Steelman'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'District / Division Name')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Steelman' AND Descr = 'Steelman' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'District / Division Name')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Steelman'' AND Descr = ''Steelman'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''District / Division Name'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Steelman'' AND Descr = ''Steelman'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''District / Division Name'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Steelman' AND Descr = 'Steelman'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Steelman' AND Descr = 'Steelman' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Steelman'' AND Descr = ''Steelman'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Area Name'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Steelman'' AND Descr = ''Steelman'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Area Name'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'SpirAll MFL/Geometry' AND Descr = 'SpirAll MFL/Geometry'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'SpirAll MFL/Geometry' AND Descr = 'SpirAll MFL/Geometry' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''SpirAll MFL/Geometry'' AND Descr = ''SpirAll MFL/Geometry'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Tool'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''SpirAll MFL/Geometry'' AND Descr = ''SpirAll MFL/Geometry'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Tool'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Spiral Seam Corrosion' AND Descr = 'Spiral Seam Corrosion'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Spiral Seam Corrosion' AND Descr = 'Spiral Seam Corrosion' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Spiral Seam Corrosion'' AND Descr = ''Spiral Seam Corrosion'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Spiral Seam Corrosion'' AND Descr = ''Spiral Seam Corrosion'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Sleeve CL' AND Descr = 'Sleeve CL'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Sleeve CL' AND Descr = 'Sleeve CL' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Sleeve CL'' AND Descr = ''Sleeve CL'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Facility Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Sleeve CL'' AND Descr = ''Sleeve CL'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Facility Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Single-Wrap Polyken' AND Descr = 'Single-Wrap Polyken'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Single-Wrap Polyken' AND Descr = 'Single-Wrap Polyken' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Single-Wrap Polyken'' AND Descr = ''Single-Wrap Polyken'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Single-Wrap Polyken'' AND Descr = ''Single-Wrap Polyken'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Seamless 711-11' AND Descr = 'Seamless 711-11'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Seamless 711-11' AND Descr = 'Seamless 711-11' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Seamless 711-11'' AND Descr = ''Seamless 711-11'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Seamless 711-11'' AND Descr = ''Seamless 711-11'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Seamless 711 Primer' AND Descr = 'Seamless 711 Primer'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Seamless 711 Primer' AND Descr = 'Seamless 711 Primer' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Seamless 711 Primer'' AND Descr = ''Seamless 711 Primer'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Seamless 711 Primer'' AND Descr = ''Seamless 711 Primer'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'SDR 26' AND Descr = 'SDR 26-Plastic Pipe'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'SDR 26' AND Descr = 'SDR 26-Plastic Pipe' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''SDR 26'' AND Descr = ''SDR 26-Plastic Pipe'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''SDR 26'' AND Descr = ''SDR 26-Plastic Pipe'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'SDR 21' AND Descr = 'SDR 21-Plastic Pipe'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'SDR 21' AND Descr = 'SDR 21-Plastic Pipe' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''SDR 21'' AND Descr = ''SDR 21-Plastic Pipe'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''SDR 21'' AND Descr = ''SDR 21-Plastic Pipe'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'SDR 17' AND Descr = 'SDR 17-Plastic Pipe'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'SDR 17' AND Descr = 'SDR 17-Plastic Pipe' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''SDR 17'' AND Descr = ''SDR 17-Plastic Pipe'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''SDR 17'' AND Descr = ''SDR 17-Plastic Pipe'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'SDR 13.5' AND Descr = 'SDR 13.5-Plastic Pipe'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'SDR 13.5' AND Descr = 'SDR 13.5-Plastic Pipe' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''SDR 13.5'' AND Descr = ''SDR 13.5-Plastic Pipe'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''SDR 13.5'' AND Descr = ''SDR 13.5-Plastic Pipe'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'SDR 11' AND Descr = 'SDR 11-Plastic Pipe'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'SDR 11' AND Descr = 'SDR 11-Plastic Pipe' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''SDR 11'' AND Descr = ''SDR 11-Plastic Pipe'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''SDR 11'' AND Descr = ''SDR 11-Plastic Pipe'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'SDR 10' AND Descr = 'SDR 10-Plastic Pipe'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'SDR 10' AND Descr = 'SDR 10-Plastic Pipe' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''SDR 10'' AND Descr = ''SDR 10-Plastic Pipe'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''SDR 10'' AND Descr = ''SDR 10-Plastic Pipe'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'SCCCrackTool' AND Descr = 'SCCCrackTool'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'SCCCrackTool' AND Descr = 'SCCCrackTool' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''SCCCrackTool'' AND Descr = ''SCCCrackTool'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''SCCCrackTool'' AND Descr = ''SCCCrackTool'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'SCCCrackTool' AND Descr = 'SCCCrackTool'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'SCCCrackTool' AND Descr = 'SCCCrackTool' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''SCCCrackTool'' AND Descr = ''SCCCrackTool'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''SCCCrackTool'' AND Descr = ''SCCCrackTool'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Rosen Canada Ltd.' AND Descr = 'Rosen Canada Ltd.'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Rosen Canada Ltd.' AND Descr = 'Rosen Canada Ltd.' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Rosen Canada Ltd.'' AND Descr = ''Rosen Canada Ltd.'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Company'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Rosen Canada Ltd.'' AND Descr = ''Rosen Canada Ltd.'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Company'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Rosen Canada' AND Descr = 'Rosen Canada'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Rosen Canada' AND Descr = 'Rosen Canada' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Rosen Canada'' AND Descr = ''Rosen Canada'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Company'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Rosen Canada'' AND Descr = ''Rosen Canada'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Company'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Ripple' AND Descr = 'Ripple'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Non Corrosion Defect')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Ripple' AND Descr = 'Ripple' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Non Corrosion Defect')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Ripple'' AND Descr = ''Ripple'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Non Corrosion Defect'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Ripple'' AND Descr = ''Ripple'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Non Corrosion Defect'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'RELIEF' AND Descr = 'RELIEF'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'RELIEF' AND Descr = 'RELIEF' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''RELIEF'' AND Descr = ''RELIEF'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Valve Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''RELIEF'' AND Descr = ''RELIEF'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Valve Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'PUDDLE WELD' AND Descr = 'PUDDLE WELD'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'PUDDLE WELD' AND Descr = 'PUDDLE WELD' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''PUDDLE WELD'' AND Descr = ''PUDDLE WELD'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''PUDDLE WELD'' AND Descr = ''PUDDLE WELD'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Possible Weld Indication' AND Descr = 'Possible Weld Indication'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Possible Weld Indication' AND Descr = 'Possible Weld Indication' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Possible Weld Indication'' AND Descr = ''Possible Weld Indication'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Possible Weld Indication'' AND Descr = ''Possible Weld Indication'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Possible Weld Defect' AND Descr = 'Possible Weld Defect'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Possible Weld Defect' AND Descr = 'Possible Weld Defect' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Possible Weld Defect'' AND Descr = ''Possible Weld Defect'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Possible Weld Defect'' AND Descr = ''Possible Weld Defect'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Possible manufacturing feature' AND Descr = 'Possible manufacturing feature'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Possible manufacturing feature' AND Descr = 'Possible manufacturing feature' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Possible manufacturing feature'' AND Descr = ''Possible manufacturing feature'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Possible manufacturing feature'' AND Descr = ''Possible manufacturing feature'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Possible ID anomaly' AND Descr = 'Possible ID anomaly'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Possible ID anomaly' AND Descr = 'Possible ID anomaly' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Possible ID anomaly'' AND Descr = ''Possible ID anomaly'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Possible ID anomaly'' AND Descr = ''Possible ID anomaly'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Possible Feature C' AND Descr = 'Possible Feature C'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Possible Feature C' AND Descr = 'Possible Feature C' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Possible Feature C'' AND Descr = ''Possible Feature C'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Possible Feature C'' AND Descr = ''Possible Feature C'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Possible Feature B' AND Descr = 'Possible Feature B'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Possible Feature B' AND Descr = 'Possible Feature B' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Possible Feature B'' AND Descr = ''Possible Feature B'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Possible Feature B'' AND Descr = ''Possible Feature B'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Possible Feature A' AND Descr = 'Possible Feature A'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Possible Feature A' AND Descr = 'Possible Feature A' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Possible Feature A'' AND Descr = ''Possible Feature A'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Possible Feature A'' AND Descr = ''Possible Feature A'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Possible Dent' AND Descr = 'Possible Dent'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Possible Dent' AND Descr = 'Possible Dent' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Possible Dent'' AND Descr = ''Possible Dent'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Possible Dent'' AND Descr = ''Possible Dent'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Positive Projects International Ltd.' AND Descr = 'Positive Projects International Ltd.'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Positive Projects International Ltd.' AND Descr = 'Positive Projects International Ltd.' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Positive Projects International Ltd.'' AND Descr = ''Positive Projects International Ltd.'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Company'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Positive Projects International Ltd.'' AND Descr = ''Positive Projects International Ltd.'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Company'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Positive Projects (GE)' AND Descr = 'Positive Projects (GE)'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Positive Projects (GE)' AND Descr = 'Positive Projects (GE)' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Positive Projects (GE)'' AND Descr = ''Positive Projects (GE)'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Company'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Positive Projects (GE)'' AND Descr = ''Positive Projects (GE)'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Company'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Polyken Primer 919' AND Descr = 'Polyken Primer 919'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Polyken Primer 919' AND Descr = 'Polyken Primer 919' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Polyken Primer 919'' AND Descr = ''Polyken Primer 919'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Polyken Primer 919'' AND Descr = ''Polyken Primer 919'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Polyken Blue Guard' AND Descr = 'Polyken Blue Guard'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Polyken Blue Guard' AND Descr = 'Polyken Blue Guard' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Polyken Blue Guard'' AND Descr = ''Polyken Blue Guard'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Polyken Blue Guard'' AND Descr = ''Polyken Blue Guard'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Polyguard RD-6' AND Descr = 'Polyguard RD-6'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Polyguard RD-6' AND Descr = 'Polyguard RD-6' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Polyguard RD-6'' AND Descr = ''Polyguard RD-6'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Polyguard RD-6'' AND Descr = ''Polyguard RD-6'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Poly Tape' AND Descr = 'Poly Tape'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Poly Tape' AND Descr = 'Poly Tape' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Poly Tape'' AND Descr = ''Poly Tape'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Poly Tape'' AND Descr = ''Poly Tape'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Poly Tape' AND Descr = 'Poly Tape'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Poly Tape' AND Descr = 'Poly Tape' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Poly Tape'' AND Descr = ''Poly Tape'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Poly Tape'' AND Descr = ''Poly Tape'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'PLWD' AND Descr = 'PLWD'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'PLWD' AND Descr = 'PLWD' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''PLWD'' AND Descr = ''PLWD'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''PLWD'' AND Descr = ''PLWD'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'PLOT/UNKN' AND Descr = 'PLOT/UNKN'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'PLOT/UNKN' AND Descr = 'PLOT/UNKN' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''PLOT/UNKN'' AND Descr = ''PLOT/UNKN'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''PLOT/UNKN'' AND Descr = ''PLOT/UNKN'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Plains Midstream' AND Descr = 'Plains Midstream'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Operator Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Plains Midstream' AND Descr = 'Plains Midstream' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Operator Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Plains Midstream'' AND Descr = ''Plains Midstream'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Valve Operator Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Plains Midstream'' AND Descr = ''Plains Midstream'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Valve Operator Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Pipeline Fitting' AND Descr = 'Pipeline Fitting'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Pipeline Fitting' AND Descr = 'Pipeline Fitting' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Pipeline Fitting'' AND Descr = ''Pipeline Fitting'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Facility Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Pipeline Fitting'' AND Descr = ''Pipeline Fitting'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Facility Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'PII' AND Descr = 'PII'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'PII' AND Descr = 'PII' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''PII'' AND Descr = ''PII'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Company'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''PII'' AND Descr = ''PII'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Company'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'PE 4710' AND Descr = 'PE 4710'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'PE 4710' AND Descr = 'PE 4710' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''PE 4710'' AND Descr = ''PE 4710'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''PE 4710'' AND Descr = ''PE 4710'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'PE 3408' AND Descr = 'PE 3408'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'PE 3408' AND Descr = 'PE 3408' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''PE 3408'' AND Descr = ''PE 3408'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''PE 3408'' AND Descr = ''PE 3408'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Patch CL' AND Descr = 'Patch CL'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Patch CL' AND Descr = 'Patch CL' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Patch CL'' AND Descr = ''Patch CL'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Facility Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Patch CL'' AND Descr = ''Patch CL'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Facility Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'P. FEATURE C' AND Descr = 'P. FEATURE C'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'P. FEATURE C' AND Descr = 'P. FEATURE C' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''P. FEATURE C'' AND Descr = ''P. FEATURE C'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''P. FEATURE C'' AND Descr = ''P. FEATURE C'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'P. FEATURE B' AND Descr = 'P. FEATURE B'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'P. FEATURE B' AND Descr = 'P. FEATURE B' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''P. FEATURE B'' AND Descr = ''P. FEATURE B'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''P. FEATURE B'' AND Descr = ''P. FEATURE B'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'P. FEATURE A' AND Descr = 'P. FEATURE A'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'P. FEATURE A' AND Descr = 'P. FEATURE A' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''P. FEATURE A'' AND Descr = ''P. FEATURE A'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''P. FEATURE A'' AND Descr = ''P. FEATURE A'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Notch-like' AND Descr = 'Notch-like'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Notch-like' AND Descr = 'Notch-like' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Notch-like'' AND Descr = ''Notch-like'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Notch-like'' AND Descr = ''Notch-like'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Not Complete' AND Descr = 'Not Complete'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Status')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Not Complete' AND Descr = 'Not Complete' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Status')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Not Complete'' AND Descr = ''Not Complete'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Status'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Not Complete'' AND Descr = ''Not Complete'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Status'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'N/A' AND Descr = 'Not Applicable'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'N/A' AND Descr = 'Not Applicable' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''N/A'' AND Descr = ''Not Applicable'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Coordinate System'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''N/A'' AND Descr = ''Not Applicable'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Coordinate System'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'N/A' AND Descr = 'Not Applicable'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Axial Strain Available Analysis Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'N/A' AND Descr = 'Not Applicable' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Axial Strain Available Analysis Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''N/A'' AND Descr = ''Not Applicable'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Axial Strain Available Analysis Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''N/A'' AND Descr = ''Not Applicable'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Axial Strain Available Analysis Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Milling Feature' AND Descr = 'Milling Feature'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Milling Feature' AND Descr = 'Milling Feature' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Milling Feature'' AND Descr = ''Milling Feature'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Milling Feature'' AND Descr = ''Milling Feature'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Mill Defect' AND Descr = 'Mill Defect'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Mill Defect' AND Descr = 'Mill Defect' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Mill Defect'' AND Descr = ''Mill Defect'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Mill Defect'' AND Descr = ''Mill Defect'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'MFL/Geometry/AFD/USCD' AND Descr = 'MFL/Geometry/AFD/USCD'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'MFL/Geometry/AFD/USCD' AND Descr = 'MFL/Geometry/AFD/USCD' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''MFL/Geometry/AFD/USCD'' AND Descr = ''MFL/Geometry/AFD/USCD'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Tool'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''MFL/Geometry/AFD/USCD'' AND Descr = ''MFL/Geometry/AFD/USCD'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Tool'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'MFL/Caliper' AND Descr = 'MFL/Caliper'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'MFL/Caliper' AND Descr = 'MFL/Caliper' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''MFL/Caliper'' AND Descr = ''MFL/Caliper'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''MFL/Caliper'' AND Descr = ''MFL/Caliper'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'MFL/AFD/Geometry' AND Descr = 'MFL/AFD/Geometry'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'MFL/AFD/Geometry' AND Descr = 'MFL/AFD/Geometry' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''MFL/AFD/Geometry'' AND Descr = ''MFL/AFD/Geometry'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Tool'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''MFL/AFD/Geometry'' AND Descr = ''MFL/AFD/Geometry'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Tool'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'MFL/AFD' AND Descr = 'MFL/AFD'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'MFL/AFD' AND Descr = 'MFL/AFD' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''MFL/AFD'' AND Descr = ''MFL/AFD'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Tool'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''MFL/AFD'' AND Descr = ''MFL/AFD'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Tool'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'MFL' AND Descr = 'MFL'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'MFL' AND Descr = 'MFL' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''MFL'' AND Descr = ''MFL'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''MFL'' AND Descr = ''MFL'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Metal In Proximity' AND Descr = 'Metal In Proximity'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Metal In Proximity' AND Descr = 'Metal In Proximity' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Metal In Proximity'' AND Descr = ''Metal In Proximity'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Metal In Proximity'' AND Descr = ''Metal In Proximity'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Mechanical w/Metal Loss' AND Descr = 'Mechanical w/Metal Loss'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Mechanical w/Metal Loss' AND Descr = 'Mechanical w/Metal Loss' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Mechanical w/Metal Loss'' AND Descr = ''Mechanical w/Metal Loss'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Mechanical w/Metal Loss'' AND Descr = ''Mechanical w/Metal Loss'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Mechanical' AND Descr = 'Mechanical'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Mechanical' AND Descr = 'Mechanical' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Mechanical'' AND Descr = ''Mechanical'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Mechanical'' AND Descr = ''Mechanical'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Marker/Valve' AND Descr = 'Marker/Valve'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Marker/Valve' AND Descr = 'Marker/Valve' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Marker/Valve'' AND Descr = ''Marker/Valve'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Facility Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Marker/Valve'' AND Descr = ''Marker/Valve'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Facility Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Marker Coil' AND Descr = 'Marker Coil'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Marker Coil' AND Descr = 'Marker Coil' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Marker Coil'' AND Descr = ''Marker Coil'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Facility Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Marker Coil'' AND Descr = ''Marker Coil'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Facility Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Marker' AND Descr = 'Marker'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Marker' AND Descr = 'Marker' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Marker'' AND Descr = ''Marker'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Facility Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Marker'' AND Descr = ''Marker'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Facility Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Manufacturing' AND Descr = 'Manufacturing'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Manufacturing' AND Descr = 'Manufacturing' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Manufacturing'' AND Descr = ''Manufacturing'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Manufacturing'' AND Descr = ''Manufacturing'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'MAIN LINE VALVE|AGMSHARP' AND Descr = 'MAIN LINE VALVE|AGMSHARP'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'MAIN LINE VALVE|AGMSHARP' AND Descr = 'MAIN LINE VALVE|AGMSHARP' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''MAIN LINE VALVE|AGMSHARP'' AND Descr = ''MAIN LINE VALVE|AGMSHARP'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''MAIN LINE VALVE|AGMSHARP'' AND Descr = ''MAIN LINE VALVE|AGMSHARP'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Main Line G4' AND Descr = 'Main Line G4'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Main Line G4' AND Descr = 'Main Line G4' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Main Line G4'' AND Descr = ''Main Line G4'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Valve Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Main Line G4'' AND Descr = ''Main Line G4'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Valve Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Main Line G12' AND Descr = 'Main Line G12'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Main Line G12' AND Descr = 'Main Line G12' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Main Line G12'' AND Descr = ''Main Line G12'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Valve Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Main Line G12'' AND Descr = ''Main Line G12'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Valve Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Magpie Systems' AND Descr = 'Magpie Systems'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Magpie Systems' AND Descr = 'Magpie Systems' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Magpie Systems'' AND Descr = ''Magpie Systems'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Company'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Magpie Systems'' AND Descr = ''Magpie Systems'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Company'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Magpie' AND Descr = 'Magpie'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Magpie' AND Descr = 'Magpie' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Magpie'' AND Descr = ''Magpie'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Company'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Magpie'' AND Descr = ''Magpie'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Company'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Long Seam Weld Anomaly' AND Descr = 'Long Seam Weld Anomaly'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Long Seam Weld Anomaly' AND Descr = 'Long Seam Weld Anomaly' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Long Seam Weld Anomaly'' AND Descr = ''Long Seam Weld Anomaly'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Long Seam Weld Anomaly'' AND Descr = ''Long Seam Weld Anomaly'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Long Seam Indication' AND Descr = 'Long Seam Indication'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Long Seam Indication' AND Descr = 'Long Seam Indication' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Long Seam Indication'' AND Descr = ''Long Seam Indication'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Long Seam Indication'' AND Descr = ''Long Seam Indication'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Long Seam Anomaly' AND Descr = 'Long Seam Anomaly'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Long Seam Anomaly' AND Descr = 'Long Seam Anomaly' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Long Seam Anomaly'' AND Descr = ''Long Seam Anomaly'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Long Seam Anomaly'' AND Descr = ''Long Seam Anomaly'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Internal pitting corrosion' AND Descr = 'Internal pitting corrosion'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Internal pitting corrosion' AND Descr = 'Internal pitting corrosion' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Internal pitting corrosion'' AND Descr = ''Internal pitting corrosion'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Internal pitting corrosion'' AND Descr = ''Internal pitting corrosion'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Internal MFG' AND Descr = 'Internal MFG'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Internal MFG' AND Descr = 'Internal MFG' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Internal MFG'' AND Descr = ''Internal MFG'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Internal MFG'' AND Descr = ''Internal MFG'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Internal Metal Loss' AND Descr = 'Internal Metal Loss'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Internal Metal Loss' AND Descr = 'Internal Metal Loss' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Internal Metal Loss'' AND Descr = ''Internal Metal Loss'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Internal Metal Loss'' AND Descr = ''Internal Metal Loss'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Internal Metal Loss' AND Descr = 'Internal Metal Loss'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Internal Metal Loss' AND Descr = 'Internal Metal Loss' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Internal Metal Loss'' AND Descr = ''Internal Metal Loss'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Internal Metal Loss'' AND Descr = ''Internal Metal Loss'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Internal general corrosion' AND Descr = 'Internal general corrosion'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Internal general corrosion' AND Descr = 'Internal general corrosion' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Internal general corrosion'' AND Descr = ''Internal general corrosion'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Internal general corrosion'' AND Descr = ''Internal general corrosion'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'INDICATION' AND Descr = 'INDICATION'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'INDICATION' AND Descr = 'INDICATION' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''INDICATION'' AND Descr = ''INDICATION'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''INDICATION'' AND Descr = ''INDICATION'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Inactive' AND Descr = 'Inactive'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Call Box Interaction rule')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Inactive' AND Descr = 'Inactive' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Call Box Interaction rule')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Inactive'' AND Descr = ''Inactive'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Call Box Interaction rule'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Inactive'' AND Descr = ''Inactive'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Call Box Interaction rule'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ID Anomaly / Ovality' AND Descr = 'ID Anomaly / Ovality'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ID Anomaly / Ovality' AND Descr = 'ID Anomaly / Ovality' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ID Anomaly / Ovality'' AND Descr = ''ID Anomaly / Ovality'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ID Anomaly / Ovality'' AND Descr = ''ID Anomaly / Ovality'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Hirsch' AND Descr = 'Steelman'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Hirsch' AND Descr = 'Steelman' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Hirsch'' AND Descr = ''Steelman'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Area Name'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Hirsch'' AND Descr = ''Steelman'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Area Name'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Heavy Weld' AND Descr = 'Heavy Weld'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Heavy Weld' AND Descr = 'Heavy Weld' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Heavy Weld'' AND Descr = ''Heavy Weld'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Heavy Weld'' AND Descr = ''Heavy Weld'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Hastings' AND Descr = 'Steelman'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Hastings' AND Descr = 'Steelman' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Hastings'' AND Descr = ''Steelman'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Area Name'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Hastings'' AND Descr = ''Steelman'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Area Name'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Grade B' AND Descr = 'Grade B'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Grade B' AND Descr = 'Grade B' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Grade B'' AND Descr = ''Grade B'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Grade B'' AND Descr = ''Grade B'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Gr.B' AND Descr = 'Gr.B'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Gr.B' AND Descr = 'Gr.B' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Gr.B'' AND Descr = ''Gr.B'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Gr.B'' AND Descr = ''Gr.B'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'GR.A' AND Descr = 'GR.A'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'GR.A' AND Descr = 'GR.A' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''GR.A'' AND Descr = ''GR.A'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''GR.A'' AND Descr = ''GR.A'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Girth Weld' AND Descr = 'Girth Weld'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Girth Weld' AND Descr = 'Girth Weld' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Girth Weld'' AND Descr = ''Girth Weld'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Facility Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Girth Weld'' AND Descr = ''Girth Weld'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Facility Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'GEOPIG' AND Descr = 'GEOPIG'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'GEOPIG' AND Descr = 'GEOPIG' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''GEOPIG'' AND Descr = ''GEOPIG'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''GEOPIG'' AND Descr = ''GEOPIG'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Geometry' AND Descr = 'Geometry'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Geometry' AND Descr = 'Geometry' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Geometry'' AND Descr = ''Geometry'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Geometry'' AND Descr = ''Geometry'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'General Corrosion' AND Descr = 'General Corrosion'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'General Corrosion' AND Descr = 'General Corrosion' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''General Corrosion'' AND Descr = ''General Corrosion'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''General Corrosion'' AND Descr = ''General Corrosion'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'GE Pipeline Solutions' AND Descr = 'GE Pipeline Solutions'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'GE Pipeline Solutions' AND Descr = 'GE Pipeline Solutions' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''GE Pipeline Solutions'' AND Descr = ''GE Pipeline Solutions'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Company'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''GE Pipeline Solutions'' AND Descr = ''GE Pipeline Solutions'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Company'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'GE / PII' AND Descr = 'GE / PII'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'GE / PII' AND Descr = 'GE / PII' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''GE / PII'' AND Descr = ''GE / PII'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Company'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''GE / PII'' AND Descr = ''GE / PII'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Company'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Fusion Bond Epoxy' AND Descr = 'Fusion Bond Epoxy'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Fusion Bond Epoxy' AND Descr = 'Fusion Bond Epoxy' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Fusion Bond Epoxy'' AND Descr = ''Fusion Bond Epoxy'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Fusion Bond Epoxy'' AND Descr = ''Fusion Bond Epoxy'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Frobisher' AND Descr = 'Steelman'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Frobisher' AND Descr = 'Steelman' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Frobisher'' AND Descr = ''Steelman'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Area Name'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Frobisher'' AND Descr = ''Steelman'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Area Name'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Field Verify' AND Descr = 'Field Verify'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Field Verify' AND Descr = 'Field Verify' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Field Verify'' AND Descr = ''Field Verify'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Field Verify'' AND Descr = ''Field Verify'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Extra Metal Weld defect' AND Descr = 'Extra Metal Weld defect'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Extra Metal Weld defect' AND Descr = 'Extra Metal Weld defect' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Extra Metal Weld defect'' AND Descr = ''Extra Metal Weld defect'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Extra Metal Weld defect'' AND Descr = ''Extra Metal Weld defect'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Extra Metal / Unknown' AND Descr = 'Extra Metal / Unknown'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Extra Metal / Unknown' AND Descr = 'Extra Metal / Unknown' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Extra Metal / Unknown'' AND Descr = ''Extra Metal / Unknown'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Extra Metal / Unknown'' AND Descr = ''Extra Metal / Unknown'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Extra metal / Possible extra metal' AND Descr = 'Extra metal / Possible extra metal'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Extra metal / Possible extra metal' AND Descr = 'Extra metal / Possible extra metal' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Extra metal / Possible extra metal'' AND Descr = ''Extra metal / Possible extra metal'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Extra metal / Possible extra metal'' AND Descr = ''Extra metal / Possible extra metal'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'External pitting corrosion' AND Descr = 'External pitting corrosion'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'External pitting corrosion' AND Descr = 'External pitting corrosion' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''External pitting corrosion'' AND Descr = ''External pitting corrosion'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''External pitting corrosion'' AND Descr = ''External pitting corrosion'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'External MFG' AND Descr = 'External MFG'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'External MFG' AND Descr = 'External MFG' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''External MFG'' AND Descr = ''External MFG'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''External MFG'' AND Descr = ''External MFG'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'External Metal Loss' AND Descr = 'External Metal Loss'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'External Metal Loss' AND Descr = 'External Metal Loss' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''External Metal Loss'' AND Descr = ''External Metal Loss'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''External Metal Loss'' AND Descr = ''External Metal Loss'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'External Metal Loss' AND Descr = 'External Metal Loss'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'External Metal Loss' AND Descr = 'External Metal Loss' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''External Metal Loss'' AND Descr = ''External Metal Loss'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''External Metal Loss'' AND Descr = ''External Metal Loss'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ERW Cracking' AND Descr = 'ERW Cracking'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ERW Cracking' AND Descr = 'ERW Cracking' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ERW Cracking'' AND Descr = ''ERW Cracking'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ERW Cracking'' AND Descr = ''ERW Cracking'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Enduro Pipeline Services' AND Descr = 'Enduro Pipeline Services'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Enduro Pipeline Services' AND Descr = 'Enduro Pipeline Services' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Enduro Pipeline Services'' AND Descr = ''Enduro Pipeline Services'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Company'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Enduro Pipeline Services'' AND Descr = ''Enduro Pipeline Services'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Company'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ENDURO' AND Descr = 'ENDURO'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ENDURO' AND Descr = 'ENDURO' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ENDURO'' AND Descr = ''ENDURO'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Company'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ENDURO'' AND Descr = ''ENDURO'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Company'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'End Casing' AND Descr = 'End Casing'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'End Casing' AND Descr = 'End Casing' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''End Casing'' AND Descr = ''End Casing'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Facility Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''End Casing'' AND Descr = ''End Casing'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Facility Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'EMAT' AND Descr = 'EMAT'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'EMAT' AND Descr = 'EMAT' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''EMAT'' AND Descr = ''EMAT'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''EMAT'' AND Descr = ''EMAT'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Douglaston' AND Descr = 'Steelman'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Douglaston' AND Descr = 'Steelman' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Douglaston'' AND Descr = ''Steelman'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Area Name'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Douglaston'' AND Descr = ''Steelman'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Area Name'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Double-Wrap Polyken' AND Descr = 'Double-Wrap Polyken'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Double-Wrap Polyken' AND Descr = 'Double-Wrap Polyken' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Double-Wrap Polyken'' AND Descr = ''Double-Wrap Polyken'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Double-Wrap Polyken'' AND Descr = ''Double-Wrap Polyken'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Depth > 3mm' AND Descr = 'Depth > 3mm'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Depth > 3mm' AND Descr = 'Depth > 3mm' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Depth > 3mm'' AND Descr = ''Depth > 3mm'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Depth > 3mm'' AND Descr = ''Depth > 3mm'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Depth < 1mm' AND Descr = 'Depth < 1mm'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Depth < 1mm' AND Descr = 'Depth < 1mm' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Depth < 1mm'' AND Descr = ''Depth < 1mm'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Depth < 1mm'' AND Descr = ''Depth < 1mm'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Dent' AND Descr = 'Dent'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Dent' AND Descr = 'Dent' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Dent'' AND Descr = ''Dent'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Dent'' AND Descr = ''Dent'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Deformation With Metal Loss' AND Descr = 'Deformation With Metal Loss'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Deformation With Metal Loss' AND Descr = 'Deformation With Metal Loss' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Deformation With Metal Loss'' AND Descr = ''Deformation With Metal Loss'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Deformation With Metal Loss'' AND Descr = ''Deformation With Metal Loss'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Deformation with Groove' AND Descr = 'Deformation with Groove'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Non Corrosion Defect')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Deformation with Groove' AND Descr = 'Deformation with Groove' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Non Corrosion Defect')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Deformation with Groove'' AND Descr = ''Deformation with Groove'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Non Corrosion Defect'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Deformation with Groove'' AND Descr = ''Deformation with Groove'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Non Corrosion Defect'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Deformation with Gouge' AND Descr = 'Deformation with Gouge'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Non Corrosion Defect')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Deformation with Gouge' AND Descr = 'Deformation with Gouge' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Non Corrosion Defect')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Deformation with Gouge'' AND Descr = ''Deformation with Gouge'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Non Corrosion Defect'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Deformation with Gouge'' AND Descr = ''Deformation with Gouge'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Non Corrosion Defect'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Deformation with Crack' AND Descr = 'Deformation with Crack'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Non Corrosion Defect')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Deformation with Crack' AND Descr = 'Deformation with Crack' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Non Corrosion Defect')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Deformation with Crack'' AND Descr = ''Deformation with Crack'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Non Corrosion Defect'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Deformation with Crack'' AND Descr = ''Deformation with Crack'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Non Corrosion Defect'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Deformation with Arc Burn' AND Descr = 'Deformation with Arc Burn'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Non Corrosion Defect')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Deformation with Arc Burn' AND Descr = 'Deformation with Arc Burn' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Non Corrosion Defect')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Deformation with Arc Burn'' AND Descr = ''Deformation with Arc Burn'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Non Corrosion Defect'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Deformation with Arc Burn'' AND Descr = ''Deformation with Arc Burn'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Non Corrosion Defect'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Deformation - Weld' AND Descr = 'Deformation - Weld2'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Deformation - Weld' AND Descr = 'Deformation - Weld2' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Deformation - Weld'' AND Descr = ''Deformation - Weld2'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Deformation - Weld'' AND Descr = ''Deformation - Weld2'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Deformation - Weld' AND Descr = 'Deformation - Weld'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Deformation - Weld' AND Descr = 'Deformation - Weld' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Deformation - Weld'' AND Descr = ''Deformation - Weld'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Deformation - Weld'' AND Descr = ''Deformation - Weld'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Deformation - Stress Riser' AND Descr = 'Deformation - Stress Riser2'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Deformation - Stress Riser' AND Descr = 'Deformation - Stress Riser2' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Deformation - Stress Riser'' AND Descr = ''Deformation - Stress Riser2'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Deformation - Stress Riser'' AND Descr = ''Deformation - Stress Riser2'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Deformation - Other' AND Descr = 'Deformation - Other2'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Deformation - Other' AND Descr = 'Deformation - Other2' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Deformation - Other'' AND Descr = ''Deformation - Other2'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Deformation - Other'' AND Descr = ''Deformation - Other2'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Deformation - Other' AND Descr = 'Deformation - Other'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Deformation - Other' AND Descr = 'Deformation - Other' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Deformation - Other'' AND Descr = ''Deformation - Other'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Deformation - Other'' AND Descr = ''Deformation - Other'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Deformation - Flat' AND Descr = 'Deformation - Flat'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Deformation - Flat' AND Descr = 'Deformation - Flat' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Deformation - Flat'' AND Descr = ''Deformation - Flat'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Deformation - Flat'' AND Descr = ''Deformation - Flat'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Data not available' AND Descr = 'Data not available'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Data not available' AND Descr = 'Data not available' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Data not available'' AND Descr = ''Data not available'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Data not available'' AND Descr = ''Data not available'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'CSA Z662' AND Descr = 'CSA Z662'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'CSA Z662' AND Descr = 'CSA Z662' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''CSA Z662'' AND Descr = ''CSA Z662'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''CSA Z662'' AND Descr = ''CSA Z662'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'CSA Z245.5' AND Descr = 'CSA Z245.5'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'CSA Z245.5' AND Descr = 'CSA Z245.5' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''CSA Z245.5'' AND Descr = ''CSA Z245.5'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''CSA Z245.5'' AND Descr = ''CSA Z245.5'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'CSA Z245.5' AND Descr = 'CSA Z245.5'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'CSA Z245.5' AND Descr = 'CSA Z245.5' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''CSA Z245.5'' AND Descr = ''CSA Z245.5'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''CSA Z245.5'' AND Descr = ''CSA Z245.5'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'CSA Z245.3' AND Descr = 'CSA Z245.3'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'CSA Z245.3' AND Descr = 'CSA Z245.3' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''CSA Z245.3'' AND Descr = ''CSA Z245.3'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''CSA Z245.3'' AND Descr = ''CSA Z245.3'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'CSA Z-245.3' AND Descr = 'CSA Z-245.3'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'CSA Z-245.3' AND Descr = 'CSA Z-245.3' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''CSA Z-245.3'' AND Descr = ''CSA Z-245.3'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''CSA Z-245.3'' AND Descr = ''CSA Z-245.3'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'CSA Z245.2' AND Descr = 'CSA Z245.2'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'CSA Z245.2' AND Descr = 'CSA Z245.2' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''CSA Z245.2'' AND Descr = ''CSA Z245.2'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''CSA Z245.2'' AND Descr = ''CSA Z245.2'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'CSA Z245.1' AND Descr = 'CSA Z245.1'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'CSA Z245.1' AND Descr = 'CSA Z245.1' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''CSA Z245.1'' AND Descr = ''CSA Z245.1'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''CSA Z245.1'' AND Descr = ''CSA Z245.1'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'CSA Z-245.1' AND Descr = 'CSA Z-245.1'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'CSA Z-245.1' AND Descr = 'CSA Z-245.1' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''CSA Z-245.1'' AND Descr = ''CSA Z-245.1'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''CSA Z-245.1'' AND Descr = ''CSA Z-245.1'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Crack-Seam' AND Descr = 'Crack-Seam'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Crack-Seam' AND Descr = 'Crack-Seam' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Crack-Seam'' AND Descr = ''Crack-Seam'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Crack-Seam'' AND Descr = ''Crack-Seam'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Crack-Colony' AND Descr = 'Crack-Colony'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Crack-Colony' AND Descr = 'Crack-Colony' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Crack-Colony'' AND Descr = ''Crack-Colony'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Crack-Colony'' AND Descr = ''Crack-Colony'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Crack' AND Descr = 'Crack'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Crack' AND Descr = 'Crack' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Crack'' AND Descr = ''Crack'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Crack'' AND Descr = ''Crack'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'CPWA' AND Descr = 'CPWA'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'CPWA' AND Descr = 'CPWA' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''CPWA'' AND Descr = ''CPWA'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Facility Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''CPWA'' AND Descr = ''CPWA'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Facility Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'CPIG' AND Descr = 'CPIG'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'CPIG' AND Descr = 'CPIG' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''CPIG'' AND Descr = ''CPIG'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Company'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''CPIG'' AND Descr = ''CPIG'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Company'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Construction Feature' AND Descr = 'Construction Feature'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Construction Feature' AND Descr = 'Construction Feature' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Construction Feature'' AND Descr = ''Construction Feature'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Construction Feature'' AND Descr = ''Construction Feature'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Completed-100%' AND Descr = 'Completed-100%'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Status')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Completed-100%' AND Descr = 'Completed-100%' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Status')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Completed-100%'' AND Descr = ''Completed-100%'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Status'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Completed-100%'' AND Descr = ''Completed-100%'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Status'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Completed' AND Descr = 'Completed'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Status')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Completed' AND Descr = 'Completed' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Status')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Completed'' AND Descr = ''Completed'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Status'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Completed'' AND Descr = ''Completed'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Status'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Complete but no data' AND Descr = 'Complete but no data'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Status')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Complete but no data' AND Descr = 'Complete but no data' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Status')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Complete but no data'' AND Descr = ''Complete but no data'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Status'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Complete but no data'' AND Descr = ''Complete but no data'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Status'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'CLOSE METAL OBJECT W/ML' AND Descr = 'CLOSE METAL OBJECT W/ML'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'CLOSE METAL OBJECT W/ML' AND Descr = 'CLOSE METAL OBJECT W/ML' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''CLOSE METAL OBJECT W/ML'' AND Descr = ''CLOSE METAL OBJECT W/ML'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''CLOSE METAL OBJECT W/ML'' AND Descr = ''CLOSE METAL OBJECT W/ML'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'CLOSE METAL OBJECT' AND Descr = 'CLOSE METAL OBJECT'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'CLOSE METAL OBJECT' AND Descr = 'CLOSE METAL OBJECT' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''CLOSE METAL OBJECT'' AND Descr = ''CLOSE METAL OBJECT'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''CLOSE METAL OBJECT'' AND Descr = ''CLOSE METAL OBJECT'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'CL 600' AND Descr = 'CL 600'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'CL 600' AND Descr = 'CL 600' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''CL 600'' AND Descr = ''CL 600'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Valve Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''CL 600'' AND Descr = ''CL 600'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Valve Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Check G4' AND Descr = 'Check G4'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Check G4' AND Descr = 'Check G4' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Check G4'' AND Descr = ''Check G4'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Valve Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Check G4'' AND Descr = ''Check G4'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Valve Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Check' AND Descr = 'Check'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Check' AND Descr = 'Check' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Check'' AND Descr = ''Check'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Valve Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Check'' AND Descr = ''Check'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Valve Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'CFD' AND Descr = 'Circumferential Flaw Detection Crack Tool'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'CFD' AND Descr = 'Circumferential Flaw Detection Crack Tool' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''CFD'' AND Descr = ''Circumferential Flaw Detection Crack Tool'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''CFD'' AND Descr = ''Circumferential Flaw Detection Crack Tool'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'CFD' AND Descr = 'Circumferential Flaw Detection Crack Tool'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'CFD' AND Descr = 'Circumferential Flaw Detection Crack Tool' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''CFD'' AND Descr = ''Circumferential Flaw Detection Crack Tool'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Tool'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''CFD'' AND Descr = ''Circumferential Flaw Detection Crack Tool'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Tool'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'CFD /CDP' AND Descr = 'CFD /CDP'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'CFD /CDP' AND Descr = 'CFD /CDP' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''CFD /CDP'' AND Descr = ''CFD /CDP'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''CFD /CDP'' AND Descr = ''CFD /CDP'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'CFD /CDP' AND Descr = 'CFD /CDP'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'CFD /CDP' AND Descr = 'CFD /CDP' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''CFD /CDP'' AND Descr = ''CFD /CDP'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''CFD /CDP'' AND Descr = ''CFD /CDP'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'CDP/AFD/Caliper' AND Descr = 'CDP/AFD/Caliper'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'CDP/AFD/Caliper' AND Descr = 'CDP/AFD/Caliper' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''CDP/AFD/Caliper'' AND Descr = ''CDP/AFD/Caliper'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''CDP/AFD/Caliper'' AND Descr = ''CDP/AFD/Caliper'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'CDP/AFD' AND Descr = 'CDP/AFD'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'CDP/AFD' AND Descr = 'CDP/AFD' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''CDP/AFD'' AND Descr = ''CDP/AFD'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''CDP/AFD'' AND Descr = ''CDP/AFD'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'CAT2 M45C' AND Descr = 'CAT2 M45C'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'CAT2 M45C' AND Descr = 'CAT2 M45C' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''CAT2 M45C'' AND Descr = ''CAT2 M45C'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''CAT2 M45C'' AND Descr = ''CAT2 M45C'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Casing middle' AND Descr = 'Casing middle'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Casing middle' AND Descr = 'Casing middle' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Casing middle'' AND Descr = ''Casing middle'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Facility Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Casing middle'' AND Descr = ''Casing middle'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Facility Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Caliper/Bend' AND Descr = 'Caliper/Bend'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Caliper/Bend' AND Descr = 'Caliper/Bend' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Caliper/Bend'' AND Descr = ''Caliper/Bend'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Caliper/Bend'' AND Descr = ''Caliper/Bend'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Caliper Tool' AND Descr = 'Caliper Tool'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Caliper Tool' AND Descr = 'Caliper Tool' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Caliper Tool'' AND Descr = ''Caliper Tool'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Caliper Tool'' AND Descr = ''Caliper Tool'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Caliper Tool' AND Descr = 'Caliper Tool'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Caliper Tool' AND Descr = 'Caliper Tool' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Caliper Tool'' AND Descr = ''Caliper Tool'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Caliper Tool'' AND Descr = ''Caliper Tool'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Caliper Inline Inspection' AND Descr = 'Caliper Inline Inspection'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Caliper Inline Inspection' AND Descr = 'Caliper Inline Inspection' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Caliper Inline Inspection'' AND Descr = ''Caliper Inline Inspection'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Caliper Inline Inspection'' AND Descr = ''Caliper Inline Inspection'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Buckle' AND Descr = 'Buckle'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Non Corrosion Defect')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Buckle' AND Descr = 'Buckle' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Non Corrosion Defect')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Buckle'' AND Descr = ''Buckle'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Non Corrosion Defect'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Buckle'' AND Descr = ''Buckle'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Non Corrosion Defect'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Browning' AND Descr = 'Steelman'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Browning' AND Descr = 'Steelman' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Browning'' AND Descr = ''Steelman'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Area Name'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Browning'' AND Descr = ''Steelman'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Area Name'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Block G4' AND Descr = 'Block G4'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Block G4' AND Descr = 'Block G4' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Block G4'' AND Descr = ''Block G4'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Valve Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Block G4'' AND Descr = ''Block G4'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Valve Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Block G12' AND Descr = 'Block G12'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Block G12' AND Descr = 'Block G12' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Block G12'' AND Descr = ''Block G12'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Valve Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Block G12'' AND Descr = ''Block G12'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Valve Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Block' AND Descr = 'Block'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Block' AND Descr = 'Block' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Block'' AND Descr = ''Block'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Valve Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Block'' AND Descr = ''Block'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Valve Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'BJ Pipeline Inspection Services' AND Descr = 'BJ Pipeline Inspection Services'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Operator Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'BJ Pipeline Inspection Services' AND Descr = 'BJ Pipeline Inspection Services' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Valve Operator Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''BJ Pipeline Inspection Services'' AND Descr = ''BJ Pipeline Inspection Services'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Valve Operator Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''BJ Pipeline Inspection Services'' AND Descr = ''BJ Pipeline Inspection Services'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Valve Operator Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'BJ Pipeline Inspection Services' AND Descr = 'BJ Pipeline Inspection Services'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'BJ Pipeline Inspection Services' AND Descr = 'BJ Pipeline Inspection Services' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''BJ Pipeline Inspection Services'' AND Descr = ''BJ Pipeline Inspection Services'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Company'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''BJ Pipeline Inspection Services'' AND Descr = ''BJ Pipeline Inspection Services'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Company'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'BJ - Services (Nowsco)' AND Descr = 'BJ - Services (Nowsco)'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'BJ - Services (Nowsco)' AND Descr = 'BJ - Services (Nowsco)' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''BJ - Services (Nowsco)'' AND Descr = ''BJ - Services (Nowsco)'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Company'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''BJ - Services (Nowsco)'' AND Descr = ''BJ - Services (Nowsco)'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Company'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'BG' AND Descr = 'BG'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'BG' AND Descr = 'BG' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''BG'' AND Descr = ''BG'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Company'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''BG'' AND Descr = ''BG'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Company'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Begin Casing' AND Descr = 'Begin Casing'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Begin Casing' AND Descr = 'Begin Casing' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Begin Casing'' AND Descr = ''Begin Casing'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Facility Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Begin Casing'' AND Descr = ''Begin Casing'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Facility Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Baker Hughes CPIG ILI' AND Descr = 'Baker Hughes CPIG ILI'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Baker Hughes CPIG ILI' AND Descr = 'Baker Hughes CPIG ILI' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Baker Hughes CPIG ILI'' AND Descr = ''Baker Hughes CPIG ILI'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Company'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Baker Hughes CPIG ILI'' AND Descr = ''Baker Hughes CPIG ILI'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Company'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Baker Hughes CPIG' AND Descr = 'Baker Hughes CPIG'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Baker Hughes CPIG' AND Descr = 'Baker Hughes CPIG' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Company')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Baker Hughes CPIG'' AND Descr = ''Baker Hughes CPIG'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Company'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Baker Hughes CPIG'' AND Descr = ''Baker Hughes CPIG'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Company'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'B31G' AND Descr = 'B31G'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Call Box Interaction rule')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'B31G' AND Descr = 'B31G' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Call Box Interaction rule')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''B31G'' AND Descr = ''B31G'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Call Box Interaction rule'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''B31G'' AND Descr = ''B31G'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Call Box Interaction rule'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'B31G' AND Descr = 'B31G'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Failure Pressure Algorithm')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'B31G' AND Descr = 'B31G' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Failure Pressure Algorithm')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''B31G'' AND Descr = ''B31G'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Failure Pressure Algorithm'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''B31G'' AND Descr = ''B31G'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Failure Pressure Algorithm'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ASTM-SB11' AND Descr = 'ASTM-SB11'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ASTM-SB11' AND Descr = 'ASTM-SB11' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ASTM-SB11'' AND Descr = ''ASTM-SB11'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ASTM-SB11'' AND Descr = ''ASTM-SB11'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ASTM-D513' AND Descr = 'ASTM-D513 Plastic Pipe for Gas Piping Only'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ASTM-D513' AND Descr = 'ASTM-D513 Plastic Pipe for Gas Piping Only' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ASTM-D513'' AND Descr = ''ASTM-D513 Plastic Pipe for Gas Piping Only'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ASTM-D513'' AND Descr = ''ASTM-D513 Plastic Pipe for Gas Piping Only'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ASTM-D2517' AND Descr = 'ASTM-D2517 Plastic Pipe for Gas Piping Only'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ASTM-D2517' AND Descr = 'ASTM-D2517 Plastic Pipe for Gas Piping Only' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ASTM-D2517'' AND Descr = ''ASTM-D2517 Plastic Pipe for Gas Piping Only'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ASTM-D2517'' AND Descr = ''ASTM-D2517 Plastic Pipe for Gas Piping Only'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ASTMD2513' AND Descr = 'ASTMD2513'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ASTMD2513' AND Descr = 'ASTMD2513' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ASTMD2513'' AND Descr = ''ASTMD2513'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ASTMD2513'' AND Descr = ''ASTMD2513'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ASTMD-2241' AND Descr = 'ASTMD-2241 Plastic Pipe for Water Piping Only'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ASTMD-2241' AND Descr = 'ASTMD-2241 Plastic Pipe for Water Piping Only' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ASTMD-2241'' AND Descr = ''ASTMD-2241 Plastic Pipe for Water Piping Only'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ASTMD-2241'' AND Descr = ''ASTMD-2241 Plastic Pipe for Water Piping Only'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ASTM-B111' AND Descr = 'ASTM-B111'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ASTM-B111' AND Descr = 'ASTM-B111' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ASTM-B111'' AND Descr = ''ASTM-B111'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ASTM-B111'' AND Descr = ''ASTM-B111'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ASTM-A860' AND Descr = 'ASTM-A860'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ASTM-A860' AND Descr = 'ASTM-A860' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ASTM-A860'' AND Descr = ''ASTM-A860'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ASTM-A860'' AND Descr = ''ASTM-A860'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ASTM-A72' AND Descr = 'ASTM-A72'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ASTM-A72' AND Descr = 'ASTM-A72' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ASTM-A72'' AND Descr = ''ASTM-A72'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ASTM-A72'' AND Descr = ''ASTM-A72'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ASTM-A53-GR.B' AND Descr = 'ASTM-A53-GR.B'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ASTM-A53-GR.B' AND Descr = 'ASTM-A53-GR.B' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ASTM-A53-GR.B'' AND Descr = ''ASTM-A53-GR.B'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ASTM-A53-GR.B'' AND Descr = ''ASTM-A53-GR.B'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ASTM-A53-GR.A' AND Descr = 'ASTM-A53-GR.A'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ASTM-A53-GR.A' AND Descr = 'ASTM-A53-GR.A' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ASTM-A53-GR.A'' AND Descr = ''ASTM-A53-GR.A'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ASTM-A53-GR.A'' AND Descr = ''ASTM-A53-GR.A'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ASTM-A539' AND Descr = 'ASTM-A539'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ASTM-A539' AND Descr = 'ASTM-A539' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ASTM-A539'' AND Descr = ''ASTM-A539'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ASTM-A539'' AND Descr = ''ASTM-A539'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ASTM-A53' AND Descr = 'ASTM-A53'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ASTM-A53' AND Descr = 'ASTM-A53' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ASTM-A53'' AND Descr = ''ASTM-A53'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ASTM-A53'' AND Descr = ''ASTM-A53'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ASTM-A381' AND Descr = 'ASTM-A381'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ASTM-A381' AND Descr = 'ASTM-A381' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ASTM-A381'' AND Descr = ''ASTM-A381'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ASTM-A381'' AND Descr = ''ASTM-A381'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ASTM-A337' AND Descr = 'ASTM-A337'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ASTM-A337' AND Descr = 'ASTM-A337' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ASTM-A337'' AND Descr = ''ASTM-A337'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ASTM-A337'' AND Descr = ''ASTM-A337'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ASTM-A333' AND Descr = 'ASTM-A333'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ASTM-A333' AND Descr = 'ASTM-A333' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ASTM-A333'' AND Descr = ''ASTM-A333'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ASTM-A333'' AND Descr = ''ASTM-A333'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ASTM-A214' AND Descr = 'ASTM-A214'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ASTM-A214' AND Descr = 'ASTM-A214' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ASTM-A214'' AND Descr = ''ASTM-A214'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ASTM-A214'' AND Descr = ''ASTM-A214'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ASTM-A211' AND Descr = 'ASTM-A211'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ASTM-A211' AND Descr = 'ASTM-A211' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ASTM-A211'' AND Descr = ''ASTM-A211'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ASTM-A211'' AND Descr = ''ASTM-A211'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ASTM-A155' AND Descr = 'ASTM-A155'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ASTM-A155' AND Descr = 'ASTM-A155' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ASTM-A155'' AND Descr = ''ASTM-A155'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ASTM-A155'' AND Descr = ''ASTM-A155'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ASTM-A139' AND Descr = 'ASTM-A139'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ASTM-A139' AND Descr = 'ASTM-A139' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ASTM-A139'' AND Descr = ''ASTM-A139'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ASTM-A139'' AND Descr = ''ASTM-A139'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ASTM-A135' AND Descr = 'ASTM-A135'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ASTM-A135' AND Descr = 'ASTM-A135' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ASTM-A135'' AND Descr = ''ASTM-A135'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ASTM-A135'' AND Descr = ''ASTM-A135'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ASTM-A134' AND Descr = 'ASTM-A134'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ASTM-A134' AND Descr = 'ASTM-A134' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ASTM-A134'' AND Descr = ''ASTM-A134'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ASTM-A134'' AND Descr = ''ASTM-A134'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ASTM-A106, GR. B' AND Descr = 'ASTM-A106, GR. B'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ASTM-A106, GR. B' AND Descr = 'ASTM-A106, GR. B' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ASTM-A106, GR. B'' AND Descr = ''ASTM-A106, GR. B'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ASTM-A106, GR. B'' AND Descr = ''ASTM-A106, GR. B'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ASTM-A106' AND Descr = 'ASTM-A106'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ASTM-A106' AND Descr = 'ASTM-A106' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ASTM-A106'' AND Descr = ''ASTM-A106'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ASTM-A106'' AND Descr = ''ASTM-A106'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ASTM A252' AND Descr = 'ASTM A252'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ASTM A252' AND Descr = 'ASTM A252' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ASTM A252'' AND Descr = ''ASTM A252'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ASTM A252'' AND Descr = ''ASTM A252'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'ASTM A120' AND Descr = 'ASTM A120'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'ASTM A120' AND Descr = 'ASTM A120' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''ASTM A120'' AND Descr = ''ASTM A120'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''ASTM A120'' AND Descr = ''ASTM A120'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Area Supervisor - Tim Dennis' AND Descr = 'Area Supervisor - Tim Dennis'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Area Supervisor - Tim Dennis' AND Descr = 'Area Supervisor - Tim Dennis' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Area Supervisor - Tim Dennis'' AND Descr = ''Area Supervisor - Tim Dennis'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Area Name'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Area Supervisor - Tim Dennis'' AND Descr = ''Area Supervisor - Tim Dennis'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Area Name'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Area Supervisor - Shane Anderson' AND Descr = 'Area Supervisor - Shane Anderson'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Area Supervisor - Shane Anderson' AND Descr = 'Area Supervisor - Shane Anderson' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Area Supervisor - Shane Anderson'' AND Descr = ''Area Supervisor - Shane Anderson'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Area Name'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Area Supervisor - Shane Anderson'' AND Descr = ''Area Supervisor - Shane Anderson'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Area Name'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Area Supervisor - Ron Pischke' AND Descr = 'Area Supervisor - Ron Pischke'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Area Supervisor - Ron Pischke' AND Descr = 'Area Supervisor - Ron Pischke' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Area Supervisor - Ron Pischke'' AND Descr = ''Area Supervisor - Ron Pischke'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Area Name'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Area Supervisor - Ron Pischke'' AND Descr = ''Area Supervisor - Ron Pischke'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Area Name'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Area Supervisor - Paul Burnay' AND Descr = 'Area Supervisor- Paul Burnay'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Area Supervisor - Paul Burnay' AND Descr = 'Area Supervisor- Paul Burnay' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Area Supervisor - Paul Burnay'' AND Descr = ''Area Supervisor- Paul Burnay'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Area Name'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Area Supervisor - Paul Burnay'' AND Descr = ''Area Supervisor- Paul Burnay'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Area Name'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Area Supervisor - Kerry Wilson' AND Descr = 'Area Supervisor - Kerry Wilson'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Area Supervisor - Kerry Wilson' AND Descr = 'Area Supervisor - Kerry Wilson' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Area Supervisor - Kerry Wilson'' AND Descr = ''Area Supervisor - Kerry Wilson'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Area Name'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Area Supervisor - Kerry Wilson'' AND Descr = ''Area Supervisor - Kerry Wilson'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Area Name'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Area Supervisor - Kelly Cottrell' AND Descr = 'Area Supervisor - Kelly Cottrell'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Area Supervisor - Kelly Cottrell' AND Descr = 'Area Supervisor - Kelly Cottrell' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Area Supervisor - Kelly Cottrell'' AND Descr = ''Area Supervisor - Kelly Cottrell'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Area Name'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Area Supervisor - Kelly Cottrell'' AND Descr = ''Area Supervisor - Kelly Cottrell'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Area Name'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Area Supervisor - Jay Eagleson' AND Descr = 'Area Supervisor - Jay Eagleson'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Area Supervisor - Jay Eagleson' AND Descr = 'Area Supervisor - Jay Eagleson' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Area Supervisor - Jay Eagleson'' AND Descr = ''Area Supervisor - Jay Eagleson'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Area Name'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Area Supervisor - Jay Eagleson'' AND Descr = ''Area Supervisor - Jay Eagleson'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Area Name'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Area Supervisor - Jack Lytle' AND Descr = 'Area Supervisor - Jack Lytle'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Area Supervisor - Jack Lytle' AND Descr = 'Area Supervisor - Jack Lytle' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Area Supervisor - Jack Lytle'' AND Descr = ''Area Supervisor - Jack Lytle'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Area Name'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Area Supervisor - Jack Lytle'' AND Descr = ''Area Supervisor - Jack Lytle'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Area Name'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Area Supervisor - Andy Risbridger' AND Descr = 'Area Supervisor - Andy Risbridger'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Area Supervisor - Andy Risbridger' AND Descr = 'Area Supervisor - Andy Risbridger' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Area Supervisor - Andy Risbridger'' AND Descr = ''Area Supervisor - Andy Risbridger'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Area Name'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Area Supervisor - Andy Risbridger'' AND Descr = ''Area Supervisor - Andy Risbridger'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Area Name'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Area Supervisor - Allan Krupka' AND Descr = 'Area Supervisor - Allan Krupka'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Area Supervisor - Allan Krupka' AND Descr = 'Area Supervisor - Allan Krupka' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Area Supervisor - Allan Krupka'' AND Descr = ''Area Supervisor - Allan Krupka'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Area Name'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Area Supervisor - Allan Krupka'' AND Descr = ''Area Supervisor - Allan Krupka'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Area Name'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Arc Burn' AND Descr = 'Arc Burn'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Non Corrosion Defect')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Arc Burn' AND Descr = 'Arc Burn' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Non Corrosion Defect')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Arc Burn'' AND Descr = ''Arc Burn'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Non Corrosion Defect'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Arc Burn'' AND Descr = ''Arc Burn'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Non Corrosion Defect'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'API-5XL-42' AND Descr = 'API-5XL-42'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'API-5XL-42' AND Descr = 'API-5XL-42' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''API-5XL-42'' AND Descr = ''API-5XL-42'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''API-5XL-42'' AND Descr = ''API-5XL-42'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'API-5LY-60' AND Descr = 'API-5LY-60'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'API-5LY-60' AND Descr = 'API-5LY-60' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''API-5LY-60'' AND Descr = ''API-5LY-60'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''API-5LY-60'' AND Descr = ''API-5LY-60'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'API-5LY-52' AND Descr = 'API-5LY-52'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'API-5LY-52' AND Descr = 'API-5LY-52' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''API-5LY-52'' AND Descr = ''API-5LY-52'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''API-5LY-52'' AND Descr = ''API-5LY-52'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'API-5LX-70' AND Descr = 'API-5LX-70'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'API-5LX-70' AND Descr = 'API-5LX-70' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''API-5LX-70'' AND Descr = ''API-5LX-70'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''API-5LX-70'' AND Descr = ''API-5LX-70'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'API-5LX-65' AND Descr = 'API-5LX-65'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'API-5LX-65' AND Descr = 'API-5LX-65' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''API-5LX-65'' AND Descr = ''API-5LX-65'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''API-5LX-65'' AND Descr = ''API-5LX-65'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'API-5LX-60V' AND Descr = 'API-5LX-60V'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'API-5LX-60V' AND Descr = 'API-5LX-60V' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''API-5LX-60V'' AND Descr = ''API-5LX-60V'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''API-5LX-60V'' AND Descr = ''API-5LX-60V'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'API-5LX-60' AND Descr = 'API-5LX-60'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'API-5LX-60' AND Descr = 'API-5LX-60' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''API-5LX-60'' AND Descr = ''API-5LX-60'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''API-5LX-60'' AND Descr = ''API-5LX-60'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'API-5LX-56' AND Descr = 'API-5LX-56'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'API-5LX-56' AND Descr = 'API-5LX-56' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''API-5LX-56'' AND Descr = ''API-5LX-56'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''API-5LX-56'' AND Descr = ''API-5LX-56'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'API-5LX-54' AND Descr = 'API-5LX-54'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'API-5LX-54' AND Descr = 'API-5LX-54' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''API-5LX-54'' AND Descr = ''API-5LX-54'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''API-5LX-54'' AND Descr = ''API-5LX-54'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'API-5LX-52' AND Descr = 'API-5LX-52'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'API-5LX-52' AND Descr = 'API-5LX-52' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''API-5LX-52'' AND Descr = ''API-5LX-52'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''API-5LX-52'' AND Descr = ''API-5LX-52'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'API-5LX-46' AND Descr = 'API-5LX-46'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'API-5LX-46' AND Descr = 'API-5LX-46' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''API-5LX-46'' AND Descr = ''API-5LX-46'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''API-5LX-46'' AND Descr = ''API-5LX-46'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'API-5LX-45' AND Descr = 'API-5LX-45'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'API-5LX-45' AND Descr = 'API-5LX-45' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''API-5LX-45'' AND Descr = ''API-5LX-45'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''API-5LX-45'' AND Descr = ''API-5LX-45'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'API-5LX-42' AND Descr = 'API-5LX-42'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'API-5LX-42' AND Descr = 'API-5LX-42' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''API-5LX-42'' AND Descr = ''API-5LX-42'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''API-5LX-42'' AND Descr = ''API-5LX-42'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'API-5LX-40' AND Descr = 'API-5LX-40'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'API-5LX-40' AND Descr = 'API-5LX-40' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''API-5LX-40'' AND Descr = ''API-5LX-40'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''API-5LX-40'' AND Descr = ''API-5LX-40'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'API-5LX-37' AND Descr = 'API-5LX-37'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'API-5LX-37' AND Descr = 'API-5LX-37' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''API-5LX-37'' AND Descr = ''API-5LX-37'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''API-5LX-37'' AND Descr = ''API-5LX-37'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'API-5LX-35' AND Descr = 'API-5LX-35'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'API-5LX-35' AND Descr = 'API-5LX-35' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''API-5LX-35'' AND Descr = ''API-5LX-35'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''API-5LX-35'' AND Descr = ''API-5LX-35'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'API-5LX-30' AND Descr = 'API-5LX-30'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'API-5LX-30' AND Descr = 'API-5LX-30' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''API-5LX-30'' AND Descr = ''API-5LX-30'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''API-5LX-30'' AND Descr = ''API-5LX-30'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'API-5LX' AND Descr = 'API-5LX'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'API-5LX' AND Descr = 'API-5LX' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''API-5LX'' AND Descr = ''API-5LX'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''API-5LX'' AND Descr = ''API-5LX'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'API-5LS' AND Descr = 'API-5LS'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'API-5LS' AND Descr = 'API-5LS' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''API-5LS'' AND Descr = ''API-5LS'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''API-5LS'' AND Descr = ''API-5LS'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'API-5L-Gr.B' AND Descr = 'API-5L-Gr.B'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'API-5L-Gr.B' AND Descr = 'API-5L-Gr.B' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''API-5L-Gr.B'' AND Descr = ''API-5L-Gr.B'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''API-5L-Gr.B'' AND Descr = ''API-5L-Gr.B'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'API-5L-Gr.A' AND Descr = 'API-5L-Gr.A'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'API-5L-Gr.A' AND Descr = 'API-5L-Gr.A' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''API-5L-Gr.A'' AND Descr = ''API-5L-Gr.A'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''API-5L-Gr.A'' AND Descr = ''API-5L-Gr.A'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'API-5L' AND Descr = 'API-5L'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'API-5L' AND Descr = 'API-5L' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''API-5L'' AND Descr = ''API-5L'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''API-5L'' AND Descr = ''API-5L'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'API 5L GrB' AND Descr = 'API 5L GrB'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'API 5L GrB' AND Descr = 'API 5L GrB' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''API 5L GrB'' AND Descr = ''API 5L GrB'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''API 5L GrB'' AND Descr = ''API 5L GrB'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'API 5L' AND Descr = 'API 5L'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'API 5L' AND Descr = 'API 5L' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''API 5L'' AND Descr = ''API 5L'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''API 5L'' AND Descr = ''API 5L'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Anadarko' AND Descr = 'Anadarko'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'District / Division Name')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Anadarko' AND Descr = 'Anadarko' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'District / Division Name')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Anadarko'' AND Descr = ''Anadarko'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''District / Division Name'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Anadarko'' AND Descr = ''Anadarko'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''District / Division Name'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Anadarko' AND Descr = 'Anadarko'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Anadarko' AND Descr = 'Anadarko' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Area Name')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Anadarko'' AND Descr = ''Anadarko'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Area Name'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Anadarko'' AND Descr = ''Anadarko'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Area Name'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'AGM' AND Descr = 'AGM'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'AGM' AND Descr = 'AGM' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Facility Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''AGM'' AND Descr = ''AGM'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Facility Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''AGM'' AND Descr = ''AGM'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Facility Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'AFD/Geometry' AND Descr = 'AFD/Geometry'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'AFD/Geometry' AND Descr = 'AFD/Geometry' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''AFD/Geometry'' AND Descr = ''AFD/Geometry'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Tool'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''AFD/Geometry'' AND Descr = ''AFD/Geometry'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Tool'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'AFD/Caliper' AND Descr = 'AFD/Caliper'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'AFD/Caliper' AND Descr = 'AFD/Caliper' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''AFD/Caliper'' AND Descr = ''AFD/Caliper'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''AFD/Caliper'' AND Descr = ''AFD/Caliper'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'AFD' AND Descr = 'AFD'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'AFD' AND Descr = 'AFD' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''AFD'' AND Descr = ''AFD'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''AFD'' AND Descr = ''AFD'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'AFD' AND Descr = 'AFD'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'AFD' AND Descr = 'AFD' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''AFD'' AND Descr = ''AFD'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Tool'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''AFD'' AND Descr = ''AFD'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Tool'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Active' AND Descr = 'Active2'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Non Crsn Dfct Status')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Active' AND Descr = 'Active2' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Non Crsn Dfct Status')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Active'' AND Descr = ''Active2'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Non Crsn Dfct Status'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Active'' AND Descr = ''Active2'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Non Crsn Dfct Status'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = 'Active' AND Descr = 'Active'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Call Box Interaction rule')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = 'Active' AND Descr = 'Active' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Call Box Interaction rule')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''Active'' AND Descr = ''Active'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Call Box Interaction rule'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''Active'' AND Descr = ''Active'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Call Box Interaction rule'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '6T' AND Descr = '6T'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Call Box Interaction rule')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '6T' AND Descr = '6T' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Call Box Interaction rule')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''6T'' AND Descr = ''6T'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Call Box Interaction rule'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''6T'' AND Descr = ''6T'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Call Box Interaction rule'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '60' AND Descr = '> 60%'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '60' AND Descr = '> 60%' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''60'' AND Descr = ''> 60%'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''60'' AND Descr = ''> 60%'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '48000' AND Descr = '48000'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '48000' AND Descr = '48000' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''48000'' AND Descr = ''48000'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''48000'' AND Descr = ''48000'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '40-60' AND Descr = '40% - 60%'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '40-60' AND Descr = '40% - 60%' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''40-60'' AND Descr = ''40% - 60%'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''40-60'' AND Descr = ''40% - 60%'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '3T axial and 1 circ' AND Descr = '3T axial and 1 circ'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Call Box Interaction rule')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '3T axial and 1 circ' AND Descr = '3T axial and 1 circ' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Call Box Interaction rule')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''3T axial and 1 circ'' AND Descr = ''3T axial and 1 circ'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Call Box Interaction rule'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''3T axial and 1 circ'' AND Descr = ''3T axial and 1 circ'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Call Box Interaction rule'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '3T' AND Descr = '3T'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Call Box Interaction rule')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '3T' AND Descr = '3T' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Call Box Interaction rule')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''3T'' AND Descr = ''3T'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Call Box Interaction rule'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''3T'' AND Descr = ''3T'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Call Box Interaction rule'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '2SG' AND Descr = '2SG'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '2SG' AND Descr = '2SG' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''2SG'' AND Descr = ''2SG'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''2SG'' AND Descr = ''2SG'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '2mm <= Depth < 3mm' AND Descr = '2mm <= Depth < 3mm'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '2mm <= Depth < 3mm' AND Descr = '2mm <= Depth < 3mm' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''2mm <= Depth < 3mm'' AND Descr = ''2mm <= Depth < 3mm'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''2mm <= Depth < 3mm'' AND Descr = ''2mm <= Depth < 3mm'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '28200' AND Descr = '28200'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '28200' AND Descr = '28200' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''28200'' AND Descr = ''28200'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''28200'' AND Descr = ''28200'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '26917' AND Descr = 'NAD83 UTM Zone 17N'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '26917' AND Descr = 'NAD83 UTM Zone 17N' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''26917'' AND Descr = ''NAD83 UTM Zone 17N'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Coordinate System'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''26917'' AND Descr = ''NAD83 UTM Zone 17N'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Coordinate System'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '26914' AND Descr = 'NAD83 UTM Zone 14N'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '26914' AND Descr = 'NAD83 UTM Zone 14N' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''26914'' AND Descr = ''NAD83 UTM Zone 14N'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Coordinate System'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''26914'' AND Descr = ''NAD83 UTM Zone 14N'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Coordinate System'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '26913' AND Descr = 'NAD83 UTM Zone 13N'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '26913' AND Descr = 'NAD83 UTM Zone 13N' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''26913'' AND Descr = ''NAD83 UTM Zone 13N'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Coordinate System'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''26913'' AND Descr = ''NAD83 UTM Zone 13N'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Coordinate System'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '26913' AND Descr = 'NAD 83 UTM Zone 13N'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '26913' AND Descr = 'NAD 83 UTM Zone 13N' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''26913'' AND Descr = ''NAD 83 UTM Zone 13N'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Coordinate System'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''26913'' AND Descr = ''NAD 83 UTM Zone 13N'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Coordinate System'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '26912' AND Descr = 'NAD 83 UTM Zone 12N'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '26912' AND Descr = 'NAD 83 UTM Zone 12N' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''26912'' AND Descr = ''NAD 83 UTM Zone 12N'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Coordinate System'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''26912'' AND Descr = ''NAD 83 UTM Zone 12N'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Coordinate System'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '26911' AND Descr = 'NAD83 UTM Zone 11N'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '26911' AND Descr = 'NAD83 UTM Zone 11N' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''26911'' AND Descr = ''NAD83 UTM Zone 11N'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Coordinate System'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''26911'' AND Descr = ''NAD83 UTM Zone 11N'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Coordinate System'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '26911' AND Descr = 'NAD 83 UTM Zone 11N'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '26911' AND Descr = 'NAD 83 UTM Zone 11N' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''26911'' AND Descr = ''NAD 83 UTM Zone 11N'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Coordinate System'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''26911'' AND Descr = ''NAD 83 UTM Zone 11N'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Coordinate System'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '25' AND Descr = '25'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Crack Anomaly Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '25' AND Descr = '25' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Crack Anomaly Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''25'' AND Descr = ''25'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Crack Anomaly Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''25'' AND Descr = ''25'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Crack Anomaly Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '25' AND Descr = '25'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Crack Anomaly Type')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '25' AND Descr = '25' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Crack Anomaly Type')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''25'' AND Descr = ''25'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Crack Anomaly Type'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''25'' AND Descr = ''25'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Crack Anomaly Type'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '20-40' AND Descr = '20% - 40%'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '20-40' AND Descr = '20% - 40%' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''20-40'' AND Descr = ''20% - 40%'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''20-40'' AND Descr = ''20% - 40%'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '20' AND Descr = '< 20%'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '20' AND Descr = '< 20%' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''20'' AND Descr = ''< 20%'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''20'' AND Descr = ''< 20%'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '1mm <= Depth < 2mm' AND Descr = '1mm <= Depth < 2mm'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '1mm <= Depth < 2mm' AND Descr = '1mm <= Depth < 2mm' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'DELETED')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''1mm <= Depth < 2mm'' AND Descr = ''1mm <= Depth < 2mm'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''DELETED'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''1mm <= Depth < 2mm'' AND Descr = ''1mm <= Depth < 2mm'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''DELETED'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '192.107-B2T' AND Descr = '192.107-B2T'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '192.107-B2T' AND Descr = '192.107-B2T' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''192.107-B2T'' AND Descr = ''192.107-B2T'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''192.107-B2T'' AND Descr = ''192.107-B2T'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '192.107-B2' AND Descr = '192.107-B2'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '192.107-B2' AND Descr = '192.107-B2' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Pipe Specification')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''192.107-B2'' AND Descr = ''192.107-B2'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Pipe Specification'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''192.107-B2'' AND Descr = ''192.107-B2'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Pipe Specification'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '102185' AND Descr = 'NAD 1983 10TM AEP Resource'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '102185' AND Descr = 'NAD 1983 10TM AEP Resource' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''102185'' AND Descr = ''NAD 1983 10TM AEP Resource'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Coordinate System'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''102185'' AND Descr = ''NAD 1983 10TM AEP Resource'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Coordinate System'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '102008' AND Descr = 'NAD83 North America Albers Equal Area Conic'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '102008' AND Descr = 'NAD83 North America Albers Equal Area Conic' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''102008'' AND Descr = ''NAD83 North America Albers Equal Area Conic'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Coordinate System'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''102008'' AND Descr = ''NAD83 North America Albers Equal Area Conic'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Coordinate System'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '102001' AND Descr = 'Canada_Albers_Equal_Area_Conic'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '102001' AND Descr = 'Canada_Albers_Equal_Area_Conic' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Coordinate System')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''102001'' AND Descr = ''Canada_Albers_Equal_Area_Conic'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Coordinate System'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''102001'' AND Descr = ''Canada_Albers_Equal_Area_Conic'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Coordinate System'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '0T' AND Descr = '0T'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Call Box Interaction rule')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '0T' AND Descr = '0T' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Call Box Interaction rule')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''0T'' AND Descr = ''0T'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''ILI Call Box Interaction rule'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''0T'' AND Descr = ''0T'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''ILI Call Box Interaction rule'')'
END
IF (SELECT COUNT(*) FROM ListDomain WHERE Code = '0.85 DL ' AND Descr = 'MODIFIED B31G (0.85 DL)'
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Failure Pressure Algorithm')) <= 1
BEGIN
	UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = '0.85 DL ' AND Descr = 'MODIFIED B31G (0.85 DL)' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'Failure Pressure Algorithm')
END
ELSE
BEGIN
	INSERT INTO ##ManualRun 
	SELECT
			 'SELECT * FROM ListDomain WHERE Code = ''0.85 DL '' AND Descr = ''MODIFIED B31G (0.85 DL)'' AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr =  ''Failure Pressure Algorithm'')'
	,'UPDATE ListDomain SET DomainCatalogId = -1 
	WHERE Code = ''0.85 DL '' AND Descr = ''MODIFIED B31G (0.85 DL)'' 
			AND DomainCatalogId = (SELECT Id FROM DomainCatalog WHERE DomainDescr = ''Failure Pressure Algorithm'')'
END

SELECT * FROM ##ManualRun