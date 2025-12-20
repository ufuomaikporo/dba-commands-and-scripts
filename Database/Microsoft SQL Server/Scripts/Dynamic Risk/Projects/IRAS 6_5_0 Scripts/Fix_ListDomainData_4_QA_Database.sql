/*
this script attempts to clean-up bad data in the Listdomain table, by trying to ensure that tables referencing 
the ListDomain table have entries with the same DomainCatalogId. It creates an 'N/A' code entry with an 
appropriate DomainCatalogId for tables that are currently using DomainCatalogId = 1 for that purpose.

**NOTE** This script is for testing purposes only
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
DECLARE @Id INT;

----------------------------------------- Table Definitions -----------------------------------------

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

IF OBJECT_ID('tempdb..##DMLCommands') IS NOT NULL
BEGIN
	DROP TABLE ##DMLCommands
END

IF OBJECT_ID('tempdb..##DMLCommands') IS NULL
BEGIN
	SET @SQL = 'CREATE TABLE ##DMLCommands (FKTableName VARCHAR(100), 
											FKColumnName VARCHAR(100),
											DomainCatalogId INT,
											Command VARCHAR(MAX))';
	EXECUTE(@SQL)
END

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
						DomainDescr NVARCHAR(100)
						);

	SET @SQL = '
	INSERT INTO ##NewDomainTableList --(FKConstraint, FKTableName, FKColumnName)
	SELECT OBJECT_NAME(constraint_object_id) AS fk_constraint,
		   OBJECT_NAME(parent_object_id) AS fk_table,
		   COL_NAME(parent_object_id, parent_column_id) AS fk_column,
		   NULL,
		   NULL,
		   NULL
	FROM sys.foreign_key_columns 
	WHERE OBJECT_NAME(referenced_object_id) = ''ListDomain''
	AND OBJECT_NAME(parent_object_id) NOT IN (''RememberedListDomainValues'', ''VirtualTableDataListDomain'', ''ActionItemPropDCXRef'', ''CategoryDataListDomainXRef'')
	UNION
	SELECT NULL,
		   NULL,
		   NULL,
		    CASE 
				WHEN LEN (REPLACE(REPLACE(REPLACE(REPLACE(DomainDescr, '' '', ''''), ''-'', ''''), ''.'', ''''), ''/'', '''')) > 24
					THEN ''LD_'' + SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DomainDescr, '' '', ''''), ''-'', ''''), ''.'', ''''), ''/'', ''''), ''('', ''''), '')'', ''''), ''>'', ''''), ''<'', ''''), ''%'', ''''), ''@'', ''''), ''='', ''''), ''&'', ''''), '','', ''''), 1, 28) 
				ELSE ''LD_'' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DomainDescr, '' '', ''''), ''-'', ''''), ''.'', ''''), ''/'', ''''), ''('', ''''), '')'', ''''), ''>'', ''''), ''<'', ''''), ''%'', ''''), ''@'', ''''), ''='', ''''), ''&'', ''''), '','', '''' )
			END AS new_table_name,
			Id,
			DomainDescr
	FROM DomainCatalog
	WHERE Id <> -1'

	EXECUTE (@SQL)

END

DECLARE LDTables_Cursor CURSOR FOR
SELECT FKTableName,
	   FKColumnName,
	   NewListDomainTable,
	   DomainCatalogId
FROM ##NewDomainTableList
--WHERE FKTableName IN ('Weight', 'Stg_ILIRange', 'Valve')

OPEN LDTables_Cursor
FETCH NEXT FROM LDTables_Cursor INTO @FKTableName, @FKColumnName, @NewTableName, @DomainCatalogId

WHILE @@FETCH_STATUS = 0
BEGIN
		-- Store all ListDomain table entries for the table and column in the current loop iteration into a temporary table
	SET @SQL = 'DELETE FROM ##ListDomainInfo

					INSERT INTO ##ListDomainInfo (Id, DomainCatalogId, Code, Descr)
					SELECT Id,
						   DomainCatalogId,
						   Code,
						   Descr
					FROM ListDomain
					WHERE Id IN (SELECT DISTINCT ' + @FKColumnName + ' FROM ' + @FKTableName+ ')'

	EXECUTE (@SQL)

	SET @DomainCatalogId = NULL
	SELECT @DomainCatalogId = DomainCatalogId FROM DomainCatalogColXRef
	WHERE TableName = @FKTableName
	AND ColumnName = @FKColumnName

	IF (SELECT COUNT(DISTINCT DomainCatalogId) FROM ##ListDomainInfo WHERE DomainCatalogId <> -1) >= 2
	BEGIN
		IF @DomainCatalogId IS NULL AND (SELECT COUNT(DISTINCT DomainCatalogId) FROM ##ListDomainInfo WHERE DomainCatalogId NOT IN (1, -1)) = 1
		BEGIN
			SELECT @DomainCatalogId = DomainCatalogId FROM ##ListDomainInfo
			WHERE DomainCatalogId NOT IN (-1, 1)
		END

		IF EXISTS (SELECT 1 FROM ##ListDomainInfo WHERE Code IN ('N/A','Not Applicable'))
		BEGIN

			DECLARE @NewDomainId INT = NULL
			DECLARE @OldDomainId INT = NULL
			SET @SQL = NULL

			SELECT @NewDomainId = Id FROM ListDomain WHERE Code IN ('N/A','Not Applicable')
								AND DomainCatalogId = @DomainCatalogId

			SELECT @OldDomainId = Id FROM ##ListDomainInfo WHERE Code IN ('N/A', 'Not Applicable', 'Not Available')
									AND DomainCatalogId <> @DomainCatalogId

			IF (@NewDomainId IS NOT NULL AND @OldDomainId IS NOT NULL)
			BEGIN
				SET @SQL = '
				BEGIN TRANSACTION
						UPDATE ' + @FKTableName + '
							SET ' + @FKColumnName + ' = ' + CAST(@NewDomainId AS NVARCHAR)+ '
							WHERE ' + @FKColumnName + ' = ' + CAST(@OldDomainId AS NVARCHAR) + '
				COMMIT TRANSACTION'
				
				EXECUTE(@SQL)

				INSERT INTO ##DMLCommands
				SELECT @FKTableName, @FKColumnname, @DomainCatalogId, @SQL

					--select @FKTableName, @FKColumnName, @DomainCatalogId, @NewDomainId, @OldDomainId
					--break
			END
			ELSE IF (@OldDomainId IS NOT NULL)
			BEGIN
				SET @SQL = 'IF NOT EXISTS (SELECT 1 FROM ListDomain WHERE DomainCatalogId = ' + CAST(@DomainCatalogId AS NVARCHAR) + ' AND Code = ''N/A'')
				BEGIN TRANSACTION
					INSERT INTO ListDomain (DomainCatalogId, Code, Descr)
					VALUES(' + CAST(@DomainCatalogId AS NVARCHAR) + ', ''N/A'', ''Not Applicable'')
				COMMIT TRANSACTION'

				EXECUTE(@SQL)

				SELECT @Id = Id FROM ListDomain WHERE Code = 'N/A' AND DomainCatalogId = @DomainCatalogId
				
				SET @SQL = 'BEGIN TRANSACTION
				UPDATE ' + @FKTableName + '
				SET ' + @FKColumnName + ' = ' + CAST(@Id AS NVARCHAR) + '
				WHERE ' + @FKColumnName + '= ' + CAST(@OldDomainId AS NVARCHAR) + '
				COMMIT TRANSACTION'
			
				EXECUTE(@SQL)
				
				INSERT INTO ##DMLCommands
				SELECT @FKTableName, @FKColumnname, @DomainCatalogId, @SQL


			END
			ELSE
			BEGIN
				INSERT INTO ##DMLCommands
				SELECT @FKTableName, @FKColumnname, @DomainCatalogId, @SQL			
			END
		END
		ELSE
		BEGIN
			INSERT INTO ##DMLCommands
			SELECT @FKTableName, @FKColumnname, @DomainCatalogId, @SQL	
		END
	END

	FETCH NEXT FROM LDTables_Cursor INTO @FKTableName, @FKColumnName, @NewTableName, @DomainCatalogId
END

CLOSE LDTables_Cursor
DEALLOCATE LDTables_Cursor

UPDATE Stg_ILI
SET ILITypeDomainId = 31
WHERE ILITypeDomainId = 26

UPDATE Stg_ILI
SET ILITypeDomainId = (SELECT Id FROM ListDomain WHERE Code = 'N/A' AND DomainCatalogId = 31)
WHERE ILITypeDomainId = 1

UPDATE Stg_ILIRange
SET ILIRToolDomainId = (SELECT Id FROM ListDomain WHERE DomainCatalogId = 31 and Code = 'N/A')
WHERE ILIRToolDomainId = 1

UPDATE Stg_ILIRange
SET ILIRToolDomainId = 31
WHERE ILIRToolDomainId = 26

UPDATE POECoatingProperty
SET CoatingLineDomainId = (SELECT Id FROM ListDomain WHERE DomainCatalogId = 14 AND Code = 'N/A')
WHERE CoatingLineDomainId = 1

DELETE FROM POECoatingProperty
WHERE CoatingLineDomainId IN (SELECT Id FROM ListDomain WHERE DomainCatalogId = 5)

UPDATE Pressure
SET PressureTypeDomainId = 701933
WHERE PressureTypeDomainId = 600873

UPDATE Pressure
SET PressureTypeDomainId = 701933
WHERE PressureTypeDomainId = 600768

UPDATE CoatingCondition
SET CoatingCondLineTypeLD = 600369
WHERE CoatingCondLineTypeLD = 701350

UPDATE InlineInspectionCrackAnomaly
SET ILICATypeDomainId = 700950
WHERE ILICATypeDomainId = 5515535

UPDATE InlineInspectionCrackAnomaly
SET ILICATypeDomainId = 700951
WHERE ILICATypeDomainId = 5515536

UPDATE InlineInspectionNonCrsnDfct
SET ILINCDGrading1DomainId = 26932
WHERE ILINCDGrading1DomainId = 600223

UPDATE MLVCorrection
SET DistrictDivisionDomainId = 600366
WHERE DistrictDivisionDomainId = 5515482

--UPDATE Stg_ILICrackAnomaly
--SET ILICATypeDomainId = 5515703
--WHERE ILICATypeDomainId = 600661



