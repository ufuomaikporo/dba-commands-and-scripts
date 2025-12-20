USE DRAS_IRASv6_ENG_STAGE

GRANT CREATE TABLE ON SCHEMA::dbo TO [test]
REVOKE CREATE TABLE FROM [test]

EXECUTE (' USE DRAS_IRASv6_ENG_STAGE
SELECT * INTO ListDomainConflicts FROM DRASSQL2019.DRASInternal..ListDomainTableinfo
WHERE ServerName = ''DRASSQL2017''
AND DBName = ''DRAS_IRASv6_ENG_STAGE''
AND flag = 1') AT DRASSQL2017

SELECT * INTO DRAS_IRASv6_ENG_STAGE.dbo.ListDomainConflicts
FROM OPENQUERY(DRASSQL2019, 'SELECT *  FROM DRASInternal..ListDomainTableinfo
WHERE ServerName = ''DRASSQL2017''
AND DBName = ''DRAS_IRASv6_ENG_STAGE''
AND flag = 1')

SELECT TableName, ColumnName, FlaggedDomainDescr, FlaggedDomainCatalogId  
FROM ListDomainConflicts WHERE tablename = 'InlineInspectionCrsnCallBox'

DECLARE @Servername nvarchar(100) = @@SERVERNAME
DECLARE @DBName nvarchar(100) =  DB_NAME()
DECLARE @TableName nvarchar(100) = 'InlineInspectionCrsnCallBox'
DECLARE @ColumnName nvarchar(100)= 'ILICBFailPressAlgthmDomainId'
declare @sql nvarchar(max)
execute ('select * from listdomain where id in (select '+@Columnname+' from '+@Tablename+')')
execute ('select * from DomainCatalogColXRef where tablename = ''' + @TableName + '''
and ColumnName = '''+@Columnname+'''')


