USE PLAINS_IRASv6_STAGE

--#########################################################################################################
-- REACTIVATION CHECK
--#########################################################################################################

--SELECT ILIFStatusDomainID,
--	OperatorComment
----SELECT * FROM InlineInspectionFeature
--FROM InlineInspectionFeature
--where 
----InlineInspectionrangeid IN (3, 2730, 2732,
----2733, 2734, 2735, 2740, 2741, 2742
----) AND --Enter affected ranges 
--ILIFStatusDomainID in (
--		SELECT ld.id FROM DomainCatalogColXref x
--		INNER JOIN dbo.DomainCatalog AS DC ON dc.Id = x.domaincatalogid
--		INNER JOIN dbo.ListDomain AS LD ON ld.DomainCatalogId = dc.Id
--		WHERE TableName = 'InlineInspectionFeature'
--		AND ColumnName = 'ILIFStatusDomainID'
--		and ld.code= 'Inactive - from MDL'
--) 

--SELECT ILICAStatusDomainID, 
--		OperatorComment
----SELECT * FROM InlineInspectionCrackAnomaly
--FROM InlineInspectionCrackAnomaly
--where 
----InlineInspectionrangeid IN (3, 2730, 2732, 2733, 2734,
----2735, 2740, 2741, 2742
----) AND --Enter affected ranges
--iliCAStatusDomainID iN (
--		SELECT ld.id FROM DomainCatalogColXref x
--		INNER JOIN dbo.DomainCatalog AS DC ON dc.Id = x.domaincatalogid
--		INNER JOIN dbo.ListDomain AS LD ON ld.DomainCatalogId = dc.Id
--		WHERE TableName = 'InlineInspectionCrackAnomaly'
--		AND ColumnName = 'ILICAStatusDomainID'
--		and ld.code= 'Inactive - from MDL'
--)

--SELECT ILICBStatusDomainID, 
--		OperatorComment 
----SELECT * FROM InlineInspectionCrsnCallBox
--FROM InlineInspectionCrsnCallBox
--where 
----InlineInspectionrangeid IN (3, 2730, 2732, 2733, 2734,
----2735, 2740, 2741, 2742
----) AND --Enter affected ranges
--ILICBStatusDomainID iN (
--		SELECT ld.id FROM DomainCatalogColXref x
--		INNER JOIN dbo.DomainCatalog AS DC ON dc.Id = x.domaincatalogid
--		INNER JOIN dbo.ListDomain AS LD ON ld.DomainCatalogId = dc.Id
--		WHERE TableName = 'InlineInspectionCrackAnomaly'
--		AND ColumnName = 'ILICAStatusDomainID'
--		and ld.code= 'Inactive - from MDL'
--)

--SELECT ILINCDStatusDomainId, 
--		OperatorComment
----SELECT * FROM InlineInspectionNonCrsnDfct
--FROM InlineInspectionNonCrsnDfct
--where 
----InlineInspectionrangeid IN (3, 2730, 2732, 2733, 2734,
----2735, 2740, 2741, 2742
----) AND --Enter affected ranges
--ILINCDStatusDomainId iN (
--		SELECT ld.id FROM DomainCatalogColXref x
--		INNER JOIN dbo.DomainCatalog AS DC ON dc.Id = x.domaincatalogid
--		INNER JOIN dbo.ListDomain AS LD ON ld.DomainCatalogId = dc.Id
--		WHERE TableName = 'InlineInspectionCrackAnomaly'
--		AND ColumnName = 'ILICAStatusDomainID'
--		and ld.code= 'Inactive - from MDL'
--)

--########################################################################################################
-- DEACTIVATION CHECK
--########################################################################################################

SELECT ILIFStatusDomainID,
 OperatorComment 
FROM InlineInspectioNfeature
WHERE id IN (
SELECT t.featureid 
FROM (
SELECT DISTINCT t1.linename, t1.excavationsitename, t1.featureid, t1.code, t1.stationnum, digbegchain, digendchain, excavationdate, excavationreason 
,lastmoddatetime, digsize, round(abs(digbegchain - digendchain), 3) loadeddigsize
, ilifPeakdepthpct
FROM 
(
			SELECT distinct l.id, 
							l.linename, 
							ps.StationSeriesId, 
							ps.StationNum + bc.factornum featurechain, 
							ld.code,
							t.digbegchain, 
							t.digendchain,   
							t.excavationsitename,
							t.excavationsitedescription, 
							t.excavationdate,
							t.excavationreason, 
							t.inlineinspectionid, 
							t.BeginDistFromGirthWeld, 
							t.enddistfromgirthweld, 
							t.excavationtype, 
							t.digsize,
							ps.id AS featureid, 
							ps.ilifPeakdepthpct, 
							ps.lastmoddatetime, 
							ps.stationnum
			FROM InlineInspectionFeature PS 
			INNER JOIN StationSEries bs ON bs.Id = ps.StationSeriesId  AND bs.effectiveenddate IS null
			INNER JOIN MLVCorrection bC ON bc.StationSeriesId = bs.id
			INNER JOIN Lineloop l ON l.id = bs.lineloopid
			INNER JOIN ListDomain ld ON ld.id = ps.ilifstatusdomainid
			INNER JOIN InlineInspectionRange r ON r.id = ps.inlineinspectionrangeid  AND r.effectiveenddate IS null

			INNER JOIN (
							  SELECT distinct ps.id, ll.linename,  ps.BeginStationSeriesId, ps.BeginStationNum + bc.factornum AS digbegchain, ps.EndStationSeriesId, ps.EndStationNum + ec.factornum AS digendchain,
							  bs.BeginStationNum + bc.factornum AS begsschain, bs.EndStationNum + ec.factornum AS endsschain	
							  ,ps.excavationsitename, ps.excavationsitedescription, excavationdate,excavationreason
							  , ps.inlineinspectionid, ps.BeginDistFromGirthWeld, ps.enddistfromgirthweld, ld.code AS excavationtype, abs(ps.BeginDistFromGirthWeld -  ps.enddistfromgirthweld) AS digsize,
							  i.id as ili_id				 
				  
							  FROM ExcavationSite ps
							  INNER JOIN StationSEries bs ON bs.Id = ps.BeginStationSeriesId AND bs.effectiveenddate IS null
							  INNER JOIN StationSEries es ON es.Id = ps.EndStationSeriesID
							  INNER JOIN MLVCorrection  bC ON bc.StationSeriesId = bs.id
							  INNER JOIN MLVCorrection  eC ON ec.StationSeriesId = es.id
							  INNER JOIN LineLoop ll ON ll.id = bs.lineloopid
							  INNER JOIN ListDomain ld ON ld.id = ps.excavationTypeDomainid

							  INNER JOIN InlineInspection i ON i.id = ps.inlineinspectionid
							 -- WHERE ps.BeginStationSeriesId IN (SELECT id FROM StationSeries SS WHERE LineLoopId = 810002413)
							 /*where ps.beginstationseriesid in (
												 select id From stationseries where effectiveenddate is NULL
													AND lastmoddatetime >= '12-18-2019'
							 )*/
							   --where ll.id in (2, 171 )  -- Fill LineIDs Here

						) t on ps.stationseriesid = t.beginstationseriesid
						and (ps.StationNum + bc.factornum) >= t.digbegchain
						and (ps.StationNum + bc.factornum) <= t.digendchain
						--AND r.ilirstartdate < t.excavationdate

) t1
WHERE t1.code = 'Active'
--GROUP BY t1.linename, t1.excavationsitename, t1.digbegchain, t1.digendchain, t1.excavationdate, t1.excavationreason, t1.lastmoddatetime
) t
)

--SELECT ILICAStatusDomainID,
-- OperatorComment 
--FROM InlineInspectioNCrackAnomaly
--WHERE id IN 
--(
--			SELECT featureid FROM (
--			SELECT DISTINCT t1.linename, t1.excavationsitename, t1.featureid, t1.code, t1.stationnum, digbegchain, digendchain, excavationdate, excavationreason 
--			,lastmoddatetime, digsize, round(abs(digbegchain - digendchain), 3) loadeddigsize
--			, iliCAdepthpct
--			FROM 
--			(

--			SELECT distinct l.id, l.linename, ps.StationSeriesId, ps.StationNum + bc.factornum featurechain, 
--			ld.code,
--			t.digbegchain, t.digendchain,   t.excavationsitename,t.excavationsitedescription, t.excavationdate,t.excavationreason
--							  , t.inlineinspectionid, t.BeginDistFromGirthWeld, t.enddistfromgirthweld, t.excavationtype, t.digsize
--							  ,ps.id AS featureid, ps.iliCAdepthpct, ps.lastmoddatetime, ps.stationnum

--			FROM InlineInspectionCrackANomaly PS 
--			INNER JOIN StationSEries bs ON bs.Id = ps.StationSeriesId  AND bs.effectiveenddate IS null
--			INNER JOIN MLVCorrection bC ON bc.StationSeriesId = bs.id
--			INNER JOIN Lineloop l ON l.id = bs.lineloopid
--			INNER JOIN ListDomain ld ON ld.id = ps.iliCAstatusdomainid
--			INNER JOIN InlineInspectionRange r ON r.id = ps.inlineinspectionrangeid  AND r.effectiveenddate IS null

--			INNER JOIN (
--							  SELECT DISTINCT ps.id, ll.linename,  ps.BeginStationSeriesId, ps.BeginStationNum + bc.factornum AS digbegchain, ps.EndStationSeriesId, ps.EndStationNum + ec.factornum AS digendchain,
--							  bs.BeginStationNum + bc.factornum AS begsschain, bs.EndStationNum + ec.factornum AS endsschain	
--							  ,ps.excavationsitename, ps.excavationsitedescription, excavationdate,excavationreason
--							  , ps.inlineinspectionid, ps.BeginDistFromGirthWeld, ps.enddistfromgirthweld, ld.code AS excavationtype, abs(ps.BeginDistFromGirthWeld -  ps.enddistfromgirthweld) AS digsize,
--							  i.id as ili_id				 
				  
--							  FROM ExcavationSite ps
--							  INNER JOIN StationSEries bs ON bs.Id = ps.BeginStationSeriesId AND bs.effectiveenddate IS null
--							  INNER JOIN StationSEries es ON es.Id = ps.EndStationSeriesID
--							  INNER JOIN MLVCorrection  bC ON bc.StationSeriesId = bs.id
--							  INNER JOIN MLVCorrection  eC ON ec.StationSeriesId = es.id
--							  INNER JOIN LineLoop ll ON ll.id = bs.lineloopid
--							  INNER JOIN ListDomain ld ON ld.id = ps.excavationTypeDomainid

--							  INNER JOIN InlineInspection i ON i.id = ps.inlineinspectionid
--							 -- WHERE ps.BeginStationSeriesId IN (SELECT id FROM StationSeries SS WHERE LineLoopId = 810002413)
--							-- where ps.beginstationseriesid in (
--							--					 select id From stationseries where effectiveenddate is NULL
--							--						AND lastmoddatetime >= '12-18-2019'
--							-- )
--							 --where ll.id in (2, 171)   /*Fill LineIDs here*/
--) t on ps.stationseriesid = t.beginstationseriesid
--and (ps.StationNum + bc.factornum) >= t.digbegchain
--and (ps.StationNum + bc.factornum) <= t.digendchain
----AND r.ilirstartdate < t.excavationdate

--) t1
--WHERE t1.code = 'Active'
----GROUP BY t1.linename, t1.excavationsitename, t1.digbegchain, t1.digendchain, t1.excavationdate, t1.excavationreason, t1.lastmoddatetime

--) t
--)

--SELECT ILICBStatusDomainID ,
-- OperatorComment 
--FROM InlineInspectionCrsnCallBox
--WHERE id IN (
--SELECT t.featureid FROM (
--SELECT DISTINCT t1.linename, t1.excavationsitename, t1.featureid, t1.code, t1.stationnum, digbegchain, digendchain, excavationdate, excavationreason 
--,lastmoddatetime, digsize, round(abs(digbegchain - digendchain), 3) loadeddigsize
----, ilifPeakdepthpct
--FROM 
--(
--			SELECT distinct l.id, l.linename, ps.StationSeriesId, ps.StationNum + bc.factornum featurechain, 
--			ld.code,
--			t.digbegchain, t.digendchain,   t.excavationsitename,t.excavationsitedescription, t.excavationdate,t.excavationreason
--							  , t.inlineinspectionid, t.BeginDistFromGirthWeld, t.enddistfromgirthweld, t.excavationtype, t.digsize
--							  ,ps.id AS featureid, --ps.ilifPeakdepthpct, 
--							  ps.lastmoddatetime, ps.stationnum

--			FROM InlineInspectionCrsnCallBox PS 
--			INNER JOIN StationSEries bs ON bs.Id = ps.StationSeriesId  AND bs.effectiveenddate IS null
--			INNER JOIN MLVCorrection bC ON bc.StationSeriesId = bs.id
--			INNER JOIN Lineloop l ON l.id = bs.lineloopid
--			INNER JOIN ListDomain ld ON ld.id = ps.ILICBStatusDomainID
--			INNER JOIN InlineInspectionRange r ON r.id = ps.inlineinspectionrangeid  AND r.effectiveenddate IS null

--			INNER JOIN (
--							  SELECT DISTINCT ps.id, ll.linename,  ps.BeginStationSeriesId, ps.BeginStationNum + bc.factornum AS digbegchain, ps.EndStationSeriesId, ps.EndStationNum + ec.factornum AS digendchain,
--							  bs.BeginStationNum + bc.factornum AS begsschain, bs.EndStationNum + ec.factornum AS endsschain	
--							  ,ps.excavationsitename, ps.excavationsitedescription, excavationdate,excavationreason
--							  , ps.inlineinspectionid, ps.BeginDistFromGirthWeld, ps.enddistfromgirthweld, ld.code AS excavationtype, abs(ps.BeginDistFromGirthWeld -  ps.enddistfromgirthweld) AS digsize,
--							  i.id as ili_id				 
				  
--							  FROM ExcavationSite ps
--							  INNER JOIN StationSEries bs ON bs.Id = ps.BeginStationSeriesId AND bs.effectiveenddate IS null
--							  INNER JOIN StationSEries es ON es.Id = ps.EndStationSeriesID
--							  INNER JOIN MLVCorrection  bC ON bc.StationSeriesId = bs.id
--							  INNER JOIN MLVCorrection  eC ON ec.StationSeriesId = es.id
--							  INNER JOIN LineLoop ll ON ll.id = bs.lineloopid
--							  INNER JOIN ListDomain ld ON ld.id = ps.excavationTypeDomainid

--							  INNER JOIN InlineInspection i ON i.id = ps.inlineinspectionid
--							 -- WHERE ps.BeginStationSeriesId IN (SELECT id FROM StationSeries SS WHERE LineLoopId = 810002413)
--							 /*where ps.beginstationseriesid in (
--												 select id From stationseries where effectiveenddate is NULL
--													AND lastmoddatetime >= '12-18-2019'
--							 )*/
--							   --where ll.id in (2, 171 )  -- Fill LineIDs Here

--) t on ps.stationseriesid = t.beginstationseriesid
--and (ps.StationNum + bc.factornum) >= t.digbegchain
--and (ps.StationNum + bc.factornum) <= t.digendchain
----AND r.ilirstartdate < t.excavationdate

--) t1
--WHERE t1.code = 'Active'
----GROUP BY t1.linename, t1.excavationsitename, t1.digbegchain, t1.digendchain, t1.excavationdate, t1.excavationreason, t1.lastmoddatetime
--) t
--)

--SELECT ILINCDStatusDomainId,
-- OperatorComment 
--FROM InlineInspectionNonCrsnDfct
--WHERE id IN (
--SELECT DISTINCT t.featureid FROM (
--SELECT DISTINCT t1.linename, t1.excavationsitename, t1.featureid, t1.code, t1.stationnum, digbegchain, digendchain, excavationdate, excavationreason 
--,lastmoddatetime, digsize, round(abs(digbegchain - digendchain), 3) loadeddigsize
----, ilifPeakdepthpct
--FROM 
--(
--			SELECT distinct l.id, l.linename, ps.StationSeriesId, ps.StationNum + bc.factornum featurechain, 
--			ld.code,
--			t.digbegchain, t.digendchain,   t.excavationsitename,t.excavationsitedescription, t.excavationdate,t.excavationreason
--							  , t.inlineinspectionid, t.BeginDistFromGirthWeld, t.enddistfromgirthweld, t.excavationtype, t.digsize
--							  ,ps.id AS featureid, --ps.ilifPeakdepthpct, 
--							  ps.lastmoddatetime, ps.stationnum

--			FROM InlineInspectionNonCrsnDfct PS 
--			INNER JOIN StationSEries bs ON bs.Id = ps.StationSeriesId  AND bs.effectiveenddate IS null
--			INNER JOIN MLVCorrection bC ON bc.StationSeriesId = bs.id
--			INNER JOIN Lineloop l ON l.id = bs.lineloopid
--			INNER JOIN ListDomain ld ON ld.id = ps.ILINCDStatusDomainId
--			INNER JOIN InlineInspectionRange r ON r.id = ps.inlineinspectionrangeid  AND r.effectiveenddate IS null

--			INNER JOIN (
--							  SELECT DISTINCT ps.id, ll.linename,  ps.BeginStationSeriesId, ps.BeginStationNum + bc.factornum AS digbegchain, ps.EndStationSeriesId, ps.EndStationNum + ec.factornum AS digendchain,
--							  bs.BeginStationNum + bc.factornum AS begsschain, bs.EndStationNum + ec.factornum AS endsschain	
--							  ,ps.excavationsitename, ps.excavationsitedescription, excavationdate,excavationreason
--							  , ps.inlineinspectionid, ps.BeginDistFromGirthWeld, ps.enddistfromgirthweld, ld.code AS excavationtype, abs(ps.BeginDistFromGirthWeld -  ps.enddistfromgirthweld) AS digsize,
--							  i.id as ili_id				 
				  
--							  FROM ExcavationSite ps
--							  INNER JOIN StationSEries bs ON bs.Id = ps.BeginStationSeriesId AND bs.effectiveenddate IS null
--							  INNER JOIN StationSEries es ON es.Id = ps.EndStationSeriesID
--							  INNER JOIN MLVCorrection  bC ON bc.StationSeriesId = bs.id
--							  INNER JOIN MLVCorrection  eC ON ec.StationSeriesId = es.id
--							  INNER JOIN LineLoop ll ON ll.id = bs.lineloopid
--							  INNER JOIN ListDomain ld ON ld.id = ps.excavationTypeDomainid

--							  INNER JOIN InlineInspection i ON i.id = ps.inlineinspectionid
--							 -- WHERE ps.BeginStationSeriesId IN (SELECT id FROM StationSeries SS WHERE LineLoopId = 810002413)
--							 /*where ps.beginstationseriesid in (
--												 select id From stationseries where effectiveenddate is NULL
--													AND lastmoddatetime >= '12-18-2019'
--							 )*/
--							   --where ll.id in (2, 171 )  -- Fill LineIDs Here

--) t on ps.stationseriesid = t.beginstationseriesid
--and (ps.StationNum + bc.factornum) >= t.digbegchain
--and (ps.StationNum + bc.factornum) <= t.digendchain
----AND r.ilirstartdate < t.excavationdate

--) t1
--WHERE t1.code = 'Active'
----GROUP BY t1.linename, t1.excavationsitename, t1.digbegchain, t1.digendchain, t1.excavationdate, t1.excavationreason, t1.lastmoddatetime
--) t
--)
