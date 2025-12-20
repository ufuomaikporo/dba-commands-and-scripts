/*
RUN on CONFIG database
*/
--SELECT * FROM DataSourceTable where NAME like 'LD[_]%VT'
DECLARE @SQL NVARCHAR(MAX)
DECLARE @StageDatabaseName NVARCHAR(100) = 'IRQ_IRASv6_STAGE_June_1'

IF @StageDatabaseName = '' 
BEGIN
	THROW 51000, 'Missing @StageDatabaseName. Please enter the stage database before running this.', 1;  
END

-- Make sure all stage tables listed in config db exist in stage db (should return null)
SET @SQL = 'SELECT dt.name TableName, df.FieldName 
from DataSourceTable dt
LEFT JOIN DataSourceField df ON df.TableId = dt.Id
LEFT JOIN ' + @StageDatabaseName + '.INFORMATION_SCHEMA.columns tab 
ON tab.table_name = dt.name AND tab.column_name = df.FieldName
WHERE df.FieldName IS NULL'

EXECUTE (@SQL)

-- Missing DataRelation table entry (LD tables with no child tables)
SET @SQL = 'SELECT dr.ParentFieldId, dr.ChildFieldId, dfp.FieldName ParentCol, dfc.FieldName ChildCol, dtp.name parentTable,
tld.LDTableName, tld.TableName AS ChildTable, tld.ColumnName 
FROM DataRelation dr
JOIN DataSourceField dfp ON dfp.Id = dr.ParentFieldId
JOIN DataSourceField dfc ON dfc.Id = dr.ChildFieldId
JOIN DataSourceTable dtp ON dtp.Id = dfp.TableId
JOIN DataSourceTable dtc ON dtc.Id = dfc.TableId
RIGHT JOIN ' + @StageDatabaseName + '.dbo.TempListDomainTable tld 
ON tld.TableName = dtc.name AND tld.ColumnName = dfc.FieldName
WHERE dr.ParentFieldId IS NULL AND tld.TableName IS NOT NULL'

EXECUTE (@SQL)

-- Missing entries in DataSourceFieldMetaData table for parent LD tables
SET @SQL = 'select dt.name, df.FieldName, tld.LDTableName, tld.TableName, tld.ColumnName, dmd.FieldId, dmd.FieldAppRole
from DataSourceFieldMetaData dmd
JOIN DataSourceField df ON df.Id = dmd.FieldId
AND df.FieldName = ''Id''
JOIN DataSourceTable dt ON dt.Id = df.TableId
RIGHT JOIN ' + @StageDatabaseName + '.dbo.TempListDomainTable tld ON tld.LDTableName = dt.name
WHERE dmd.FieldAppRole is null AND tld.LDTableName IS NOT NULL'

EXECUTE (@SQL)

UPDATE versioninfo  SET DBVersion = 650104

-- Missing entries in DataSourceFieldMetaData table for child tables referencing LD tables
SET @SQL = 'select tld.TableType, tld.LDTableName, dt.Name TableName, df.Id AS FieldId, df.FieldName ColumnName, 
dmd.FieldId, dmd.FieldAppRole, 
		CASE WHEN tld.TableType = ''Virtual'' THEN 1024
				WHEN df.FieldName = ''Id'' THEN 8193
				END NewAppRole
from ' + @StageDatabaseName+ '.dbo.TempListDomainTable tld 
LEFT JOIN DataSourceTable dt ON tld.TableName = dt.name
LEFT JOIN DataSourceField df ON tld.ColumnName = df.FieldName
AND df.TableId = dt.Id
LEFT JOIN DataSourceFieldMetaData dmd ON df.Id = dmd.FieldId
WHERE  dmd.FieldAppRole is null AND tld.TableName IS NOT NULL order by FieldAppRole'

EXECUTE (@SQL)


-- missing entries in DataSourceTableDomainCatalog
SET @SQL = 'select DISTINCT t1.DomainCatalog, t3.DomainDescr, t3.LDTableName, Tablename, columnName, 
t3.DomainCatalogId, t2.DomainDescr 
from DataSourceTableDomainCatalog t1
RIGHT JOIN ' + @StageDatabaseName + '.dbo.TempListDomainTable t3  ON t3.LDTableName = t1.DataSourceTableId
RIGHT JOIN ' + @StageDatabaseName + '.dbo.DomainCatalog_bkp t2 ON t1.DomainCatalog = t2.DomainDescr
WHERE t3.DomainDescr IS NOT NULL AND t1.DomainCatalog IS NULL'

EXECUTE (@SQL)





