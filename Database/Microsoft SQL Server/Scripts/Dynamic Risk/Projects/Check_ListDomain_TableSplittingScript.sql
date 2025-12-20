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
DECLARE @IfExists INT;
DECLARE @IsDuplicate INT;
DECLARE @Code NVARCHAR(100);
DECLARE @OldDomainId INT;
DECLARE @NewDomainId INT;
DECLARE @QUERYNUM INT;

--SELECT DISTINCT(PipeSeamDomainId) as OldDomainId, NewDomainTable.Id AS NewDomainId
--	FROM PipeSegment fk_table
--	JOIN ListDomain LD
--		ON LD.Id = fk_table.PipeSeamDomainId
--	JOIN PipeSeam NewDomainTable
--		ON NewDomainTable.Code = LD.Code
--select * from ##NewDomainTableList where fk_table = 'pipesegment'

--FK_ILINCDGrading2DomainId                                                                            InlineInspectionNonCrsnDfct                                                                          ILINCDGrading2DomainId                                                                               ILINCDGrading2
--InlineInspectionNonCrsnDfct
--ILINCDGrading2DomainId
--ILINCDGrading2
--delete from ##NewDomainTableList where FKConstraint = 'FK_ILINCDGrading2DomainId'
--select * from ##NewDomainTableList where FKConstraint = 'FK_ILINCDGrading2DomainId'

SET @QUERYNUM = 2

--select * from ##NewDomainTableList where FKConstraint = 'FK_POECoatPropCoatLineDomainId'

SET @FKConstraintName = 'FK_POECoatPropCoatLineDomainId' --'FK_StructAreaFillStructTypeLD' --'FK_POECoatPropCoatLineDomainId' --'FK_ClassAreaRatingDomainId' --'FK_RCCPStateProvinceDomainID' --'FK_POECoLkpCoDomainId' --'FK_PointCharTypeDomainId' --FK_PipeSeamDomainId
SELECT @FKTableName = FKTableName FROM ##NewDomainTableList WHERE FKConstraint = @FKConstraintName --'PointChar'
SELECT @FKColumnName = FKColumnName FROM ##NewDomainTableList WHERE FKConstraint = @FKConstraintName --'PointCharTypeDomainId'
SELECT @NewTableName = NewListDomainTable FROM ##NewDomainTableList WHERE FKConstraint = @FKConstraintName --'PointCharType'

select @FKConstraintName As FKConstraint 
,@FKTableName fk_table, @FKColumnName fk_column, @NewTableName as new_table_name

--SELECT count(DISTINCT(code)) FROM 
--(
--select c.ValueDomainId, v.Id, v.code, v.descr
--from CategoryDataListDomainXRef c 
--join value v
--on c.ValueDomainId = v.id
--UNION
--select c.ValueDomainId, v.Id ,ld.code, ld.descr
--from CategoryDataListDomainXRef c 
--join listdomain ld
--on ld.Id = c.ValueDomainId
--left join value v
--on v.code = ld.code
--WHERE ValueDomainId NOT IN (SELECT Id FROM value)
--order by code
--) TMP

--SELECT * FROM ##NewDomainTableList WHERE FKConstraint IN ('FK_CDLDXValueDomainId'
--,'FK_ILIFacTypeDomainId'
--,'FK_LLProdTypeLd'
--,'FK_LLStatusLd'
--,'FK_MLVCorDistrictDivisionLD'
--,'FK_MLVCorStateProvinceDomainId'
--,'FK_MtrlRghns_MtrlRghnsLd'
--,'FK_PointCharTypeDomainId'
--,'FK_RCMLVStateProvinceDomainID'
--,'FK_RCSFAreaDomainId'
--,'FK_RCSFDistDivisionDomainId'
--,'FK_RCSFStateProvinceDomainID'
--,'FK_RCSTV_VarScrSrceDomainIdX'
--,'FK_RemLDVal_Ld'
--,'FK_Stg_ILIEventTableLDLD'
--,'FK_Stg_ILIFacTypdLD')
--------------------------------------------------------------------
IF (@QUERYNUM = 3)
BEGIN
SET @SQL = 'SELECT DISTINCT ' + @FKColumnName + ' AS OldDomainId,
	   NewDomain.Id NewDomainId, 
	   Ld.Code, 
	   Ld.descr, 
	   Ld.domaincatalogId ListDomain_CatalogId, 
	   dccxr.domaincatalogid DomainCatalogColXRef_CatalogId
FROM ' + @FKTableName + ' C
JOIN ListDomain Ld
	ON C.' + @FKColumnName + ' = Ld.Id
LEFT JOIN DomainCatalogColXRef dccxr
	ON Ld.DomainCatalogId = dccxr.DomainCatalogId
	AND TableName = ''' + @FKTableName + '''
	AND ColumnName = ''' + @FKColumnName + '''
LEFT JOIN ' + @NewTableName + '  NewDomain
	ON Ld.Code = NewDomain.Code
ORDER BY Ld.Code'

EXECUTE (@SQL)


PRINT 'Contents of ##ListDomainInfo table (Not reliable if ' + @FKColumnName + ' column has been updated)'

SET @SQL = '
SELECT Code, COUNT(Code)
FROM
(
SELECT DISTINCT lD.Id, Code, Descr
FROM ListDomain Ld
JOIN '+ @FKTableName + ' fk_table
 ON Ld.Id = fk_table. ' + @FKColumnName + '
 ) SubQ
 GROUP BY Code
 HAVING COUNT(Code) > 3'

EXECUTE (@SQL)
END
--select count(*) from 
--(
--SELECT DISTINCT(code) FROM CategoryDataListDomainXRef c
--left join listdomain ld
--on ld.Id = c.ValueDomainId
--) tmp

--select count(distinct(code)) from CategoryDataListDomainXRef


--SELECT * FROM CategoryDataListDomainXRef WHERE ValueDomainId = 701944

--select distinct(ValueDomainId) from CategoryDataListDomainXRef
--select id from listdomain where id = 405

--SELECT p.PointCharTypeDomainId, ld.code, ld.descr FROM PointChar p 
--JOIN ListDomain ld
--ON ld.Id = p.PointCharTypeDomainId
----WHERE PointCharTypeDomainId NOT IN (SELECT Id FROM PointCharType)
--order by ld.code


------------------------------------- compare content of new domain table, and child table
IF (@querynum = 1)
BEGIN

PRINT 'The codes below are missing from the NEW domain table'
SET @SQL = 'SELECT DISTINCT ' + @FKColumnName + ' AS OldDomainId, 
			NewDomain.Id AS NewDomainId,
			Ld.Code, 
			Ld.Descr
			FROM ' + @FKTableName +' fk_table
			JOIN ListDomain Ld
			ON Ld.Id = fk_table.'+ @FKColumnName +'
			JOIN ' + @NewTableName + ' NewDomain
			ON TRIM(NewDomain.Code) = TRIM(Ld.Code)
			WHERE TRIM(Ld.Code) NOT IN (SELECT Code FROM '+ @NewTableName +')
ORDER BY 1'

execute (@sql)


PRINT 'Duplication in child table'

SET @SQL = 'SELECT NewDomain.Id As NewDomainId,
			COUNT(*)
			FROM 
			(SELECT DISTINCT(' + @FKColumnName + ') AS ' + @FKColumnName + '
			 FROM ' + @FKTableName + ' fk_table
			 WHERE ' + @FKColumnName + ' NOT IN (SELECT Id FROM ' + @NewTableName + ')
			) SubQ
			JOIN ListDomain Ld
				ON Ld.Id = SubQ.' + @FKColumnName +'
			JOIN ' + @NewTableName + ' NewDomain
				ON NewDomain.Code = Ld.Code
			WHERE ' + @FKColumnName + ' NOT IN (SELECT Id FROM ' + @NewTableName + ') 
			GROUP BY NewDomain.Id 
			HAVING COUNT(*) > 1
			ORDER BY NewDomain.Id '

execute (@sql)

PRINT 'Domain key values that need to be changed IN CHILD TABLE ---> Child TableName: ' + @FKTableName
SET @SQL = 'SELECT SubQ.' + @FKColumnName + ' As OldDomainId, 
			NewDomain.Id As NewDomainId,
			Ld.Code, 
			Ld.Descr
			FROM 
			(SELECT DISTINCT(' + @FKColumnName + ') AS ' + @FKColumnName + '
			 FROM ' + @FKTableName + ' fk_table
			 WHERE ' + @FKColumnName + ' NOT IN (SELECT Id FROM ' + @NewTableName + ')
			) SubQ
			JOIN ListDomain Ld
				ON Ld.Id = SubQ.' + @FKColumnName +'
			JOIN ' + @NewTableName + ' NewDomain
				ON NewDomain.Code = Ld.Code
			WHERE ' + @FKColumnName + ' NOT IN (SELECT Id FROM ' + @NewTableName + ') 
			ORDER BY NewDomain.Id' 

EXECUTE (@SQL)		

PRINT ' All DISTINCT code and Id combos in child table'
SET @SQL = 'SELECT DISTINCT(fk_table.' + @FKColumnName + '), Ld.Code, Ld.Descr
	   FROM ' + @FKTableName +' fk_table
	   JOIN ListDomain Ld
	   ON Ld.Id = fk_table.'+ @FKColumnName +'
	   JOIN ' + @NewTableName + ' NewDomain
	   ON TRIM(NewDomain.Code) = TRIM(Ld.Code)
	   WHERE fk_table.'+ @FKColumnName +' NOT IN (SELECT Id FROM '+ @NewTableName +') 
	   UNION
	   SELECT DISTINCT(' + @FKColumnName + '), NewDomain.Code, NewDomain.Descr
	   FROM '+ @FKTableName +' fk_table
	    JOIN ' + @NewTableName +' NewDomain
		ON fk_table.'  + @FKColumnName + ' = NewDomain.Id
	   WHERE '+ @FKColumnName +' IN (SELECT Id FROM '+ @NewTableName +')  
		ORDER BY 2'

		
execute (@sql)

PRINT 'Contents of new domain table ---> ' + @NewTableName
SET @SQL = 'SELECT * FROM ' + @NewTableName + ' ORDER BY Code'

execute (@sql)

END


--SELECT * FROM POECoatingProperty WHERE CoatingLineDomainId = 14
--select * from INFORMATION_SCHEMA.KEY_COLUMN_USAGE
--where TABLE_NAME = 'POECoatingProperty'
-------------------------------------------- test updat


----------------------------------------------- final check ?? -----------------------
IF (@QUERYNUM) = 2
BEGIN
SELECT 'Unchanged foreign keys'
SELECT * 
FROM ##NewDomainTableList
WHERE FKConstraint NOT IN 
(SELECT OBJECT_NAME(constraint_object_id) AS FKConstraint
FROM sys.foreign_key_columns
WHERE OBJECT_NAME(constraint_object_id) IN (select FKConstraint FROM ##NewDomainTableList)
AND OBJECT_NAME(referenced_object_id) <> 'ListDomain'
						
)

SELECT 'Changed foreign keys'
SELECT OBJECT_NAME(constraint_object_id) AS FKConstraint,
	   OBJECT_NAME(parent_object_id) AS fk_table,
	   COL_NAME(parent_object_id, parent_column_id) AS fk_column,
	   OBJECT_NAME(referenced_object_id) AS referenced_table,
	   COL_NAME(referenced_object_id, referenced_column_id) AS referenced_column
FROM sys.foreign_key_columns
WHERE OBJECT_NAME(constraint_object_id) IN (select FKConstraint FROM ##NewDomainTableList)
AND OBJECT_NAME(referenced_object_id) <> 'ListDomain'
ORDER BY 4
						
END
----------------------------------------------------------------------------

SET @SQL = 'Select 
	(SELECT DISTINCT(' + @FKColumnName + ') as OldDomainId, 
			NewDomainTable.Id AS NewDomainId,
			Ld.code,
			Ld.Descr
		FROM ' + @FKTableName + ' fk_table
		JOIN ListDomain LD
			ON LD.Id = fk_table.' + @FKColumnName + '
		JOIN ' + @NewTableName + ' NewDomainTable
			ON NewDomainTable.Code = LD.Code
		WHERE ' + @FKColumnName + ' <> NewDomainTable.Id) SubQ'

		IF OBJECT_ID('tempdb.##ListDomainInfo') IS NOT NULL
					BEGIN
						DROP TABLE ##ListDomainInfo;

						SELECT fk_table.PointCharTypeDomainId As OldDomainId, 
							TRIM(Ld.Code) AS Code, 
							TRIM(Ld.Descr) As Descr
					INTO ##ListDomainInfo
					FROM PointChar fk_table
					JOIN ListDomain Ld
						ON Ld.Id = fk_table.PointCharTypeDomainId;
					END;

					