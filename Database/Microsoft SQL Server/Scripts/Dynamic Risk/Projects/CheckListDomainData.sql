DECLARE @SQL NVARCHAR(MAX)
DECLARE @VirtualTable NVARCHAR(100) = 'OFUnstableSlope'
DECLARE @VirtualColumn NVARCHAR(100) = 'UnstableSY'

--OFBlastingRemediation	OFBlastingRemediation
--ICMaintenance	Maintenance
--ECDA	ECDACoatingCondition
--OFFloodingRemediation	OFFloodingRemediation
--OxygenC	OxygenC
--OFUnstableSlope	UnstableSY

SET @SQL = 'SELECT * FROM ListDomain 
WHERE Id IN (SELECT DataFieldValueDomainId FROM VirtualTableDataListDomain
			 WHERE VirtualTableId IN (SELECT Id FROM VirtualTable WHERE VirtualTableName = '''+ @VirtualTable+''')
			 AND VirtualColumnId IN (SELECT Id FROM VirtualColumn WHERE VirtualColumnName = '''+@VirtualColumn+''')
			 )'

EXECUTE (@SQL)

SET @SQL = 'SELECT * FROM DomainCatalogColXRef WHERE Tablename = '''+@VirtualTable+'''
AND Columnname = '''+@VirtualColumn+''''

EXECUTE (@SQL)