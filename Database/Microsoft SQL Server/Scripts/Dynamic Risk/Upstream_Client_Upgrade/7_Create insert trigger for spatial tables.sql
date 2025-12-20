-- create the insert trigger for spatial tables

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'TANK' And c.Column_Name = 'CreateDate')
BEGIN
	ALTER TABLE TANK ADD [CreateDate] [datetime] DEFAULT getdate() NOT NULL
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.Columns c Where c.Table_Name = 'TANK' And c.Column_Name = 'CreateByUserId')
BEGIN
	ALTER TABLE TANK ADD [CreateByUserId] [nvarchar](45) default suser_sname() NOT NULL
END
GO

DECLARE @table_name NVARCHAR(100);
DECLARE @cmd NVARCHAR(MAX);

DECLARE create_trigger_cur CURSOR FOR
SELECT Table_Name ,
'Create TRIGGER ti_' + Table_name + ' ON ' + Table_Name + ' AFTER INSERT AS
IF EXISTS(SELECT * FROM INSERTED)
BEGIN
	UPDATE ' + Table_Name + '
	SET Id = t.OBJECTID,
		LastModByUserId = SUSER_SNAME(), 
		LastModDate = GETDATE(),
		CreateByUserId = SUSER_SNAME(),
		CreateDate = GETDATE()
	FROM ' + Table_Name + ' AS t, INSERTED d
	WHERE t.OBJECTID = d.OBJECTID;
END;' AS Script

FROM INFORMATION_SCHEMA.Columns c 
Where c.Column_Name = 'shape' AND Table_Name NOT IN (
	SELECT Table_Name FROM (
	SELECT [so].[name] AS [trigger_name],
	USER_NAME([so].[uid]) AS [trigger_owner],
	USER_NAME([so2].[uid]) AS [table_schema],
	OBJECT_NAME([so].[parent_obj]) AS [table_name],
	OBJECTPROPERTY( [so].[id], 'ExecIsUpdateTrigger') AS [isupdate],
	OBJECTPROPERTY( [so].[id], 'ExecIsDeleteTrigger') AS [isdelete],
	OBJECTPROPERTY( [so].[id], 'ExecIsInsertTrigger') AS [isinsert],
	OBJECTPROPERTY( [so].[id], 'ExecIsAfterTrigger') AS [isafter],
	OBJECTPROPERTY( [so].[id], 'ExecIsInsteadOfTrigger') AS [isinsteadof],
	OBJECTPROPERTY([so].[id], 'ExecIsTriggerDisabled') AS [disabled] 
	FROM sysobjects AS [so]
	INNER JOIN sysobjects AS so2 ON so.parent_obj = so2.Id
	WHERE [so].[type] = 'TR') tmp
	where Table_Name IN (SELECT Table_Name FROM INFORMATION_SCHEMA.Columns c Where c.Column_Name = 'shape')
	AND trigger_name LIKE 'ti%'
	UNION(
	SELECT DISTINCT(table_name) FROM  INFORMATION_SCHEMA.TABLES
	EXCEPT
	SELECT DISTINCT(table_name) FROM INFORMATION_SCHEMA.COLUMNS 
	WHERE column_name IN ('LastModByUserId', 'LastModDate', 'CreateByUserId', 'CreateDate')
	)
)
AND table_name NOT IN ('GDB_ITEMS', 'STATIONSERIES2017', 'NODECONNECTIONFLOWDIRECTION')

OPEN create_trigger_cur
FETCH NEXT FROM create_trigger_cur INTO @table_name, @cmd

WHILE @@FETCH_STATUS = 0
BEGIN
	EXECUTE sp_executesql @cmd
	FETCH NEXT FROM create_trigger_cur INTO @table_name, @cmd
END

CLOSE create_trigger_cur
DEALLOCATE create_trigger_cur

