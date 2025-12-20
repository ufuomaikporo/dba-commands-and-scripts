 /* 
	Only works on dbs with version 6.3.2 or greater DE
	Returns a temp table with details on row counts from extract, link, error and stage tables

	This Script was modified to ignore expired StationSeries lines - Sept 6 2024

	**************BEFORE RUNNING SCRIPT****************
	SET '@StageDATABASE' and '@LINKDATABASE' to desired stage and link databases

	Run on Link db 

*/


DECLARE @STAGEDATABASE VARCHAR(30)
DECLARE @LINKDATABASE VARCHAR(30)
DECLARE @SQL NVARCHAR(MAX)
Declare @ExtractTablename VARCHAR(50)
Declare @LinkTableName varchar(50)
Declare @ErrTableName varchar(50)
Declare @StageTableName varchar(50)
Declare @VirtualTableName varchar(50)

--********************************************************************************
-- Update @LINKDATABASE/STAGE to Desired databases

SET @STAGEDATABASE = 'EPCO_IRASv6_GAS_STAGE'
SET @LINKDATABASE = 'EPCO_IRASv6_GAS_LINK'

--************************************************************************************

IF OBJECT_ID('tempdb..#Data_Reconciliation') IS NOT NULL
 BEGIN
	DROP TABLE #Data_Reconciliation
 END

Create Table #Data_Reconciliation
(
	TableName varchar(50) NOT NULL,
	HierarchyOrder int NULL,
	ExtractTable varchar(50) NULL,
	ExtractCount int NULL,
	LinkCount int NULL,
	ErrTable varchar(50) NULL,
	ErrorCount int NULL,
	ErrorTypes varchar(max) NULL,
	StageCount int NULL,
	DataMatch varchar(3) NULL,
	Details varchar(255) NULL
)

-- Update @LINKDATABASE in Select statement to Link database 

SET @sql = 'DECLARE e CURSOR FAST_FORWARD READ_ONLY FOR
select Table_Name from ' + @LINKDATABASE + '.INFORMATION_SCHEMA.TABLES
where TABLE_Name like (''Extract_%'')'

EXECUTE (@sql)

OPEN e
 
FETCH NEXT FROM e INTO @ExtractTablename
 
WHILE @@FETCH_STATUS = 0
BEGIN
 
SET @sql = 'insert into #Data_Reconciliation (TableName, ExtractTable, ExtractCount, ErrTable)
			Select 
				replace('''+@ExtractTablename+''',''Extract_'',''''), 
				'''+@ExtractTablename+''', 
				 (Select count(*) from '+ @LINKDATABASE + '.dbo.'+@ExtractTablename+'),
				 replace('''+@ExtractTablename+''',''Extract_'',''Err_'')
			where (Select count(*) from ' + @LINKDATABASE + '.dbo.' +@ExtractTablename+') > 0'

EXECUTE (@sql)

FETCH NEXT FROM e INTO @ExtractTablename
END
 
CLOSE e
DEALLOCATE e

DECLARE l CURSOR FAST_FORWARD READ_ONLY FOR
select TABLEName from #Data_Reconciliation

OPEN l
 
FETCH NEXT FROM l INTO @LinkTableName
 
WHILE @@FETCH_STATUS = 0
BEGIN

SET @sql = 'Update #Data_Reconciliation
			Set LinkCount = (Select count(*) from '+ @LINKDATABASE + '.dbo.'+@LinkTableName+')
			where TableName = '''+@LinkTablename+''' '

EXECUTE (@sql)

FETCH NEXT FROM l INTO @LinkTablename
END
 
CLOSE l
DEALLOCATE l


DECLARE r CURSOR FAST_FORWARD READ_ONLY FOR
select ErrTable from #Data_Reconciliation

OPEN r
 
FETCH NEXT FROM r INTO @ErrTableName
 
WHILE @@FETCH_STATUS = 0
BEGIN

SET @sql = 'Update #Data_Reconciliation
			Set ErrorCount = (Select count(*) from '+ @LINKDATABASE + '.dbo.'+@ErrTableName+'),
			ErrorTypes = (Select String_Agg(MessagesText, '','') from 
						(Select distinct MessagesText 
							from ' + @LINKDATABASE + '.dbo.' +@ErrTableName+') e) 

			where ErrTable = '''+@ErrTableName+''' '

EXECUTE (@sql)

FETCH NEXT FROM r INTO @ErrTableName
END
 
CLOSE r
DEALLOCATE r


DECLARE s CURSOR FAST_FORWARD READ_ONLY FOR
select TABLEName from #Data_Reconciliation
where TableName not in ('DistrictDivision','Area','StateProvince') and TableName not like 'VT_%'

OPEN s
 
FETCH NEXT FROM s INTO @StageTableName
 
WHILE @@FETCH_STATUS = 0
BEGIN

	IF (@StageTableName = 'OperatingUnit')
	BEGIN
		SET @sql = 'UPDATE #Data_Reconciliation
			SET StageCount = (SELECT COUNT(DISTINCT ou.Id )
							FROM ' + @StageDATABASE + '.dbo.OperatingUnit ou
							INNER JOIN ' + @StageDATABASE + '.dbo.PipelineSystem ps
							ON ps.OperatingUnitId = ou.Id
							INNER JOIN ' + @StageDATABASE + '.dbo.DischargeSubsystem d
							ON ps.Id = d.PipelineSystemId
							INNER JOIN ' + @StageDATABASE + '.dbo.StationSeries s
							ON d.Id = s.DischargeSubsystemId 
							WHERE s.EffectiveEndDate IS NULL)
			WHERE TableName = ''OperatingUnit'' '

			print @sql
	END
	ELSE IF (@StageTableName = 'StationSeries')
	BEGIN
		SET @sql = 'Update #Data_Reconciliation
			Set StageCount = (SELECT COUNT(DISTINCT Id) FROM '+ @StageDATABASE + '.dbo.StationSeries
							  WHERE EffectiveEndDate IS NULL 
							 )
			WHERE TableName = ''StationSeries'' '
	END
	ELSE IF (@StageTableName IN ('LineLoop', 'DischargeSubsystem'))
	BEGIN
		SET @sql = 'UPDATE #Data_Reconciliation
			SET StageCount = (SELECT COUNT(DISTINCT a.Id) 
							  FROM '+ @StageDATABASE + '.dbo.' + @StageTableName + ' a
							  INNER JOIN '+ @StageDATABASE + '.dbo.StationSeries b
							  ON a.Id = b.' + @StageTableName + 'Id
							  WHERE b.EffectiveEndDate IS NULL)
			WHERE TableName = ''' + @StageTableName + ''' '
	END
	ELSE IF (@StageTableName = 'PipeLineSystem')
	BEGIN
		SET @sql = 'UPDATE #Data_Reconciliation
			SET StageCount =(SELECT COUNT(DISTINCT p.Id) 
							  FROM '+ @StageDATABASE + '.dbo.PipeLineSystem p
							  INNER JOIN '+ @StageDATABASE + '.dbo.DischargeSubsystem d
							  ON p.Id = d.PipelineSystemId
							  INNER JOIN ' + @StageDATABASE + '.dbo.StationSeries s
							  ON d.Id = s.DischargeSubsystemId
							  WHERE s.EffectiveEndDate IS NULL)
			WHERE TableName = ''PipeLineSystem'''
	END
	ELSE IF (@StageTableName = 'MLVSection')
	BEGIN
		SET @sql = 'UPDATE #Data_Reconciliation
			SET StageCount = (SELECT COUNT(DISTINCT ms.Id) 
							  FROM '+ @StageDATABASE + '.dbo.MLVSection ms
							  INNER JOIN '+ @StageDATABASE + '.dbo.MLVCorrection mc
							  ON ms.Id = mc.MLVSectionId
							  WHERE mc.EffectiveEndDate IS NULL)
			WHERE TableName = ''MLVSection'''
	END
	ELSE
	BEGIN
		SET @sql = 'Update #Data_Reconciliation
					Set StageCount = (Select count(*) from '+ @StageDATABASE + '.dbo.'+@StageTableName+')
					WHERE TableName = '''+@StageTablename+''' '
	END

EXECUTE (@sql)

FETCH NEXT FROM s INTO @StageTableName
END
 
CLOSE s
DEALLOCATE s


DECLARE v CURSOR FAST_FORWARD READ_ONLY FOR
select replace(TABLEName, 'Vt_', '') from #Data_Reconciliation
where TableName like 'VT_%'

OPEN v
 
FETCH NEXT FROM v INTO @VirtualTableName
 
WHILE @@FETCH_STATUS = 0
BEGIN

SET @sql = 'Update #Data_Reconciliation
			Set StageCount = 
				(Select count(*) from '+ @StageDATABASE + '.dbo.VirtualTableStationing vts
				inner join ' + @StageDATABASE + '.dbo.virtualtable vt on vt.id = vts.VirtualTableId
				where vt.VirtualTableName = '''+@VirtualTablename+''')
			where TableName = ''Vt_'+@VirtualTablename+''' '

EXECUTE (@sql)
FETCH NEXT FROM v INTO @VirtualTableName
END
 
CLOSE v
DEALLOCATE v


DECLARE v2 CURSOR FAST_FORWARD READ_ONLY FOR
select replace(TABLEName, 'Vt_', '') from #Data_Reconciliation
where TableName like 'VT_%'

OPEN v2
 
FETCH NEXT FROM v2 INTO @VirtualTableName
 
WHILE @@FETCH_STATUS = 0
BEGIN

SET @sql = 'Update #Data_Reconciliation
			Set DataMatch = CASE 
			WHEN ExtractCount = LinkCount AND LinkCount = StageCount THEN ''YES''
			ELSE ''NO''
			End,
			Details =
				CASE 
					WHEN ErrorCount > 0 AND ErrorCount + LinkCount = ExtractCount THEN ''Check and resolve errors in error table''
					WHEN ErrorCount > 0 AND ErrorCount + LinkCount <> ExtractCount THEN ''Check error table and investigate data inconsistencies''
				End
			where TableName = ''Vt_'+@VirtualTablename+''' '

EXECUTE (@sql)

FETCH NEXT FROM v2 INTO @VirtualTableName
END
 
CLOSE v2
DEALLOCATE v2


Update #Data_Reconciliation
set DataMatch =
 CASE 
			WHEN ExtractCount = LinkCount THEN 'YES'
			ELSE 'NO'
			End,
Details = Case 
	WHEN ErrorCount > 0 AND ErrorCount + LinkCount = ExtractCount Then 'Check and resolve errors in error table. Table not in Stage db'
	ELSE 'Table not in Stage db'
	End
where TableName in ('Area','DistrictDivision','StateProvince')



DECLARE m CURSOR FAST_FORWARD READ_ONLY FOR
select TABLEName from #Data_Reconciliation
where TableName not in ('DistrictDivision','Area','StateProvince') and TableName not like 'VT_%'

OPEN m
 
FETCH NEXT FROM m INTO @StageTableName
 
WHILE @@FETCH_STATUS = 0
BEGIN

SET @sql = 'Update #Data_Reconciliation
			Set DataMatch = 
			CASE 
			WHEN ExtractCount = LinkCount AND LinkCount = StageCount THEN ''YES''
			ELSE ''NO''
			End,
			Details = 
			CASE 
			WHEN ErrorCount > 0 AND ErrorCount + LinkCount = ExtractCount THEN ''Check and resolve errors in error tables''
			WHEN ErrorCount > 0 AND ErrorCount + LinkCount <> ExtractCount THEN ''Check error table and investigate data inconsistencies''
			WHEN ErrorCount = 0 AND StageCount = 0 AND LinkCount > 0 THEN ''Run Load in DE for data reconciliation. ''
			WHEN ErrorCount = 0 AND StageCount <> LinkCount AND LinkCount = ExtractCount THEN ''Run Load in DE for data reconciliation. Check expired lines. ''
			End
			where TableName = '''+@StageTablename+''' '

EXECUTE (@sql)

FETCH NEXT FROM m INTO @StageTableName
END
 
CLOSE m
DEALLOCATE m

SET @sql = 'insert into #Data_Reconciliation
(TableName, LinkCount, StageCount, DataMatch, Details)
		(Select ''MLVCorrection'',
		(Select count(*) from ' + @LINKDATABASE + '.dbo.MLVCorrection), 
		(Select count(*) from ' + @StageDATABASE + '.dbo.MLVCorrection),
			CASE when (Select count(*) from ' + @LINKDATABASE + '.dbo.MLVCorrection) = (Select count(*) from ' + @StageDATABASE + '.dbo.MLVCorrection) THEN ''YES''
			ELSE ''NO''
			END,
			CASE when (Select count(*) from ' + @LINKDATABASE + '.dbo.MLVCorrection) = (Select count(*) from ' + @StageDATABASE + '.dbo.MLVCorrection) THEN ''MLVCorrection calculated using BuildCenterline stored procedure in Link and Dx6ConfigV5 stored procedure in Stage''
			ELSE ''Review data issues in hierarchy tables. MLVCorrection calculated using BuildCenterline stored procedure in Link and Dx6ConfigV5 stored procedure in Stage''
			END)'

EXECUTE (@sql)
			
SET @sql = 'insert into #Data_Reconciliation
(TableName, LinkCount, StageCount, DataMatch, Details)
		(Select ''SeriesConnection'',(Select count(*) from ' + @LINKDATABASE + '.dbo.SeriesConnection), (Select count(*) from ' + @StageDATABASE + '.dbo.SeriesConnection),
			CASE when (Select count(*) from ' + @LINKDATABASE + '.dbo.SeriesConnection) = (Select count(*) from ' + @StageDATABASE + '.dbo.SeriesConnection) THEN ''YES''
			ELSE ''NO''
			END,
			CASE when (Select count(*) from ' + @LINKDATABASE + '.dbo.SeriesConnection) = (Select count(*) from ' + @StageDATABASE + '.dbo.SeriesConnection) THEN ''SeriesConnection calculated using BuildCenterline stored procedure in Link and Dx6ConfigV5 stored procedure in Stage''
			ELSE ''Review data issues in hierarchy tables. SeriesConnection calculated using BuildCenterline stored procedure in Link and Dx6ConfigV5 stored procedure in Stage''
			END)'

EXECUTE (@sql)

-- Fabrication
SET @sql = 'insert into #Data_Reconciliation
(TableName, StageCount, DataMatch, Details)
Select 
	''Fabrication'',
	(Select count(*) from ' + @StageDATABASE + '.dbo.Fabrication),
	CASE when 
	ISNULL((Select StageCount from #Data_Reconciliation where TableName = ''Elbow''),0)+ISNULL((Select StageCount from #Data_Reconciliation where TableName = ''Tap''),0)+
	ISNULL((Select StageCount from #Data_Reconciliation where TableName = ''Tee''),0)+ISNULL((Select StageCount from #Data_Reconciliation where TableName = ''Flange''),0)+
	ISNULL((Select StageCount from #Data_Reconciliation where TableName = ''Reducer''),0)+ISNULL((Select StageCount from #Data_Reconciliation where TableName = ''Extrusion''),0)
	+ISNULL((Select StageCount from #Data_Reconciliation where TableName = ''Vent''),0)=
	(Select count(*) from ' + @StageDATABASE + '.dbo.Fabrication) THEN ''YES''
	ELSE ''NO''
	END,
	CASE When ISNULL((Select StageCount from #Data_Reconciliation where TableName = ''Elbow''),0)+ISNULL((Select StageCount from #Data_Reconciliation where TableName = ''Tap''),0)+
	ISNULL((Select StageCount from #Data_Reconciliation where TableName = ''Tee''),0)+ISNULL((Select StageCount from #Data_Reconciliation where TableName = ''Flange''),0)+
	ISNULL((Select StageCount from #Data_Reconciliation where TableName = ''Reducer''),0)+ISNULL((Select StageCount from #Data_Reconciliation where TableName = ''Extrusion''),0)
	+ISNULL((Select StageCount from #Data_Reconciliation where TableName = ''Vent''),0)=
	(Select count(*) from ' + @StageDATABASE + '.dbo.Fabrication) THEN ''Table only in Stage db. Fabrication comprised of data from Elbow, Extrusion, Flange, Reducer, Tap, Tee, Vent tables.''
	ELSE ''Review errors for Data Reconciliation. Table only in Stage db. Fabrication comprised of data from Elbow, Extrusion, Flange, Reducer, Tap, Tee, Vent tables.''
	END'

EXECUTE (@sql)

update #Data_Reconciliation
set HierarchyOrder = 
	CASE
	when TableName = 'Corporation' THEN 1
	when TableName = 'OperatingUnit' THEN 2
	when TableName = 'PipelineSystem' THEN 3
	when TableName = 'DischargeSubsystem' THEN 4
	when TableName = 'LineLoop' THEN 5
	when TableName = 'StationSeries' THEN 6
	when TableName = 'MLVSection' THEN 7
	when TableName = 'MLVCorrection' THEN 8
	when TableName = 'SeriesConnection' THEN 9
	when TableName = 'Bend' THEN 10
	when TableName = 'Area' THEN 11
	when TableName = 'DistrictDivision' THEN 12
	when TableName = 'StateProvince' THEN 13
	ELSE NULL
	END



-- Hierarchy Centerline tables
select TableName, ExtractCount, LinkCount, ErrorCount,StageCount,DataMatch,Details from #Data_Reconciliation where TableName in ('Corporation','OperatingUnit','PipelineSystem','DischargeSubsystem','LineLoop','StationSeries','MLVSection','MLVCorrection','SeriesConnection',
														'Bend','Area','DistrictDivision','StateProvince') order by HierarchyOrder asc

-- Event and Virtual tables
select TableName, ExtractCount, LinkCount, ErrorCount,StageCount,DataMatch,Details from #Data_Reconciliation  where TableName not in ('Corporation','OperatingUnit','PipelineSystem','DischargeSubsystem','LineLoop','StationSeries','MLVSection','MLVCorrection','SeriesConnection',
														'Bend','Area','DistrictDivision','StateProvince') order by TableName

-- Tables where the data isn't reconciled
select TableName, ExtractCount, LinkCount, ErrorCount, ErrorTypes, StageCount,DataMatch,Details from #Data_Reconciliation where DataMatch = 'NO' order by TableName 
 

