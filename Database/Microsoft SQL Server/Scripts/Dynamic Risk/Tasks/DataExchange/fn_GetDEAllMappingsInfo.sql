/*
	Function to get the DE mapping info

	Helps with finding faulty source database queries

-- Use the following query to convert the results into a query that can be executed in a PLSQL block to find the bad query.
	You will need to modify the WHERE clause

select DISTINCT 'SELECT COUNT(*) INTO CNT FROM ('+ MainSqlStatement +');' from tmp_GetDEAllMappingsInfo
where ProjectName like 'GUID%'
AND DataSource = 'UPDM' AND MainSqlStatement IS NOT NULL

*/


CREATE FUNCTION [dbo].[fn_GetDEAllMappingsInfo]()
RETURNS @allMappingsInfo TABLE
(
	ProjectName varchar(100),
	TableName varchar(100),
	VariableName varchar(100),
	VariableDisplayName varchar(100),
	Unit varchar(30),
	SourceFieldName varchar(100),
	IrasTableName varchar(100),
	IrasColumnName varchar(100),
	IsListDomainColumn varchar(10),
	DataSource varchar(100),
	MainSqlStatement varchar(max),
	LookupSqlStatement varchar(max)
)
AS
BEGIN
	-- This is for getting all pull queries for all tables and getting all column mappings as well.
	-- This will only work with the SQL2017 and up. 

	DECLARE @jsonValue nvarchar(max)
	DECLARE @cnt int
	DECLARE @i int
	DECLARE @j int
	DECLARE @k int
	DECLARE @colCnt int
	DECLARE @projectCnt int
	DECLARE @projectName varchar(100)

	SET @k = 1
	SET @i = 0

	SET @projectCnt = (SELECT COUNT(*) FROM DEProjectTemplate)

	WHILE @k <= @projectCnt
	BEGIN
		SELECT @projectName = Name, @jsonValue = cast(dt.MetaData AS varchar(max)) 
		FROM (SELECT Row_Number() OVER(ORDER BY Id) AS RowId, * FROM dbo.DEProjectTemplate) dt
		WHERE RowId = @k

		SET @i = 0
		set @cnt = (SELECT COUNT(*) FROM OPENJSON(@jsonValue,'$.VariableCategoryObjects'))

		WHILE @i < @cnt
		BEGIN
			set @colCnt = (SELECT COUNT(*) FROM OPENJSON(@jsonValue,'$.VariableCategoryObjects[' + cast(@i AS varchar(10)) + '].Mappings'))
			SET @j = 0

			WHILE @j < @colCnt
			BEGIN
				INSERT INTO @allMappingsInfo (ProjectName,TableName,VariableName,VariableDisplayName,Unit,SourceFieldName,IrasTableName,IrasColumnName,IsListDomainColumn,DataSource,MainSqlStatement,LookupSqlStatement)
				SELECT @projectName, 
				Json_Value(@jsonValue, '$.VariableCategoryObjects[' + cast(@i AS varchar(10)) + '].TableDisplayName'), 
				Json_Value(@jsonValue, '$.VariableCategoryObjects[' + cast(@i AS varchar(10)) + '].Mappings[' + cast(@j AS varchar(10)) + '].VariableName'), 
				Json_Value(@jsonValue, '$.VariableCategoryObjects[' + cast(@i AS varchar(10)) + '].Mappings[' + cast(@j AS varchar(10)) + '].VariableDisplayName'), 
				Json_Value(@jsonValue, '$.VariableCategoryObjects[' + cast(@i AS varchar(10)) + '].Mappings[' + cast(@j AS varchar(10)) + '].Unit'), 
				Json_Value(@jsonValue, '$.VariableCategoryObjects[' + cast(@i AS varchar(10)) + '].Mappings[' + cast(@j AS varchar(10)) + '].FieldName'), 
				Json_Value(@jsonValue, '$.VariableCategoryObjects[' + cast(@i AS varchar(10)) + '].Mappings[' + cast(@j AS varchar(10)) + '].TableName'), 
				Json_Value(@jsonValue, '$.VariableCategoryObjects[' + cast(@i AS varchar(10)) + '].Mappings[' + cast(@j AS varchar(10)) + '].ColumnName'),
				Json_Value(@jsonValue, '$.VariableCategoryObjects[' + cast(@i AS varchar(10)) + '].Mappings[' + cast(@j AS varchar(10)) + '].IsListDomainColumn'),
				Json_Value(@jsonValue, '$.VariableCategoryObjects[' + cast(@i AS varchar(10)) + '].DataSourceObject.Name'), 
				Json_Value(@jsonValue, '$.VariableCategoryObjects[' + cast(@i AS varchar(10)) + '].Sql'),
				Json_Value(@jsonValue, '$.VariableCategoryObjects[' + cast(@i AS varchar(10)) + '].Mappings[' + cast(@j AS varchar(10)) + '].LookupTableObject.CustomQuery')

				SET @j = @j + 1
			END

			SET @i = @i + 1
		END

		SET @k = @k + 1
	END

	RETURN
END
GO


