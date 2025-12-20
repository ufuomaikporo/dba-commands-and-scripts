DECLARE @Count INT
DECLARE @TableName NVARCHAR(100)
DECLARE @ColumnName NVARCHAR(100)
DECLARE @SQL NVARCHAR(MAX)

DECLARE Lcursor CURSOR FOR
SELECT ReferencedColumnName, ReferencedTableName
FROM TMC_IRASv6_CONFIG..TempListDomainTable
WHERE TableType = 'Real'

OPEN Lcursor
FETCH NEXT FROM Lcursor INTO @ColumnName, @TableName

SET @SQL = 'SELECT * FROM ListDomain WHERE Id IN ('

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @SQL += 'SELECT ' + @ColumnName + ' FROM ' + @TableName + '
	UNION
	'
	--EXECUTE (@SQL)

	FETCH NEXT FROM Lcursor INTO @ColumnName, @TableName
END
CLOSE Lcursor
DEALLOCATE Lcursor

SET @SQL += ')'

SELECT @SQL

RETURN
--DECLARE @TableName NVARCHAR(100)
--DECLARE @SQL NVARCHAR(MAX)

DECLARE TableCursor CURSOR FOR
SELECT DISTINCT ListDomainTableName
FROM TMC_IRASv6_CONFIG..TempListDomainTable
WHERE ListDomainTableName  IN ('CoatingTypeLineLD', 'StructureTypeLD')

OPEN TableCursor
FETCH NEXT FROM TableCursor INTO @TableName

WHILE @@FETCH_STATUS = 0
BEGIN

	SET @SQL = 'SELECT @Result = COUNT(*) FROM '+@TableName+' WHERE Code IN
	(
	SELECT Code FROM (
	select code, COUNT(Code) cnt from '+@TableName+'
	GROUP BY Code HAVING COUNT(Code) >1) tmp
	)
	'
	SELECT @sql
	EXECUTE sp_executesql @SQL, N'@Result INT OUT', @Count OUT

	IF @Count > 0
	BEGIN
		SELECT @TableName
	END
	FETCH NEXT FROM TableCursor INTO @TableName
END

CLOSE TableCursor
DEALLOCATE TableCursor

SELECT * FROM StructureTypeLD WHERE Code IN
	(
	SELECT Code FROM (
	select code, COUNT(Code) cnt from StructureTypeLD
	GROUP BY Code HAVING COUNT(Code) >1) tmp
	)
order by 2, 4

SELECT * FROM CoatingTypeLineLD WHERE Code IN
	(
	SELECT Code FROM (
	select code, COUNT(Code) cnt from CoatingTypeLineLD
	GROUP BY Code HAVING COUNT(Code) >1) tmp
	)
order by 2, 4