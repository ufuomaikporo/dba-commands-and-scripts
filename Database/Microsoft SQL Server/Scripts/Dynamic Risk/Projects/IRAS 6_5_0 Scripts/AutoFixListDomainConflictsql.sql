--*************************************************************************************************
DECLARE @SQL NVARCHAR(max)						
DECLARE @Servername nvarchar(100) = @@SERVERNAME
DECLARE @DBName nvarchar(100) =  DB_NAME()
DECLARE @TableName nvarchar(100) = 'Stg_ILICrsnCallBox'
DECLARE @ColumnName nvarchar(100)= 'ILICBFailPressAlgthmDomainId'
DECLARE @DomainCatalogId INT = 27

-- Add a new entry to the listdomain table
DECLARE @Code NVARCHAR(MAX) = NULL
DECLARE @Descr NVARCHAR(MAX) = NULL
					
-- Change to New DomainCatalogId
DECLARE @NewDomainCatalogId INT = NULL
		      
-- Change the ListDomain Id to a different existing value 
DECLARE @OldValue INT = NULL
DECLARE @NewValue INT = NULL


/*
Structure	OccupancyCtgryDomainId	59, 89	HCA Type, Occupancy Category
InlineInspectionNonCrsnDfct	ILINCDGrading2DomainId	33, 175	ILI Feature Grading 2 - Criteria, ILINCDGrading2
Stg_ILI	ILITypeDomainId	26, 31	ILI Type, ILI Tool
InlineInspectionNonCrsnDfct	ILINCDGrading1DomainId	32, 174	ILI Feature Grading 1 - Response Time, ILINCDGrading1
Stg_ILINonCrsnDfct	ILINCDGrading2DomainId	33, 180	ILI Feature Grading 2 - Criteria, CFR Grading
Stg_ILIFeature	ILIFGrading2DomainId	33, 180	ILI Feature Grading 2 - Criteria, CFR Grading
POECompanyLookUp	ToolTypeDomainId	26, 31	ILI Type, ILI Tool
*/

---***********************************************************************************************

IF @Descr IS NULL
BEGIN
	SET @Descr = @Code
END

DROP TABLE IF EXISTS ##tempTable

SET @SQL = 'SELECT * INTO ##tempTable FROM ListDomain WHERE code IN (SELECT Code FROM listdomain
WHERE id IN (SELECT '+@Columnname+' FROM '+@Tablename+') 
AND DomainCatalogId <>' + CAST(@DomainCatalogId AS NVARCHAR) + ')
AND DomainCatalogId = ' + CAST(@DomainCatalogId AS NVARCHAR) 

EXECUTE (@SQL)


--- Uncomment the following lines to insert new listdomain if appropriate one not found. then comment lines below and rerun the script
IF NOT EXISTS (SELECT 1 FROM ListDomain where DomainCatalogId = @DomainCatalogId and Code = @Code and Descr = @Descr)
BEGIN
	SET @SQL = 'INSERT INTO ListDomain (DomainCatalogId, Code, Descr)
	VALUES (' + CAST(@DomainCatalogId AS NVARCHAR) + ',''' + @Code + ''', ''' + @Descr + ''')'

	PRINT @SQL

	EXECUTE (@SQL)
END

SET @SQL = '

DECLARE @CMD NVARCHAR(MAX)

IF EXISTS (SELECT * FROM ListDomain WHERE code IN (SELECT Code FROM listdomain
WHERE id IN (SELECT '+@Columnname+' FROM '+@Tablename+') 
AND DomainCatalogId <>' + CAST(@DomainCatalogId AS NVARCHAR) + ')
AND DomainCatalogId = ' + CAST(@DomainCatalogId AS NVARCHAR) + ')
BEGIN

	SET @CMD = ''UPDATE  ' + @TableName+' 
	SET '+@Columnname+' = c.Id
	FROM ' + @TableName+'  a
	JOIN (SELECT Id, code, DomainCatalogid FROM listdomain ld
	WHERE ld.id IN (SELECT '+@Columnname+' FROM '+@Tablename+') 
	AND DomainCatalogId <>' + CAST(@DomainCatalogId AS NVARCHAR) + ') b
	On b.Id = a.'+@Columnname+'
	JOIN ##tempTable c
	ON c.Code = b.Code''

	PRINT @CMD
	EXECUTE(@CMD)

END'

--PRINT @SQL
EXECUTE (@SQL)

--RETURN

IF @oldValue IS NOT NULL AND @NewValue IS NOT NULL
BEGIN
	SET @sql = 'UPDATE  ' + @TableName+' 
	SET '+@Columnname+' = ' + CAST(@NewValue AS NVARCHAR) +
	'WHERE '+@Columnname+' = ' +  CAST(@OldValue AS NVARCHAR)

	PRINT @SQL

	EXECUTE (@SQL)
END

SET @SQL = 'SELECT * FROM listdomain WHERE id IN (SELECT '+@Columnname+' FROM '+@Tablename+')
AND DomainCatalogId <> '+ CAST(@DomainCatalogId AS NVARCHAR)+''

EXECUTE (@SQL)

SET @SQL = 'select * from listdomain where  DomainCatalogId = ' + CAST(@DomainCatalogId AS NVARCHAR) + ' ORDER BY Code'

EXECUTE (@SQL)

IF (@NewDomainCatalogId IS NOT NULL)
BEGIN
	SET @SQL = 'UPDATE ListDomain
	SET DomainCatalogId = ' + CAST(@NewDomainCatalogId AS NVARCHAR) + '
	WHERE Id IN (SELECT ' +  @ColumnName + ' FROM ' + @TableName + ')'

	PRINT @SQL
	EXECUTE (@SQL)
END