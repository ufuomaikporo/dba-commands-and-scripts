DECLARE @SQL NVARCHAR(MAX)
SET @SQL = 'USE IRQ_IRASV6_LINK
				SELECT t.name AS TableName, c.name ColumnName, df.definition, OBJECT_DEFINITION(df.object_id),
						''ALTER TABLE '' + t.name + ''
						ADD CONSTRAINT '' + df.name + '' DEFAULT '' --+ df.definition
						+ '' FOR '' + c.name AS Constraint_def		 
			FROM sys.default_constraints df
			JOIN sys.tables t ON t.object_id = df.parent_object_id
			JOIN sys.columns c ON c.object_id = df.parent_object_id
			AND c.column_id = df.parent_column_id'

EXECUTE(@SQL) AT [DRASSQL2017]