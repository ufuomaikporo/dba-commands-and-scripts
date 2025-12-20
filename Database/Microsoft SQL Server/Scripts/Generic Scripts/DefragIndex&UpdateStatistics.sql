DECLARE @table NVARCHAR(100)
DECLARE @index_name NVARCHAR(100)
DECLARE @sql NVARCHAR(MAX)
    
DECLARE index_cursor CURSOR FOR
SELECT 
--S.name as 'SchemaName',
T.name as 'TableName',
I.name as 'IndexName'
--I.type_desc AS 'IndexType',
--DDIPS.avg_fragmentation_in_percent AS FragmentationPercentage,
--DDIPS.avg_page_space_used_in_percent AS 'PageDensity',
--DDIPS.page_count,
--allow_page_locks,
--allow_row_locks
FROM sys.dm_db_index_physical_stats (DB_ID(), default, default, default, 'SAMPLED') AS DDIPS
INNER JOIN sys.tables T on T.object_id = DDIPS.object_id
INNER JOIN sys.schemas S on T.schema_id = S.schema_id
INNER JOIN sys.indexes I ON I.object_id = DDIPS.object_id
	AND DDIPS.index_id = I.index_id
WHERE DDIPS.database_id = DB_ID()
AND DDIPS.avg_fragmentation_in_percent > 10
    
OPEN index_cursor
FETCH NEXT FROM index_cursor INTO @table, @index_name
    
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        EXECUTE ('ALTER INDEX {0} ON {1} REBUILD WITH(ONLINE=OFF);')
        EXECUTE ('ALTER INDEX {0} ON {1} SET(ALLOW_PAGE_LOCKS=ON);')
        EXECUTE ('ALTER INDEX {0} ON {1} REORGANIZE;')
        EXECUTE ('ALTER INDEX {0} ON {1} SET(ALLOW_PAGE_LOCKS=OFF);')
    END TRY
	BEGIN CATCH
		PRINT CHAR(9) + 'Failed to Rebuild Index {0} on Table {1}' + CHAR(10)
		PRINT ERROR_MESSAGE()
	END CATCH

    FETCH NEXT FROM index_cursor INTO @table, @index_name
END
CLOSE index_cursor
DEALLOCATE index_cursor

EXECUTE sp_updatestats;