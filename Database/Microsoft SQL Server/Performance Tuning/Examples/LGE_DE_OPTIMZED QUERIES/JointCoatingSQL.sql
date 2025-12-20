WITH LineInfo AS
(
SELECT DISTINCT e.RouteId, E.ROUTENAME, p.globalid as StationSeriesId
FROM gas.P_ENGINEERINGNETWORK E 
INNER JOIN gas.PIPELINELINE P ON E.ROUTEID = P.routeid
WHERE
P.AssetGroup in (3,20,2) and P.lifecyclestatus = 8 AND P.GDB_BRANCH_ID = 0 and P.GDB_IS_DELETE = 0
AND legacysystem is not null 
)

SELECT DISTINCT C.ENGFROMM as BeginStationNum, C.ENGTOM as EndStationNum, L.RouteId,
L.ROUTENAME, C.GLOBALID as sourceid, c.gdb_archive_oid, CONVERT(varchar, C.DateApplied, 106) as DateApplied,
 c.jointcoatingtype, L.StationSeriesId
FROM LineInfo L
INNER JOIN gas.P_EXTERNALCOATING C ON L.RouteId = C.ENGROUTEID
    INNER JOIN (select distinct GLOBALID, max(GDB_FROM_DATE) as MaxDate
        from gas.P_EXTERNALCOATING 
        WHERE GDB_BRANCH_ID = 0
        group by GLOBALID) G
    on C.GLOBALID = G.GLOBALID and C.GDB_FROM_DATE = G.MaxDate
WHERE jointlinebody = 'Joint'

