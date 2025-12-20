--SELECT * --distinct top 1 VirtualColumnId, VirtualTableId, DataFieldValueDomainId
--FROM dbo.VirtualTableDataListDomain vtdld


--SELECT * FROM dbo.VirtualTable vt WHERE id = 173
--SELECT * FROM dbo.VirtualColumn vt WHERE id = 197
--SELECT * FROM dbo.ListDomain ld WHERE Id = 95

--select distinct virtualtableid from VirtualTableDataListDomain
DECLARE @VTableId INT = 10

--SELECT DISTINCT VirtualTableId FROM dbo.VirtualTableDataListDomain vtdld
-- SELECT * FROM VirtualColumn WHERE virtualColumnDataTypeInd = 'L'

SELECT * FROM dbo.VirtualTable vt WHERE id = @VTableId
SELECT * FROM dbo.VirtualColumn vt WHERE VirtualTableId = @VTableId
SELECT * FROM dbo.ListDomain ld WHERE Id IN (SELECT DISTINCT DataFieldValueDomainId FROM VirtualTableDataListDomain
											 WHERE VirtualTableId = @VTableId)
SELECT * FROM .ListDomain ld WHERE Id IN (SELECT DISTINCT DataFieldValueDomainId FROM VirtualTableDataListDomain
											 WHERE VirtualTableId = @VTableId)

--select top 1 * from stationseries
--select top 1 * from VirtualTableStationing
--where virtualtableId = 205
--select * from listdomain
--select  * from VirtualTableDataListDomain WHERE virtualtableId = 173 and virtualcolumnid = 197
--select * from DomainCatalog
--select * from DomainCatalogColXRef
--select * from INFORMATION_SCHEMA.columns
--where column_name = 'beginstationseriesid'

--SP_columns listdomain

--SELECT OBJECT_NAME(constraint_object_id) AS fk_constraint,
--	   OBJECT_NAME(parent_object_id) AS fk_table,
--	   COL_NAME(parent_object_id, parent_column_id) AS fk_column,
--	   OBJECT_NAME(referenced_object_id) AS referenced_table,
--	   COL_NAME(referenced_object_id, referenced_column_id) AS referenced_column
--FROM sys.foreign_key_columns
--WHERE OBJECT_NAME(parent_object_id) = 'VirtualTableDataListDomain'



				--INSERT INTO ##DomainInfo (VirtualTableId, 
				--						  VirtualColumnId, 
				--						  VirtualTableStationingId, 
				--						  OldDomainId)
				--SELECT VirtualTableId, 
				--	   VirtualColumnId, 
				--	   VirtualTableStationingId, 
				--	   DataFieldValueDomainId
				--	   --ld.id,
				--	   --ld.code,
				--	   --ld.descr
				--FROM VirtualTableDataListDomain vtld
				----JOIN ListDomain ld
				----	ON ld.Id = vtld.DataFieldValueDomainId
				--WHERE VirtualTableId = '164'
				--AND VirtualColumnId = '188'
				--order by ld.id

				--select * from ##domaininfo
				--select * from MDHistoricPressCycleLD
				--drop table ICPiggingFrequencyLD
				--drop table MDHistoricPressCycleLD

				--		SELECT  
				--		VIRTUALTABLEID, 
				--				VIRTUALCOLUMNID, 
				--				di.VIRTUALtableSTATIONINGID, 
				--				OLDDOMAINID,
				--				nt.ID,
				--				di.CODE,
				--				di.DESCR
				--FROM MDHistoricPressCycleLD nt
				--JOIN ##DomainInfo di
				--ON nt.Code = di.Code
				--AND nt.Descr = di.Descr
				--order by nt.id

				--SELECT VIRTUALTABLEID, 
				--				VIRTUALCOLUMNID, 
				--				di.VIRTUALtableSTATIONINGID, 
				--				OLDDOMAINID,
				--				nt.ID,
				--				di.CODE,
				--				di.DESCR
				--FROM ICPiggingFrequencyLD nt
				--JOIN ##DomainInfo di
				--ON nt.Code = di.Code
				--AND nt.Descr = di.Descr

----UPDATE VirtualTableDataListDomain      --SET DataFieldValueDomainId = Id  
--select * from ##DomainInfo
--SELECT DISTINCT di.*, nt.*     
--		FROM ICPiggingFrequencyLD nt
--				JOIN ##DomainInfo di
--					ON nt.code = di.code
--					AND nt.descr = di.descr
--				INNER JOIN VirtualTableDataListDomain vtld
--					ON di.VirtualTableId = vtld.VirtualTableId
--					AND di.VirtualColumnId = vtld.VirtualColumnId
--					AND di.OldDomainId = vtld.DataFieldValueDomainId
--order by id

--SELECT * FROM VirtualTableDataListDomain
--	WHERE VirtualTableId = 81
--				AND VirtualColumnId = 124
--order by DataFieldValueDomainId

--SELECT DataFieldValueDomainId, count(DataFieldValueDomainId
--) FROM VirtualTableDataListDomain
--	WHERE VirtualTableId = 81
--				AND VirtualColumnId = 124
--				group by DataFieldValueDomainId
--order by DataFieldValueDomainId


--select virtualtableId, virtualcolumnId, count(virtualTableId)
--from VirtualTableDataListDomain
--group by VirtualTableId,virtualcolumnId
--order by VirtualTableId

--select * into VirtualTableDataListDomainOriginalCopy
--from VirtualTableDataListDomain

--SELECT virtualcolumnId, virtualtableid, DataFieldValueDomainId
--FROM VirtualTableDataListDomainOriginalCopy
--except
--SELECT virtualcolumnId, virtualtableid, DataFieldValueDomainId
--FROM VirtualTableDataListDomain

--select * from VirtualTableDataListDomainOriginalCopy
--	WHERE VirtualTableId = '164'
--				AND VirtualColumnId = '188'
--order by VirtualTableStationingId

--select * from VirtualTableDataListDomain
--	WHERE VirtualTableId = '10'
--				AND VirtualColumnId = '9'
--order by VirtualTableStationingId


--SELECT vtld.VirtualTableId, 
--	vtld.VirtualColumnId, 
--	vtld.VirtualTableStationingId, 
--	og.DataFieldValueDomainId,
--	vtld.DataFieldValueDomainId
--FROM VirtualTableDataListDomainOriginalCopy og
--JOIN VirtualTableDataListDomain vtld
--ON vtld.VirtualColumnId = og.VirtualColumnId
--AND vtld.VirtualTableId = og.VirtualTableId
--AND vtld.VirtualTableStationingId = og.VirtualTableStationingId
--	WHERE vtld.VirtualTableId = 81
--				AND vtld.VirtualColumnId = 124
--				order by vtld.VirtualTableId, vtld.DataFieldValueDomainId

--SELECT virtualTableId, VirtualColumnId, COUNT(DataFieldValueDomainId)
--FROM VirtualTableDataListDomain
--GROUP BY virtualTableId, VirtualColumnId
--ORDER BY 1,2

--select * from VirtualTableDataListDomain
