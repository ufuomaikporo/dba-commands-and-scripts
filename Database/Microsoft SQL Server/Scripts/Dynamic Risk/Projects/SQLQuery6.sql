DECLARE @FKConstraintName NVARCHAR(100);
DECLARE @NewTableName NVARCHAR(100);
DECLARE @FKTableName NVARCHAR(100);
DECLARE @FKColumnName NVARCHAR(100);
DECLARE @RefConstraintName NVARCHAR(100);
DECLARE @RefTableName NVARCHAR(100);
DECLARE @RefColumnName NVARCHAR(100);
DECLARE @ModifiedFKTableName NVARCHAR(100);
DECLARE @TempString NVARCHAR(100);
DECLARE @EndIndex INT;
DECLARE @StartIndex INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE @SetTableName NVARCHAR(100);
DECLARE @Counter INT;
DECLARE @Limit INT;
DECLARE @CharToRemove INT;
DECLARE @CharToKeep INT;
DECLARE @Check INT;

-- TABLE: BellHoleExcavation  COLUMN: BellholeDamageTypeDomainID   NEW_TABLE: BellholeDamageType

--set @NewTableName = 'test'
--SET @FKTableName = 'StructurePointChar'
--SET @FKColumnName = 'StructureTypeDomainId'

----SELECT * FROM PipeSegment
----SELECT * FROM DomainCatalogColXRef
----select * from DomainCatalog Where Id = 701339
----select * from listdomain Where Id = 701339

----select distinct(PipeSeamDomainId) from pipesegment
--SELECT LD.CODE,*
--FROM ListDomain LD
--JOIN DomainCatalogColXRef DCR 
--	ON DCR.DomainCatalogId = LD.DomainCatalogId
--WHERE DCR.TableName = 'PipeSegment'
--AND DCR.ColumnName = 'PipeSeamDomainId';

SELECT * FROM INFORMATION_SCHEMA.tables where table_name = '%History_%'
select * from pipeseam
SELECT * FROM ##fklist order by fk_table
select * from LineLoopType
select * from BEGIN
		SET @ModifiedFKTableName = ''
		SET @StartIndex = 1


		WHILE @StartIndex < LEN(@FKTableName)
		BEGIN
			SET @TempString = STUFF(@FKTableName, 1, @StartIndex, '');
			SET @ModifiedFKTableName += SUBSTRING(@FKTableName, @StartIndex, 1)

			SET @EndIndex = PATINDEX('%[A-Z]%' COLLATE Latin1_General_BIN, @TempString) + @StartIndex

			IF (PATINDEX('%[A-Z]%' COLLATE Latin1_General_BIN, @TempString) = 0)
			BEGIN
				SET @EndIndex = LEN(@FKTableName);
			END;

			SET @StartIndex = @EndIndex
			--set @Counter += 1
		END

		SET @NewTableName = @ModifiedFKTableName + @NewTableName

		SET @SQL = 'UPDATE ##FKList 
		SET new_table_name = ''' + @NewTableName + '''
		WHERE id = ' + CAST(@Counter AS NVARCHAR);

		EXECUTE (@SQL);
	END
select * from BEGIN
		SET @ModifiedFKTableName = ''
		SET @StartIndex = 1


		WHILE @StartIndex < LEN(@FKTableName)
		BEGIN
			SET @TempString = STUFF(@FKTableName, 1, @StartIndex, '');
			SET @ModifiedFKTableName += SUBSTRING(@FKTableName, @StartIndex, 1)

			SET @EndIndex = PATINDEX('%[A-Z]%' COLLATE Latin1_General_BIN, @TempString) + @StartIndex

			IF (PATINDEX('%[A-Z]%' COLLATE Latin1_General_BIN, @TempString) = 0)
			BEGIN
				SET @EndIndex = LEN(@FKTableName);
			END;

			SET @StartIndex = @EndIndex
			--set @Counter += 1
		END

		SET @NewTableName = @ModifiedFKTableName + @NewTableName

		SET @SQL = 'UPDATE ##FKList 
		SET new_table_name = ''' + @NewTableName + '''
		WHERE id = ' + CAST(@Counter AS NVARCHAR);

		EXECUTE (@SQL);
	END

--select * from ##fklist where new_table_name like '%landuse%'
--select * from PipeSeam
--WHERE Code = 'Cold'

SELECT * FROM PipeSegment

UPDATE PipeSegment
SET PipeSeamDomainId = (SELECT NewLDTable.Id FROM PipeSegment fk_table
						JOIN ListDomain LD
							ON LD.Id = fk_table.PipeSeamDomainId
						JOIN PipeSeam NewLDTable
							ON NewLDTable.Code = LD.Code
						WHERE PipeSeamDomainId = )


SELECT DISTINCT(PipeSeamDomainId) as OldDomainId, fkcol.Id AS NewDomainId
FROM PipeSegment fk_table
JOIN ListDomain LD
	ON LD.Id = fk_table.PipeSeamDomainId
JOIN pipeseam fkcol
	ON fkcol.Code = LD.Code
	order by 1
select * from pipeseam
select * from ##fklist where fk_table like '%Pipe%'

select * from PipeSeam

OldDomainId	NewDomainId
701339	4
701151	14
2350	21
11130	26
8	29

SELECT DISTINCT(PipeSeamDomainId) as OldDomainId, NewDomainTable.Id AS NewDomainId
	FROM PipeSegment fk_table
	JOIN ListDomain LD
		ON LD.Id = fk_table.PipeSeamDomainId
	JOIN PipeSeam NewDomainTable
		ON NewDomainTable.Code = LD.Code

SELECT DISTINCT(PipeSeamDomainId) from pipesegment

8
2350
11130
701151
701339

begin transaction
rollback

 PipeSeamDomainId = 8



SELECT *
FROM ##FKList
WHERE fk_constraint = 'FK_PipeSeamDomainId'

SELECT * FROM ##FKLIST WHERE fk_column like '%pipeseam%'

SET @FKTableName = 'SoilLandUseArea'
SET @ModifiedFKTableName = ''
SET @Counter = 1
SET @StartIndex = 1

WHILE @StartIndex < LEN(@FKTableName)
BEGIN
	SET @TempString = STUFF(@FKTableName, 1, @StartIndex, '');
	SET @ModifiedFKTableName += SUBSTRING(@FKTableName, @StartIndex, 1)

	SET @EndIndex = PATINDEX('%[A-Z]%' COLLATE Latin1_General_BIN, @TempString) + @StartIndex

	IF (PATINDEX('%[A-Z]%' COLLATE Latin1_General_BIN, @TempString) = 0)
	BEGIN
		SET @EndIndex = LEN(@FKTableName);
	END;

	SET @StartIndex = @EndIndex
END

select * from ##fklist where fk_table like '%soil%'
--SELECT * FROM MLVCorrection

--SELECT * FROM ACVGSurveyAnomaly

----13	FK_MLVCorAreaDomainId	MLVCorrection	AreaDomainId	MLVCorrectionArea	PK_ListDomain	ListDomain	IdIF OBJECT_ID(@NewTableName, 'U') IS NOT NULL
--BEGIN
--	EXECUTE ('DROP TABLE ' + @NewTableName);
--END

--IF OBJECT_ID(@NewTableName, 'U') IS NULL
--BEGIN
--SET @SQL = 'CREATE TABLE [dbo].[' + @NewTableName + '](
--		[Id] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
--		[Code] [varchar](60) NOT NULL,
--		[Descr] [varchar](255) NOT NULL,
--		[CreatedUser] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
--		[CreatedDate] [datetime] DEFAULT (getdate()) NOT NULL,
--		[LastModByUserId] [varchar](45) DEFAULT (suser_sname()) NOT NULL,
--		[LastModDateTime] [datetime] DEFAULT (getdate()) NOT NULL,
--		CONSTRAINT [PK_' + @NewTableName + '] PRIMARY KEY NONCLUSTERED 
--		(
--			[Id] ASC
--		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
--		CONSTRAINT [UQ_' + @NewTableName + '] UNIQUE NONCLUSTERED 
--		(
--			[Code] ASC
--		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
--		) ON [PRIMARY]';

--	EXECUTE (@SQL)
--END




--execute ('SELECT OLD.Code, OLD.Descr FROM 
--		  (
--			SELECT DISTINCT(LD.Code), 
--				FROM ListDomain LD
--				JOIN DomainCatalogColXRef DCR 
--					ON DCR.DomainCatalogId = LD.DomainCatalogId
--				WHERE DCR.TableName = ''' + @FKTableName + '''
--				AND DCR.ColumnName = ''' +  @FKColumnName + '''
--				) SUBQ
--			JOIN ListDomain OLD
--				ON OLD.Id = SUBQ.Id ')

--				SET @FKColumnName = 'PipeSeamDomainId'
--SET @FKTableName = 'PipeSegment'
	--execute ('SELECT DISTINCT(LD.Id), Code, LD.DomainCatalogId
	--			FROM ListDomain LD
	--			JOIN DomainCatalogColXRef DCR 
	--				ON DCR.DomainCatalogId = LD.DomainCatalogId
	--			WHERE DCR.TableName = ''' + @FKTableName + '''
	--			AND DCR.ColumnName = ''' +  @FKColumnName + '''')
--select * from ##fklist where new_table_name like 'PipeSeam%'