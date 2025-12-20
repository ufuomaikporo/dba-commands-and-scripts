-- This script is for creating the functions and views for DataExhange mapping 

IF object_id('fn_GetDEAllMappingsInfo') IS NOT NULL
BEGIN
	DROP FUNCTION fn_GetDEAllMappingsInfo
END
GO

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

IF object_id('fn_GetDEColumnMapping') IS NOT NULL
BEGIN
	DROP FUNCTION fn_GetDEColumnMapping
END
GO


CREATE FUNCTION [dbo].[fn_GetDEColumnMapping]()
RETURNS @columnMapping TABLE
(
	ProjectName varchar(100),
	VariableName varchar(100),
	VariableDisplayName varchar(100),
	Unit varchar(30),
	SourceFieldName varchar(100),
	IrasTableName varchar(100),
	IrasColumnName varchar(100),
	IsListDomainColumn varchar(10)
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
				INSERT INTO @columnMapping (ProjectName, VariableName,VariableDisplayName,Unit,SourceFieldName,IrasTableName,IrasColumnName, IsListDomainColumn)
				SELECT @projectName, Json_Value(@jsonValue, '$.VariableCategoryObjects[' + cast(@i AS varchar(10)) + '].Mappings[' + cast(@j AS varchar(10)) + '].VariableName'), 
				Json_Value(@jsonValue, '$.VariableCategoryObjects[' + cast(@i AS varchar(10)) + '].Mappings[' + cast(@j AS varchar(10)) + '].VariableDisplayName'), 
				Json_Value(@jsonValue, '$.VariableCategoryObjects[' + cast(@i AS varchar(10)) + '].Mappings[' + cast(@j AS varchar(10)) + '].Unit'), 
				Json_Value(@jsonValue, '$.VariableCategoryObjects[' + cast(@i AS varchar(10)) + '].Mappings[' + cast(@j AS varchar(10)) + '].FieldName'), 
				Json_Value(@jsonValue, '$.VariableCategoryObjects[' + cast(@i AS varchar(10)) + '].Mappings[' + cast(@j AS varchar(10)) + '].TableName'), 
				Json_Value(@jsonValue, '$.VariableCategoryObjects[' + cast(@i AS varchar(10)) + '].Mappings[' + cast(@j AS varchar(10)) + '].ColumnName'),
				Json_Value(@jsonValue, '$.VariableCategoryObjects[' + cast(@i AS varchar(10)) + '].Mappings[' + cast(@j AS varchar(10)) + '].IsListDomainColumn')

				SET @j = @j + 1
			END

			SET @i = @i + 1
		END

		SET @k = @k + 1
	END

	RETURN
END
GO

IF object_id('fn_GetDELookupColumnMapping') IS NOT NULL
BEGIN
	DROP FUNCTION fn_GetDELookupColumnMapping
END
GO

CREATE FUNCTION [dbo].[fn_GetDELookupColumnMapping]()
RETURNS @lookupColumnMapping TABLE
(	
	ProjectName varchar(100),
	IrasTableName varchar(100),
	IrasColumnName varchar(100),
	SqlStatement varchar(max)
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
	DECLARE @isListDomainColumn varchar(10)

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
				SET @isListDomainColumn = Json_Value(@jsonValue, '$.VariableCategoryObjects[' + cast(@i AS varchar(10)) + '].Mappings[' + cast(@j AS varchar(10)) + '].IsListDomainColumn')

				IF @isListDomainColumn = 'true'
				BEGIN
					INSERT INTO @lookupColumnMapping (ProjectName, IrasTableName, IrasColumnName,SqlStatement)
					SELECT @projectName, Json_Value(@jsonValue, '$.VariableCategoryObjects[' + cast(@i AS varchar(10)) + '].Mappings[' + cast(@j AS varchar(10)) + '].TableName'), 
							Json_Value(@jsonValue, '$.VariableCategoryObjects[' + cast(@i AS varchar(10)) + '].Mappings[' + cast(@j AS varchar(10)) + '].ColumnName'),
							Json_Value(@jsonValue, '$.VariableCategoryObjects[' + cast(@i AS varchar(10)) + '].Mappings[' + cast(@j AS varchar(10)) + '].LookupTableObject.CustomQuery')
				END

				SET @j = @j + 1
			END

			SET @i = @i + 1
		END

		SET @k = @k + 1
	END

	RETURN
END
GO

IF object_id('fn_GetDETableMapping') IS NOT NULL
BEGIN
	DROP FUNCTION fn_GetDETableMapping
END
GO

CREATE FUNCTION [dbo].[fn_GetDETableMapping]()
RETURNS @tableMapping TABLE
	(
		ProjectName varchar(100),
		TableName varchar(100),
		DataSource varchar(100),
		SqlStatement varchar(max)
	)
AS
BEGIN
	-- This is for getting all pull queries for all tables and getting all column mappings as well.
	-- This will only work with the SQL2017 and up. 

	DECLARE @jsonValue nvarchar(max)
	DECLARE @cnt int
	DECLARE @i int
	DECLARE @k int
	DECLARE @projectCnt int
	DECLARE @projectName varchar(100)

	SET @k = 1
	SET @projectCnt = (SELECT COUNT(*) FROM DEProjectTemplate)

	WHILE @k <= @projectCnt
	BEGIN
		SET @i = 0
	
		SELECT @projectName = Name, @jsonValue = cast(dt.MetaData AS varchar(max)) 
		FROM (SELECT Row_Number() OVER(ORDER BY Id) AS RowId, * FROM dbo.DEProjectTemplate) dt
		WHERE RowId = @k

		set @cnt = (SELECT COUNT(*) FROM OPENJSON(@jsonValue,'$.VariableCategoryObjects'))

		WHILE @i < @cnt
		BEGIN
			INSERT INTO @tableMapping (ProjectName, TableName, DataSource, SqlStatement)
			SELECT @projectName, Json_Value(@jsonValue, '$.VariableCategoryObjects[' + cast(@i AS varchar(10)) + '].TableDisplayName'), 
			Json_Value(@jsonValue, '$.VariableCategoryObjects[' + cast(@i AS varchar(10)) + '].DataSourceObject.Name'), 
			Json_Value(@jsonValue, '$.VariableCategoryObjects[' + cast(@i AS varchar(10)) + '].Sql')

			SET @i = @i + 1
		END

		SET @k = @k + 1
	END

	RETURN
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE table_name = 'DataExchangeTableMapping' AND Table_Type = 'View')
BEGIN
	DROP VIEW [dbo].[DataExchangeTableMapping]
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE table_name = 'DataExchangeProjects' AND Table_Type = 'View')
BEGIN
	DROP VIEW [dbo].[DataExchangeProjects]
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE table_name = 'DataExchangeLookupColumnMapping' AND Table_Type = 'View')
BEGIN
	DROP VIEW [dbo].[DataExchangeLookupColumnMapping]
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE table_name = 'DataExchangeColumnMapping' AND Table_Type = 'View')
BEGIN
	DROP VIEW [dbo].[DataExchangeColumnMapping]
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.Tables WHERE table_name = 'DataExchangeAllMappingsInfo' AND Table_Type = 'View')
BEGIN
	DROP VIEW [dbo].[DataExchangeAllMappingsInfo]
END
GO

CREATE VIEW [dbo].[DataExchangeAllMappingsInfo]
AS
	SELECT * FROM dbo.fn_GetDEAllMappingsInfo()
GO

CREATE VIEW [dbo].[DataExchangeColumnMapping]
AS
	SELECT * FROM dbo.fn_GetDEColumnMapping()
GO

CREATE VIEW [dbo].[DataExchangeLookupColumnMapping]
AS
	SELECT * FROM dbo.fn_GetDELookupColumnMapping()
GO

CREATE VIEW [dbo].[DataExchangeProjects]
AS
	SELECT dt.Id, dt.Name AS ProjectName FROM dbo.DEProjectTemplate dt

GO

CREATE VIEW [dbo].[DataExchangeTableMapping]
AS
	SELECT * FROM dbo.fn_GetDETableMapping()
GO

