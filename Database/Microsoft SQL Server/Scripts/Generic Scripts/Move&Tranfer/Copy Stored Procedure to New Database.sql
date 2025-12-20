DECLARE @ObjectName VARCHAR(200)
DECLARE @SQL NVARCHAR(MAX)
DECLARE @SQL2 NVARCHAR (MAX)
DECLARE @definition VARCHAR(MAX)
DECLARE @StrLength INT
DECLARE @Counter INT
DECLARE @SchemaName VARCHAR(200)
DECLARE @PostInsertMaxId INT
DECLARE @PreInsertMaxId INT
DECLARE @SourceDB VARCHAR(200)

SET @SourceDB = 'PAA_IRASv6_STAGE'


IF OBJECT_ID('Tmp_DefinitionTable', 'U') IS NOT NULL
BEGIN
	DROP TABLE Tmp_DefinitionTable
END

CREATE TABLE Tmp_DefinitionTable (Id INT IDENTITY, ObjectName VARCHAR(200), definition NVARCHAR(MAX))

SET @SQL = 'DECLARE CreateObject_cur CURSOR FOR
SELECT s.name SchemaName, p.name ProcedureName 
FROM ' + QUOTENAME(@SourceDB) + '.sys.procedures p
JOIN ' + QUOTENAME(@SourceDB) + '.sys.schemas s ON p.schema_id = s.schema_id'

EXECUTE (@SQL)

OPEN CreateObject_cur
FETCH NEXT FROM CreateObject_cur INTO @SchemaName, @ObjectName

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @PreInsertMaxId = COALESCE(MAX(Id), 0) + 1 FROM Tmp_DefinitionTable

	IF NOT EXISTS (SELECT * FROM Tmp_DefinitionTable WHERE ObjectName = @ObjectName)
	BEGIN
		SET @SQL = 'USE ' + QUOTENAME(@SourceDB)+ '
		INSERT INTO ' + DB_NAME() + '..Tmp_DefinitionTable (Definition)
		EXECUTE sp_helptext ''' + @SchemaName + '.' + @ObjectName + ''''

		EXECUTE (@SQL)
	END
	
	SELECT @PostInsertMaxId = MAX(Id) FROM Tmp_DefinitionTable;

	
	UPDATE Tmp_DefinitionTable
	SET ObjectName = @ObjectName 
	WHERE Id BETWEEN @PreInsertMaxId AND @PostInsertMaxId

	FETCH NEXT FROM CreateObject_cur INTO @SchemaName, @ObjectName
END

CLOSE CreateObject_cur
DEALLOCATE CreateObject_cur

SELECT * FROM Tmp_DefinitionTable