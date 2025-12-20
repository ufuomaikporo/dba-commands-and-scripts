
select TOP 20  * from InlineInspectionJoint
select TOP 20 * from InlineInspectionFeature
select TOP 20 * from InlineInspectionCrsnCallBox
select TOP 20 * from InlineInspectionNonCrsnDfct
select TOP 20 * from InlineInspectionFacility
select TOP 20 * from InlineInspectionCrackAnomaly
select TOP 20 * from InlineInspectionJoint12102019
select TOP 20 * from InlineInspection
select TOP 20 * from InlineInspectionRange
select TOP 20 * from InlineInspectionBendStrain
select TOP 20 * from InlineInspectionAxialStrain
select TOP 20 * from InlineInspectionRemark
select TOP 20 * from InlineInspectionStrain
select TOP 20 * from StationSeries

select * from StationSeries where client_code = 'EEC' order by LineLoopId, SeriesValueNUmber
select * from LineLoop where client_code = 'EEC' order by PipelinesystemId
select * from DischargeSubsystem where client_code = 'EEC' order by PipelinesystemId
select * from Corporation where client_code = 'EEC'
select * from OperatingUnit where client_code = 'EEC'
select * from PipelineSystem where client_code = 'EEC' ORDER BY OperatingUnitId
select * from InlineInspection WHERE client_code = 'EEC'

select ps.client_code, ps.Id PipelineSystemId, ps.PipelineSystemName, ll.LineName, 
ds.DischargeSubsystemName, llType.Code AS LineLoopType, llstatus.Code AS LineLoopStatus,
llprod.Code AS LineLoopProdType
from LineLoop ll
JOIN PipelineSystem ps ON ll.PipelineSystemId = ps.Id AND ps.Client_Code = ll.Client_Code
JOIN DischargeSubsystem ds ON ds.PipelineSystemId = ps.Id AND ds.Client_Code = ps.Client_Code
LEFT JOIN ListDomain llType ON llType.Id = ll.LineLoopTypeLd AND llType.Client_Code = ll.Client_Code
LEFT JOIN ListDomain llstatus ON llstatus.Id = ll.LineLoopStatusLd AND llstatus.Client_Code = ll.Client_Code
LEFT JOIN ListDomain llprod ON llprod.Id = ll.LineLoopProdTypeLd AND llprod.Client_Code = ll.Client_Code
where ps.Client_Code = 'EEC'

SELECT TOP 100 * FROM DATASHARE_DQA.dbo.DQA_IH_InlineInspectionRange
drop table Temp_InlineInspectionRange
drop table Temp_InlineInspection

SELECT ilir.Client_Code, ilir.Id, InlineInspectionId, EffectiveStartDate, EffectiveEndDate, 
ilit.Code AS ILITool, ilis.Code AS ILIStatus, ilifpa.Code AS ILIFailPressAlgthm,
ILIRDescr, ILIRStartOdometer, ILIREndOdometer, ILIRStartDate, ILIREndDate,
BeginStationSeriesId, BeginStationNum, EndStationNum
INTO Temp_InlineInspectionRange
FROM dbo.InlineInspectionRange ilir
LEFT JOIN dbo.ListDomain ilit 
ON ilit.Client_Code = ilir.Client_Code AND ilit.Id = ilir.ILIRToolDomainId
LEFT JOIN dbo.ListDomain ilis 
ON ilis.Client_Code = ilir.Client_Code AND ilis.Id = ilir.ILIRStatusDomainId
LEFT JOIN dbo.ListDomain ilifpa
ON ilifpa.Client_Code = ilir.Client_Code AND ilifpa.Id = ilir.ILIRFailPressAlgthmDomainId
JOIN dbo.InlineInspection ili
ON ili.Client_Code = ilir.Client_Code AND ili.Id = ilir.InlineInspectionId

SELECT ili.Client_Code, ili.Id, ILIName, iliv.Code AS ILIVendor, ilicbir.Code AS ILICallBoxInteractRule,
ILIReportReceivedDate, ILIStartDate, ILIEndDate, ILIDescr, ilis.Code AS ILIStatus, ilit.Code AS ILIType,
ILIBaselineAssessmentFlg, ILIDummyToolFlg, ILIBenchMarkFlg, SpecVersion, MeasuredFrom
INTO Temp_InlineInspection
FROM InlineInspection ili
LEFT JOIN ListDomain iliv 
ON iliv.Client_Code = ili.Client_Code AND ili.ILICompanyDomainId = iliv.Id
LEFT JOIN ListDomain ilicbir
ON ilicbir.Client_Code = ili.Client_Code AND ili.ILICallBoxInteractRuleDomainId = ilicbir.Id
LEFT JOIN ListDomain ilis
ON ilis.Client_Code = ili.Client_Code AND ili.ILIStatusDomainId = ilis.Id
LEFT JOIN ListDomain ilit
ON ilit.Client_Code = ili.Client_Code AND ili.ILITypeDomainId = ilit.Id

SELECT TOP 100 * FROM Temp_InlineInspectionRange ilir JOIN Temp_InlineInspection ili ON ili.Id = ilir.InlineInspectionId

select ili.client_code, ili.Id AS InlineInspectionId, ilir.Id AS ILIRId, ILIRStartOdometer, ILIREndOdometer,
BeginStationSeriesId,BeginStationNum, EndStationNum, ILIRStartDate, ILIStartDate, ILIREndDate, ILIEndDate,
ilir.EffectiveStartDate, ilir.EffectiveEndDate, ILITool, ili.ILIStatus, ilir.ILIStatus, ili.ILIType, ILIFailPressAlgthm, ILICallBoxInteractRule, ILIBaselineAssessmentFlg, ILIDummyToolFlg,
ILIBenchMarkFlg, MeasuredFrom, ILIDescr, ILIRDescr
FROM Temp_InlineInspectionRange ilir
JOIN Temp_InlineInspection ili ON ili.Client_Code = ilir.Client_Code AND ili.Id = ilir.InlineInspectionId
--GROUP BY ili.Client_Code, ili.id
--having count(ilir.Id) > 1
WHERE ili.id = 1756 AND ili.Client_Code = 'EEC'
--ILIRStartDate <> ILIStartDate
order by 1, 2, 3


select ili.client_code, ili.Id AS InlineInspectionId, count(ilir.Id) AS ILIRId --ILIRStartOdometer, ILIREndOdometer, ILIRStartDate, ILIStartDate, ILIREndDate, ILIEndDate,
--ilir.EffectiveStartDate, ilir.EffectiveEndDate, ILITool, ili.ILIStatus, ilir.ILIStatus, ili.ILIType, ILIFailPressAlgthm, ILICallBoxInteractRule, ILIBaselineAssessmentFlg, ILIDummyToolFlg,
--ILIBenchMarkFlg, MeasuredFrom, ILIDescr, ILIRDescr
FROM Temp_InlineInspectionRange ilir
JOIN Temp_InlineInspection ili ON ili.Client_Code = ilir.Client_Code AND ili.Id = ilir.InlineInspectionId
GROUP BY ili.Client_Code, ili.id
having count(ilir.Id) > 1
--WHERE ili.id <> ilir.InlineInspectionId
order by 1, 2

select * from ILIStatus_Library
select * from ILIVendor_Library
select * from ILITool_Library
