DECLARE @TableName NVARCHAR(100) = 'CalculationVariable'
DECLARE @StringAgg NVARCHAR(MAX) 
DECLARE @SourceServer NVARCHAR(100) =  'SQL2016TEST'
DECLARE @SourceDB NVARCHAR(100) = 'ETP_IRASV6_CONFIG_UPGRADE_TEST'
DECLARE @TargetServer NVARCHAR(100) = 'SQL2016'
DECLARE @TargetDB NVARCHAR(100)  = 'ETP_IRASV6_CONFIG'



SELECT @StringAgg = COALESCE(@StringAgg + ', ', '')  + name 
FROM sys.columns where OBJECT_NAME(object_id) = @TableName
ORDER BY column_id

DECLARE @SQL NVARCHAR(MAX)
SET @SQL ='
IF OBJECTPROPERTY(OBJECT_ID(''' + @TableName+ '''), ''TableHasIdentity'') = 1
BEGIN
	SET IDENTITY_INSERT ' + @TableName + ' ON
END

INSERT INTO ' + @TableName + ' ('+ @StringAgg+')
SELECT * FROM '+ @SourceServer+'.' + @SourceDB + '.dbo.' + @TableName + ' 
WHERE RevisionId NOT IN (SELECT RevisionId FROM '+ @TargetServer+'.'+ @TargetDB + '.dbo.' + @TableName + '
)'

select @sql

