UPDATE CoatingCondition 
set CoatingCondLineTypeLD = 600369
WHERE CoatingCondLineTypeLD IN (124, 701350)

IF NOT EXISTS (SELECT * FROM ListDomain WHERE DomainCatalogId = 298 AND Code = 'Unknown' AND Descr = 'Unknown')
BEGIN
	INSERT INTO listdomain (DomainCatalogId, Code, Descr)
	VALUES (298, 'Unknown', 'Unknown')
END


UPDATE FrostArea 
SET FrostAreaRangeLD = (SELECT ID FROM listdomain where Code = 'Unknown' and DomainCatalogId = (Select Id from DomainCatalog where DomainDescr = 'FROST AREA RANGE'))
WHERE FrostAreaRangeLD = 2720

UPDATE InlineInspectionCrackAnomaly 
set ILICAGrading1DomainId = 701914
WHERE ILICAGrading1DomainId IN (152)



update InlineInspectionCrackAnomaly 
set ILICAGrading2DomainId = 701915
WHERE ILICAGrading2DomainId IN (153)


update InlineInspectionCrackAnomaly 
set ILICATypeDomainId = 700950
WHERE ILICATypeDomainId IN (5515535)

update InlineInspectionCrackAnomaly 
set ILICATypeDomainId = 700951
WHERE ILICATypeDomainId IN (5515536)




update InlineInspectionNonCrsnDfct 
set ILINCDGrading1DomainId = 26932
WHERE ILINCDGrading1DomainId IN (600223)

update InlineInspectionNonCrsnDfct 
set ILINCDGrading2DomainId = 26933
WHERE ILINCDGrading2DomainId IN (153)

update Lineloop 
set LineLoopProdTypeLd = 701943



update Lineloop 
set LineLoopStatusLd = 701126
WHERE LineLoopStatusLd IN (1)

update MLVCorrection 
set DistrictDivisionDomainId = 600366
WHERE DistrictDivisionDomainId IN (5515482)


DELETE FROM POECoatingProperty WHERE CoatingLineDomainId IN (
SELECT CoatingLineDomainId FROM POECoatingProperty t
INNER JOIN dbo.ListDomain ld ON t.CoatingLineDomainId = ld.Id
WHERE ld.DomainCatalogId <> 14)


INSERT INTO dbo.ListDomain
(
    DomainCatalogId,
    Code,
    Descr
)
VALUES
(
    189, -- DomainCatalogId - numeric
    'Unknown', -- Code - varchar
    'Unknown'
)


UPDATE Stg_ILICrackAnomaly
SET ILICATypeDomainId = (SELECT ld.Id FROM dbo.ListDomain ld WHERE ld.DomainCatalogId IN (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Crack Anomaly Type') AND Code = 'Unknown')
WHERE ILICATypeDomainId IN (600660,600661)

UPDATE Stg_ILINonCrsnDfct
SET ILINCDGrading2DomainId = (SELECT ld.Id FROM dbo.ListDomain ld WHERE ld.DomainCatalogId IN (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILINCDGrading2') AND Code = 'Unknown')
WHERE ILINCDGrading2DomainId IN (600138,
600140,
600144,
600146,
600148)

UPDATE Stg_ILI
SET ILITypeDomainId = (SELECT ld.Id FROM dbo.ListDomain ld WHERE ld.DomainCatalogId IN (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool') AND Code = 'MFL')
WHERE ILITypeDomainId IN (26)


UPDATE Stg_ILIRange
SET ILIRToolDomainId = (SELECT ld.Id FROM dbo.ListDomain ld WHERE ld.DomainCatalogId IN (SELECT Id FROM DomainCatalog WHERE DomainDescr = 'ILI Tool') AND Code = 'MFL')
WHERE ILIRToolDomainId IN (26)

UPDATE ListDomain 
SET DomainCatalogId = 31
WHERE Id in (select DISTINCT ToolTypeDomainId from POECompanyLookUp)

UPDATE DomainCatalogColXRef SET DomainCatalogId = 31 WHERE DomainCatalogId = 26
UPDATE ListDomain SET DomainCatalogId = 31 WHERE DomainCatalogId = 26




