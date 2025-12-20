USE [DATASHARE]
GO

/****** Object:  StoredProcedure [dbo].[sp_CreateViews]    Script Date: 2025-05-14 2:35:32 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE OR ALTER proc [dbo].[sp_CreateViews]
@debug BIT = 0
as

if object_id(N'tempdb..#Columns') is not null drop table #columns

if object_id(N'tempdb..#Tables') is not null drop table #tables

create table #Columns
(
	Database_Name		nvarchar(150)
	,Schema_Name		nvarchar(150)
	,Table_Name			nvarchar(150)
	,Column_Name		nvarchar(150)
	,Full_Table_Name	nvarchar(250)
	,column_id			int 
	,system_type_id			int 
)

create table #Tables
(
	Database_Name		nvarchar(150)
	,Schema_Name		nvarchar(150)
	,Table_Name			nvarchar(150)
	,Full_Table_Name	nvarchar(150)
	,Processed			bit default( 0)
)

declare @str nvarchar(max) = ''
;
with dbs
as
(select
		*
	from sys.databases
	where name not in ('master', 'tempdb', 'model', 'msdb'))
select
	@str = @str + ' union select ''' + dbs.name + ''' collate SQL_Latin1_General_CP1_CI_AS as DatabaseName ,sch.name collate SQL_Latin1_General_CP1_CI_AS  as SchemaName,  tbl.name  collate SQL_Latin1_General_CP1_CI_AS  as TableName,''[''+ col.name +'']'' collate SQL_Latin1_General_CP1_CI_AS  as ColumnName
,''' + dbs.name + '''+''.''+sch.name+''.[''+tbl.name+'']''  collate SQL_Latin1_General_CP1_CI_AS  as FullTableName , col.column_id, col.system_type_id
from ' + dbs.name + '.sys.tables tbl 
inner join ' + dbs.name + '.sys.columns col ON col.object_id = tbl.object_id 
inner join ' + dbs.name + '.sys.schemas  sch ON sch.schema_id = tbl.schema_id
WHERE name NOT LIKE ''%[_][0-9][0-9]%[0-9]%''
AND name NOT LIKE ''Load[_]%''
AND name NOT LIKE ''tmp%'''
from dbs
where name like '%stage%'

set @str = substring(@str, 8, len(@str))

insert into #columns
exec (@str)

create clustered index ix_tempColumns on #Columns (Full_Table_Name,Column_Name);

--Remove columns from exclusion list
delete c
	from #columns c
	inner join tbdatasharecolumnexclusion ce
		on c.table_name = ce.tablename
		and c.column_name = ce.columnname

--Remove tables from exclusion list
delete from #columns
where table_name in (select
			tablename
		from tbdatasharetableexclusion)

insert into #tables
	select distinct
		database_name
	   ,schema_name
	   ,table_name
	   ,full_table_name
	   ,0
	from #columns

declare @Table_Name nvarchar(max)

while exists (select 1 from #tables where processed = 0)
begin
	select
		@Table_Name = table_name
	from #tables
	where processed = 0
	update #tables
	set processed = 1
	where table_name = @Table_Name

	;with AllTables (database_name, table_name, full_table_name)
	as
	(select
			database_name
		   ,table_name
		   ,full_table_name
		from #tables
		where table_name like @Table_Name),
	TablesWithSelectors (database_name, full_table_name, column_name, selector)
	as
	(select distinct
			t.database_name
		   ,t.full_table_name
		   ,a.column_name
		   ,case
				when b.column_name is null then 'NULL as '
				else  case
						when type_name( b.system_type_id) in ('text', 'ntext', 'varchar', 'nvarchar', 'char', 'nchar')
							 then a.column_name + '  collate SQL_Latin1_General_CP1_CI_AS  as '
							 else ''
						end
				end
			+  a.column_name
		from AllTables t
		cross join (select distinct
				column_name , system_type_id
			from #columns
			where full_table_name in (select
					full_table_name
				from AllTables)) a
		left outer join #columns b
			on b.full_table_name = t.full_table_name
			and b.column_name = a.column_name),
	SelectStatements (full_table_name, sql)
	as
	(select
			full_table_name
		   ,'SELECT ' + stuff((select
					', ' + selector
				from TablesWithSelectors t
				where t.full_table_name = r.full_table_name
				order by (select top 1
						column_id
					from #columns c2
					where c2.column_name = t.column_name
					and c2.table_name = @Table_Name)
				for xml path (''), type)
			.value('(./text())[1]', 'VARCHAR(MAX)'), 1, 2, '') + ' , ''' + left(database_name, charindex('_', database_name) - 1) + ''' as Client_Code' + ' FROM ' + full_table_name
		from TablesWithSelectors r
		group by database_name
				,full_table_name)

	select
		@str = ' CREATE OR ALTER VIEW [' + @Table_Name + '] AS ' + stuff((select
				' UNION ALL ' + sql
			from SelectStatements
			for xml path (''), type)
		.value('(./text())[1]', 'VARCHAR(MAX)'), 1, 11, '')

	IF @debug = 1 
	begin
		print @str
	end

	begin try
	exec sp_executesql @str
	end try
	begin catch
	print @str
	break
	end catch
	print @str
end
GO

exec sp_CreateViews

