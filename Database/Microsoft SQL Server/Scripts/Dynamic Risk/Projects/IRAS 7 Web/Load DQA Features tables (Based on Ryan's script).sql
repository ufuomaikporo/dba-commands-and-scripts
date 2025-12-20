select TOP 100 * from DATASHARE.dbo.InlineInspectionRange
SELECT top 10
       i.Client_Code,
       i.Id InlineInspectionId,
       i.ILIName,
       i.ILIDescr,
       i.MeasuredFrom,
       i.ILIReportReceivedDate ILIReportDate,
       i.ILIStartDate ILIDate,
	   com.Code,
	   iliv.IH_CompanyName ILIVendor,
       tt.Code ILIToolType,
	   ilit.IsCrackTool,
	   ilit.IsMetalLossTool,
	   ilit.IsGeometryTool,
	   ilis.IH_Standard AS ILIStatus,
       r.ILIRStartOdometer,
       r.ILIREndOdometer
FROM DATASHARE.dbo.InlineInspection i
    INNER JOIN
    (
        SELECT r.Client_Code,
               r.InlineInspectionId,
               MIN(r.ILIRStartOdometer) ILIRStartOdometer,
               MAX(r.ILIREndOdometer) ILIREndOdometer
        FROM DATASHARE.dbo.InlineInspectionRange r
        WHERE r.EffectiveEndDate IS NULL
        GROUP BY r.Client_Code,
                 r.InlineInspectionId
    ) r
        ON r.Client_Code = i.Client_Code
           AND r.InlineInspectionId = i.Id
    LEFT JOIN DATASHARE.dbo.ListDomain tt
        ON tt.Client_Code = i.Client_Code
           AND i.ILITypeDomainId = tt.Id
    LEFT JOIN DATASHARE.dbo.ListDomain st
        ON st.Client_Code = i.Client_Code
           AND i.ILIStatusDomainId = st.Id
    LEFT JOIN DATASHARE.dbo.ListDomain com
        ON com.Client_Code = i.Client_Code
           AND i.ILICompanyDomainId = com.Id
	LEFT JOIN dbo.ILIVendor_Library iliv
		ON iliv.CompanyName = com.Code 
	LEFT JOIN dbo.ILITool_Library ilit
		ON ilit.ILIToolDomainId = tt.Code
	LEFT JOIN dbo.ILIStatus_Library ilis
		ON ilis.ILIStatusCode = st.Code
GO

return
select * from sys.tables where name like '%library%'
select * from ILIVendor_Library
select * from ILITool_Library
select * from ILIStatus_Library

INSERT INTO ILIStatus_Library (ILIStatusCode, Client_Code, Count, IH_Standard)
VALUES ('Inactive - SME', 'multiple', 3, 'Unknown')


select * from DATASHARE.dbo.ListDomain where Code = 'Inactive - SME'
/*
--drop table ILIStatus_Library
drop table ILIStatusCode

--CREATE OR ALTER PROCEDURE Load_DQA_IH_ILICorrosion
--AS
--BEGIN
--	INSERT INTO dbo.DQA_IH_ILICorrosion
--	(
--		Client_Code,
--		LineName,
--		LineLoopId,
--		FeatureId,
--		FeatureNum,
--		FeatureGUID,
--		Chainage,
--		ILIOdometer,
--		ILIToolType,
--		ILIDate,
--		InlineInspectionId,
--		InlineInspectionRangeId,
--		FeatureClass,
--		FeatureType_Original,
--		FeatureType_Standard,
--		FeatureStatus,
--		USGirthWeldNum,
--		DistFromUSGW,
--		DSGirthWeldNum,
--		DistFromDSGW,
--		DepthPct,
--		GrowthRate,
--		FeatureLength,
--		FeatureWidth,
--		FeatureOrientation,
--		SurfaceInd,
--		FailurePressure,
--		RupturePressureRatio,
--		FPR,
--		FPRtc,
--		POERupture,
--		POELeak,
--		ERF,
--		Latitude,
--		Longitude,
--		FeatureZ
--	)
--	SELECT tbl.Client_Code,
--		   l.LineName,
--		   s.LineLoopId,
--		   tbl.Id FeatureId,
--		   tbl.ILIFFeatureNumber,
--		   NEWID() FeatureGUID,
--		   tbl.StationNum * mc.MultiplierNum + mc.FactorNum Chainage,
--		   tbl.ILIFOdometer,
--		   tt.Code ILIToolType,
--		   CAST(r.ILIRStartDate AS DATE) ILIDate,
--		   r.InlineInspectionId,
--		   tbl.InlineInspectionRangeId,
--		   'Corrosion' FeatureClass,
--		   ft.Code FeatureType_Original,
--		   CASE
--			   WHEN ft.Code IN ( 'Manufacturing Anomaly', 'Metal Loss', 'MetalLoss', 'External Metal Loss',
--								 'Metal Loss - Ext', 'General Corrosion', 'General Metal Loss',
--								 'Internal general corrosion', 'Metal Loss - GEN', 'External general corrosion',
--								 'Metal Loss - Ext, GEN', 'Metal Loss - Int, GEN', 'INTERNAL METAL LOSS',
--								 'Metal Loss - Int', 'Internal pitting corrosion', 'External pitting corrosion'
--							   ) THEN
--				   'ML'
--			   WHEN ft.Code IN ( 'Manufacturing Anomaly' ) THEN
--				   'MF'
--			   WHEN ft.Code IN ( 'Metal Loss with Crack' ) THEN
--				   'ML-C'
--			   WHEN ft.Code IN ( 'Corrosion with Deformation', 'Metal Loss - w/DEF', 'MLOS w Deformation' ) THEN
--				   'ML-DF'
--			   WHEN ft.Code IN ( 'Girth Weld Anomaly', 'Corrosion affecting Girth Weld', 'Metal Loss - GW',
--								 'MetalLossOnGirthWeld'
--							   ) THEN
--				   'ML-GW'
--			   WHEN ft.Code IN ( 'Longitudinal Weld Feature', 'Corrosion affecting long seam',
--								 'Corrosion Affecting Long. Seam', 'Corrosion Affecting Pipe Seam', 'Long. Seam Corrosion',
--								 'Metal Loss - LS', 'MetalLossOnSeamWeld'
--							   ) THEN
--				   'ML-LS'
--			   WHEN ft.Code IN ( 'Metal Loss - Manufacturing', 'Metal loss manufacturing',
--								 'Metal Loss Manufacturing Anomaly'
--							   ) THEN
--				   'ML-MF'
--			   WHEN ft.Code IN ( 'Spiral Seam Corrosion' ) THEN
--				   'ML-SP'
--			   WHEN ft.Code IN ( 'Metal Loss - at Wrinkle Bend' ) THEN
--				   'ML-WB'
--			   ELSE
--				   'Unknown'
--		   END FeatureType_Standard,
--		   CASE
--			   WHEN fs.Code = 'Active' THEN
--				   'Active'
--			   WHEN fs.Code IS NULL THEN
--				   'Active'
--			   ELSE
--				   'Inactive'
--		   END FeatureStatus,
--		   tbl.ILIFGirthWeldNum USGirthWeldNum,
--		   tbl.ILIFDistanceFromGirthWeld DistFromUSGW,
--		   tbl.ILIFGirthWeldNumDS DSGirthWeldNum,
--		   tbl.ILIFDistanceFromGirthWeldDS DistFromDSGW,
--		   tbl.ILIFPeakDepthPct DepthPct,
--		   tbl.GrowthRate,
--		   tbl.ILIFLength FeatureLength,
--		   tbl.ILIFWidth FeatureWidth,
--		   tbl.ILIFOrientation FeatureOrientation,
--		   TRIM(tbl.ILIFSurfaceInd) SurfaceInd,
--		   tbl.ILIFFailurePressure FailurePressure,
--		   tbl.ILIFRupturePressureRatio RupturePressureRatio,
--		   tbl.ILIFFPR FPR,
--		   tbl.ILIFFPRtc FPRtc,
--		   tbl.ILIFPOERupture POERupture,
--		   tbl.ILIFPOELeak POELeak,
--		   tbl.ILIFERF ERF,
--		   tbl.ILIFLatitude Latitude,
--		   tbl.ILIFLongitude Longitude,
--		   tbl.ILIFZ FeatureZ
--	FROM DATASHARE.dbo.InlineInspectionFeature tbl
--		LEFT JOIN DATASHARE.dbo.ListDomain fs
--			ON fs.Client_Code = tbl.Client_Code
--			   AND fs.Id = tbl.ILIFStatusDomainId
--		LEFT JOIN DATASHARE.dbo.ListDomain ft
--			ON ft.Client_Code = tbl.Client_Code
--			   AND ft.Id = tbl.ILIFTypeDomainId
--		INNER JOIN DATASHARE.dbo.InlineInspectionRange r
--			ON tbl.Client_Code = r.Client_Code
--			   AND r.Id = tbl.InlineInspectionRangeId
--		LEFT JOIN DATASHARE.dbo.ListDomain tt
--			ON tt.Client_Code = tbl.Client_Code
--			   AND tt.Id = r.ILIRToolDomainId
--		INNER JOIN DATASHARE.dbo.InlineInspection i
--			ON i.Client_Code = tbl.Client_Code
--			   AND i.Id = r.InlineInspectionId
--		LEFT JOIN DATASHARE.dbo.StationSeries s
--			ON s.Client_Code = tbl.Client_Code
--			   AND s.Id = tbl.StationSeriesId
--		LEFT JOIN
--		(
--			SELECT DISTINCT
--				   StationSeriesId,
--				   FactorNum,
--				   MultiplierNum,
--				   Client_Code
--			FROM DATASHARE.dbo.MLVCorrection
--		) mc
--			ON mc.Client_Code = tbl.Client_Code
--			   AND mc.StationSeriesId = s.Id
--		LEFT JOIN DATASHARE.dbo.LineLoop l
--			ON l.Client_Code = tbl.Client_Code
--			   AND l.Id = s.LineLoopId;
--END
--GO

--CREATE OR ALTER PROCEDURE Load_DQA_IH_ILICrack
--BEGIN
--INSERT INTO dbo.DQA_IH_ILICrack
--(
--    Client_Code,
--    LineName,
--    LineLoopId,
--    FeatureId,
--    FeatureNum,
--    FeatureGUID,
--    Chainage,
--    ILIOdometer,
--    ILIToolType,
--    ILIDate,
--    InlineInspectionId,
--    InlineInspectionRangeId,
--    FeatureClass,
--    FeatureType_Original,
--    FeatureType_Standard,
--    FeatureStatus,
--    USGirthWeldNum,
--    DistFromUSGW,
--    DSGirthWeldNum,
--    DistFromDSGW,
--    DepthPct,
--    GrowthRate,
--    FeatureLength,
--    FeatureWidth,
--    FeatureOrientation,
--    SurfaceInd,
--    FailurePressure,
--    RupturePressureRatio,
--    FPR,
--    FPRtc,
--    POERupture,
--    POELeak,
--    ERF,
--    Latitude,
--    Longitude,
--    FeatureZ
--)
--SELECT tbl.Client_Code,
--       l.LineName,
--       s.LineLoopId,
--       tbl.Id FeatureId,
--       tbl.ILICAAnomalyNumber,
--       NEWID() FeatureGUID,
--       tbl.StationNum * mc.MultiplierNum + mc.FactorNum Chainage,
--       tbl.ILICAOdometer,
--       tt.Code ILIToolType,
--       CAST(r.ILIRStartDate AS DATE) ILIDate,
--       r.InlineInspectionId,
--       tbl.InlineInspectionRangeId,
--       'Crack' FeatureClass,
--       ft.Code FeatureType_Original,
--       CASE
--           WHEN ft.Code IN ( '<12.5%', '>40%', '12.5%-25.0%', '20-40', '25.0%-40.0%', '40-60',
--                             'Axial Crack - Base Pipe Material', 'Crack', 'Crack - EMAT', 'Crack_Category_3',
--                             'Crack_Category_4', 'NCD; CRACK', 'ANOM - A', 'ANOM - B', 'Notch-like'
--                           ) THEN
--               'C'
--           WHEN ft.Code IN ( 'Axial Crack - Longitudinal Weld Area', 'Crack on Long seam', 'Crack-Seam' ) THEN
--               'C-LS'
--           WHEN ft.Code IN ( 'Crack on girth weld' ) THEN
--               'C-GW'
--           WHEN ft.Code IN ( 'Axial Crack Colony - Base Pipe Material', 'Below Spec Crack Field', 'Crack Field',
--                             'Crack-Colony', 'Crack-Field', 'SCC', 'Circumferential Crack-Field'
--                           ) THEN
--               'CF'
--           WHEN ft.Code IN ( 'Below Spec Crack Field Adj To Seam', 'Crack Field Adj To Seam',
--                             'Crack Field at Long Seam'
--                           ) THEN
--               'CF-LS'
--           WHEN ft.Code IN ( 'Crack Field Adj To GirthWeld' ) THEN
--               'CF-GW'
--           WHEN ft.Code IN ( 'Below Spec Crack Like', 'Crack Like', 'Crack-Like', 'Circumferential Crack-Like' ) THEN
--               'CL'
--           WHEN ft.Code IN ( 'Below Spec Crack Like Adj to Seam', 'Crack Like Adj to Seam', 'Crack-Like Seam' ) THEN
--               'CL-LS'
--           WHEN ft.Code IN ( 'Below Spec Crack Like Adj to Girth Weld', 'Crack Like Adj to Girth Weld',
--                             'Circumferential Crack-Like at GW'
--                           ) THEN
--               'CL-GW'
--           WHEN ft.Code IN ( 'Weld Anomaly', 'Weld-Anomaly', 'LWFE - A', 'LWFE - B', 'Below Spec Weld Anomaly',
--                             'Girth Weld Anomaly', 'Long Seam Weld Anomaly', 'Weld Anomoly',
--                             'Surface Breaking Lamination'
--                           ) THEN
--               'LI'
--           ELSE
--               'Unknown'
--       END FeatureType_Standard,
--       CASE
--           WHEN fs.Code = 'Active' THEN
--               'Active'
--           WHEN fs.Code IS NULL THEN
--               'Active'
--           ELSE
--               'Inactive'
--       END FeatureStatus,
--       tbl.ILICAGirthWeldNum USGirthWeldNum,
--       tbl.ILICADistanceFromGirthWeld DistFromUSGW,
--       tbl.ILICAGirthWeldNumDS DSGirthWeldNum,
--       tbl.ILICADistanceFromGirthWeldDS DistFromDSGW,
--       tbl.ILICADepthPct DepthPct,
--       tbl.GrowthRate,
--       tbl.ILICALength FeatureLength,
--       tbl.ILICAWidth FeatureWidth,
--       tbl.ILICAOrientation FeatureOrientation,
--       TRIM(tbl.ILICASurfaceInd) SurfaceInd,
--       tbl.ILICAFailurePressure FailurePressure,
--       tbl.ILICARupturePressureRatio RupturePressureRatio,
--       tbl.ILICAFPR FPR,
--       tbl.ILICAFPRtc FPRtc,
--       tbl.POE POERupture,
--       NULL POELeak,
--       NULL ERF,
--       tbl.ILICALatitude Latitude,
--       tbl.ILICALongitude Longitude,
--       tbl.ILICAZ FeatureZ
--FROM DATASHARE.dbo.InlineInspectionCrackAnomaly tbl
--    LEFT JOIN DATASHARE.dbo.ListDomain fs
--        ON fs.Client_Code = tbl.Client_Code
--           AND fs.Id = tbl.ILICAStatusDomainId
--    LEFT JOIN DATASHARE.dbo.ListDomain ft
--        ON ft.Client_Code = tbl.Client_Code
--           AND ft.Id = tbl.ILICATypeDomainId
--    INNER JOIN DATASHARE.dbo.InlineInspectionRange r
--        ON tbl.Client_Code = r.Client_Code
--           AND r.Id = tbl.InlineInspectionRangeId
--    LEFT JOIN DATASHARE.dbo.ListDomain tt
--        ON tt.Client_Code = tbl.Client_Code
--           AND tt.Id = r.ILIRToolDomainId
--    INNER JOIN DATASHARE.dbo.InlineInspection i
--        ON i.Client_Code = tbl.Client_Code
--           AND i.Id = r.InlineInspectionId
--    LEFT JOIN DATASHARE.dbo.StationSeries s
--        ON s.Client_Code = tbl.Client_Code
--           AND s.Id = tbl.StationSeriesId
--    LEFT JOIN
--    (
--        SELECT DISTINCT
--               StationSeriesId,
--               FactorNum,
--               MultiplierNum,
--               Client_Code
--        FROM DATASHARE.dbo.MLVCorrection
--    ) mc
--        ON mc.Client_Code = tbl.Client_Code
--           AND mc.StationSeriesId = s.Id
--    LEFT JOIN DATASHARE.dbo.LineLoop l
--        ON l.Client_Code = tbl.Client_Code
--           AND l.Id = s.LineLoopId;
--END
--GO

--CREATE OR ALTER PROCEDURE Load_DQA_IH_ILINCD
--BEGIN
--	INSERT INTO dbo.DQA_IH_ILINCD
--(
--    Client_Code,
--    LineName,
--    LineLoopId,
--    FeatureId,
--    FeatureNum,
--    FeatureGUID,
--    Chainage,
--    ILIOdometer,
--    ILIToolType,
--    ILIDate,
--    InlineInspectionId,
--    InlineInspectionRangeId,
--    FeatureClass,
--    FeatureType_Original,
--    FeatureType_Standard,
--    FeatureStatus,
--    USGirthWeldNum,
--    DistFromUSGW,
--    DSGirthWeldNum,
--    DistFromDSGW,
--    DepthPct,
--    GrowthRate,
--    FeatureLength,
--    FeatureWidth,
--    FeatureOrientation,
--    SurfaceInd,
--    FailurePressure,
--    RupturePressureRatio,
--    FPR,
--    FPRtc,
--    POERupture,
--    POELeak,
--    ERF,
--    Latitude,
--    Longitude,
--    FeatureZ
--)
--SELECT tbl.Client_Code,
--       l.LineName,
--       s.LineLoopId,
--       tbl.Id FeatureId,
--       tbl.ILINCDFeatureNumber,
--       NEWID() FeatureGUID,
--       tbl.StationNum * mc.MultiplierNum + mc.FactorNum Chainage,
--       tbl.ILINCDOdometer,
--       tt.Code ILIToolType,
--       CAST(r.ILIRStartDate AS DATE) ILIDate,
--       r.InlineInspectionId,
--       tbl.InlineInspectionRangeId,
--       'NCD' FeatureClass,
--       ft.Code FeatureType_Original,
--       CASE
--           WHEN ft.Code IN ( 'Attachment', 'TEEINDICATION' ) THEN
--               'Attachment'
--           WHEN ft.Code IN ( 'Pipe Strain', 'STRAIN' ) THEN
--               'Bending Strain'
--           WHEN ft.Code IN ( 'Cracking' ) THEN
--               'Crack'
--           WHEN ft.Code IN ( 'Debris' ) THEN
--               'Debris'
--           WHEN ft.Code IN ( 'Deformation', 'Deformation - Flat', 'Deformation - Other', 'Deformation - Sharp',
--                             'Deformation - Stress Riser', 'Dent', 'Dent - Flat', 'Dent - Other', 'Dent - Sharp',
--                             'Mechanical', 'Possible Dent', 'ID Anomaly', 'ID Anomaly / <2%', 'ID anomaly-<2%',
--                             'Possible ID anomaly', 'Deformation at Stress Riser'
--                           ) THEN
--               'DF'
--           WHEN ft.Code IN ( 'DEFORMATION OVALITY', 'Ovality', 'OVALITY10', 'ID Anomaly / Ovality' ) THEN
--               'DF-OV'
--           WHEN ft.Code IN ( 'Dent with multiple peaks', 'DentWithMultiplePeaks', 'Double Dent' ) THEN
--               'DF-MULTI'
--           WHEN ft.Code IN ( 'Dent(ML)', 'DEFORMATION W/ METAL LOSS', 'Deformation With Metal Loss', 'Dent - w/ML',
--                             'DENT (ML) - WITH ASSOC. ML < 10%', 'Dent w/ Metal Loss', 'Dent with MetalLoss < 10%',
--                             'DentWithMetalLoss'
--                           ) THEN
--               'DF-ML'
--           WHEN ft.Code IN ( 'Mechanical w/Metal Loss' ) THEN
--               'MF-ML'
--           WHEN ft.Code IN ( 'Dent with crack', 'DentWithCrack', 'Deformation with Crack' ) THEN
--               'DF-Crack'
--           WHEN ft.Code IN ( 'Dent with gouge', 'DentWithGouge', 'Deformation with Gouge' ) THEN
--               'DF-Gouge'
--           WHEN ft.Code IN ( 'Deformation at Girth Weld', 'Dent - at GW', 'DentOnGirthWeld' ) THEN
--               'DF-GW'
--           WHEN ft.Code IN ( 'DEFORMATION OVALITY on GWD', 'DEFORMATION OVALITY on SWD' ) THEN
--               'DF-OV-GW'
--           WHEN ft.Code IN ( 'Deformation - Weld', 'Deformation on Long Seam', 'Dent - at Weld', 'Dent - on LS',
--                             'DentOnLongSeam'
--                           ) THEN
--               'DF-LS'
--           WHEN ft.Code IN ( 'DentOnGirthWeldLongSeamOrSeamWeld' ) THEN
--               'DF-GW-LS'
--           WHEN ft.Code IN ( 'DEFORMATION DENTS  on SPW' ) THEN
--               'DF-SP'
--           WHEN ft.Code IN ( 'DEFORMATION OVALITY  on SPW' ) THEN
--               'DF-OV-SP'
--           WHEN ft.Code IN ( 'DEFORMATION WRINKLE' ) THEN
--               'DF-WR'
--           WHEN ft.Code IN ( 'DeformationWithMetalLossOnGirthWeld', 'DentWithMetalLossOnGirthWeld',
--                             'GMA w/ ML at Girth Weld'
--                           ) THEN
--               'DF-ML-GW'
--           WHEN ft.Code IN ( 'DeformationWithMetalLossOnLongSeam', 'DentWithMetalLossOnLongSeam' ) THEN
--               'DF-ML-LS'
--           WHEN ft.Code IN ( 'Metal Loss-Possible Girth Weld Feature' ) THEN
--               'GWA-ML'
--           WHEN ft.Code IN ( 'Wrinkle Bends w/ ML' ) THEN
--               'ML-WB'
--           WHEN ft.Code IN ( 'Gouge' ) THEN
--               'Gouge'
--           WHEN ft.Code IN ( 'Groove' ) THEN
--               'Groove'
--           WHEN ft.Code IN ( 'WELD' ) THEN
--               'GW'
--           WHEN ft.Code IN ( 'Heavy GW', 'Heavy Weld' ) THEN
--               'GW-Heavy'
--           WHEN ft.Code IN ( 'HardSpot', 'Repaired Hardspot', 'Hard Spot' ) THEN
--               'HS'
--           WHEN ft.Code IN ( 'Girth Weld Anomaly', 'Girth Weld Feature' ) THEN
--               'GWA'
--           WHEN ft.Code IN ( 'CLOSE METAL OBJECT', 'CLOSE METAL OBJECT W/ML', 'Extra Metal',
--                             'Extra metal / Possible extra metal', 'Extra Metal / Unknown', 'Extra Metal Weld defect',
--                             'Gain', 'Metal Gain Object'
--                           ) THEN
--               'Metal Gain'
--           WHEN ft.Code IN ( 'Construction Feature', 'External MFG', 'Inclusion', 'Internal MFG', 'Lamination',
--                             'Manufacturing Anomaly', 'Manufacturing Feature', 'Manufacturing Indication',
--                             'Metal Loss-Milling Feature', 'Mill Anomaly', 'Mill Defect', 'Mill Related',
--                             'Milling Feature', 'Possible manufacturing feature', 'Lamination associated with weld',
--                             'Manufacturing', 'Mill Feature'
--                           ) THEN
--               'MF'
--           WHEN ft.Code IN ( 'EXTERNAL METAL LOSS', 'Metal Loss', 'Metal Loss - Unsized', 'Metal Loss Repaired' ) THEN
--               'ML'
--           WHEN ft.Code IN ( 'P. FEATURE A', 'P. FEATURE B', 'Possible Feature A', 'INDICATION',
--                             'Non Metal Loss Anomaly'
--                           ) THEN
--               'NCD'
--           WHEN ft.Code IN ( 'Long Seam Anomaly', 'Long Seam Indication', 'Long Seam Related',
--                             'Longitudinal Weld Defect', 'Longitudinal Weld Feature', 'Non Corrosion Defect Near Weld',
--                             'Possible Weld Defect', 'Possible Weld Indication', 'Seam Weld Anomaly', 'Weld anomaly',
--                             'Weld Indication', 'Long Seam Weld Anomaly'
--                           ) THEN
--               'NCD-LS'
--           WHEN ft.Code IN ( 'Notch-Like Anomaly' ) THEN
--               'Notch-Like'
--           WHEN ft.Code IN ( 'PUDDLE WELD' ) THEN
--               'Puddle-Weld'
--           WHEN ft.Code IN ( 'MAIN LINE VALVE|AGMSHARP' ) THEN
--               'VALVE'
--           WHEN ft.Code IN ( 'Buckles', 'Buckle' ) THEN
--               'BU'
--           WHEN ft.Code IN ( 'Ripple', 'Wrinkle' ) THEN
--               'WR'
--           WHEN ft.Code IN ( 'RippleOrWrinkleOrBuckle', 'Wrinkle Bends' ) THEN
--               'WB'
--           ELSE
--               'Unknown'
--       END AS FeatureType_Standard,
--       CASE
--           WHEN fs.Code = 'Active' THEN
--               'Active'
--           WHEN fs.Code IS NULL THEN
--               'Active'
--           ELSE
--               'Inactive'
--       END FeatureStatus,
--       tbl.ILINCDGirthWeldNum USGirthWeldNum,
--       tbl.ILINCDDistanceFromGirthWeld DistFromUSGW,
--       tbl.ILINCDGirthWeldNumDS DSGirthWeldNum,
--       tbl.ILINCDDistanceFromGirthWeldDS DistFromDSGW,
--       tbl.ILINCDDepthPctNPS DepthPct,
--       NULL GrowthRate,
--       tbl.ILINCDLength FeatureLength,
--       tbl.ILINCDWidth FeatureWidth,
--       tbl.ILINCDOrientation FeatureOrientation,
--       TRIM(tbl.ILINCDSurfaceInd) SurfaceInd,
--       NULL FailurePressure,
--       NULL RupturePressureRatio,
--       NULL FPR,
--       NULL FPRtc,
--       NULL POERupture,
--       NULL POELeak,
--       NULL ERF,
--       tbl.ILINCDLatitude Latitude,
--       tbl.ILINCDLongitude Longitude,
--       tbl.ILINCDZ FeatureZ
--FROM DATASHARE.dbo.InlineInspectionNonCrsnDfct tbl
--    LEFT JOIN DATASHARE.dbo.ListDomain fs
--        ON fs.Client_Code = tbl.Client_Code
--           AND fs.Id = tbl.ILINCDStatusDomainId
--    LEFT JOIN DATASHARE.dbo.ListDomain ft
--        ON ft.Client_Code = tbl.Client_Code
--           AND ft.Id = tbl.ILINCDTypeDomainId
--    INNER JOIN DATASHARE.dbo.InlineInspectionRange r
--        ON tbl.Client_Code = r.Client_Code
--           AND r.Id = tbl.InlineInspectionRangeId
--    LEFT JOIN DATASHARE.dbo.ListDomain tt
--        ON tt.Client_Code = tbl.Client_Code
--           AND tt.Id = r.ILIRToolDomainId
--    INNER JOIN DATASHARE.dbo.InlineInspection i
--        ON i.Client_Code = tbl.Client_Code
--           AND i.Id = r.InlineInspectionId
--    LEFT JOIN DATASHARE.dbo.StationSeries s
--        ON s.Client_Code = tbl.Client_Code
--           AND s.Id = tbl.StationSeriesId
--    LEFT JOIN
--    (
--        SELECT DISTINCT
--               StationSeriesId,
--               FactorNum,
--               MultiplierNum,
--               Client_Code
--        FROM DATASHARE.dbo.MLVCorrection
--    ) mc
--        ON mc.Client_Code = tbl.Client_Code
--           AND mc.StationSeriesId = s.Id
--    LEFT JOIN DATASHARE.dbo.LineLoop l
--        ON l.Client_Code = tbl.Client_Code
--           AND l.Id = s.LineLoopId;
--END
--GO
*/