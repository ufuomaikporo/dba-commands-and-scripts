SELECT DISTINCT
J.ASSETGROUP as FabricationType,
J.GLOBALID as sourceid,
J.engm as BeginStationNum, J.engm as EndStationNum,
J.diameter, J.wallthickness, J.isconnected,
J.gisid,
CASE J.isconnected
WHEN 0 THEN 'FALSE'
WHEN 1 THEN 'TRUE'
WHEN 2 THEN 'UNKNOWN'
END as fabricationConnectId, J.ASSETGROUP,
J.manufacturer,
P.GlobalId as StationSeriesId
FROM gas.pipelinejunction J
	INNER JOIN gas.P_ENGINEERINGNETWORK EN ON EN.ROUTEID = J.ENGROUTEID
	INNER JOIN gas.PIPELINELINE P ON EN.ROUTEID = P.routeid
WHERE
J.ASSETGROUP = 7 AND
P.AssetGroup in (3,20,2) and P.lifecyclestatus = 8 AND P.GDB_BRANCH_ID = 0 and P.GDB_IS_DELETE = 0
AND legacysystem is not null 
