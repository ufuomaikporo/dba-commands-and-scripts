CONN ETP_IRASV6_TEST_OWNR/etp@ORA19C22

SET pagesize 0
SET rowprefetch 20000

ALTER SESSION SET sql_trace=TRUE;

select c.id as corporationid, c.corporationname, c.corporationaltname,
ou.id as operatingid, ou.operatingunitname, ou.operatingunitaltname,
mlvc.districtdivisiondomainid,
pls.id as pipelineid, pls.pipelinesystemname, pls.pipelinesystemaltname,
ll.id as lineid, ll.linename, ll.linealtname,
ds.id as dischargeid, ds.dischargesubsystemname, ds.dischargesubsystemaltname,
mlvs.id as sectionid, mlvs.mlvsectionname as sectionname
from lineloop ll
inner join stationseries ss on ss.lineloopid = ll.id
inner join mlvcorrection mlvc on mlvc.stationseriesid = ss.id
inner join mlvsection mlvs on mlvs.id = mlvc.mlvsectionid
inner join pipelinesystem pls on pls.id = ll.pipelinesystemid
inner join dischargesubsystem ds on pls.id = ds.pipelinesystemid and ss.dischargesubsystemid = ds.id
inner join operatingunit ou on ou.id = pls.operatingunitid
inner join corporation c on c.id = ou.corporationid
where ss.effectiveenddate is null
order by c.corporationname, ou.operatingunitname, pls.pipelinesystemname, ds.dischargesubsystemname, ll.linename,  mlvs.mlvsectionname;
/
                 

DRAS_IRASV6_DEV_DEMO_OWNR
DRAS_IRASV6_DEV_DE_DEMO_OWNR
DRAS_IRASV6_DATAEXCHANGE_OWNR		

Are ready to be tested on DRASORA19C		 
