UPDATE DomainCatalogColXRef SET DomainCatalogId = 31 WHERE DomainCatalogId = 26
UPDATE ListDomain SET DomainCatalogId = 31 WHERE DomainCatalogId = 26

UPDATE Stg_ILIFeature SET ILIFGrading2DomainId = (SELECT Id FROM dbo.ListDomain ld WHERE ld.DomainCatalogId = 33 AND Code = 'Unknown') WHERE ILIFGrading2DomainId = 600352
UPDATE Stg_ILIFeature SET ILIFGrading2DomainId = (SELECT Id FROM dbo.ListDomain ld WHERE ld.DomainCatalogId = 33 AND Code = 'Other') WHERE ILIFGrading2DomainId = 600360

UPDATE Stg_ILINonCrsnDfct SET ILINCDGrading2DomainId = (SELECT Id FROM dbo.ListDomain ld WHERE ld.DomainCatalogId = 33 AND Code = 'Other') WHERE ILINCDGrading2DomainId = 600360
UPDATE Stg_ILINonCrsnDfct SET ILINCDGrading2DomainId = (SELECT Id FROM dbo.ListDomain ld WHERE ld.DomainCatalogId = 33 AND Code = 'Unknown') WHERE ILINCDGrading2DomainId IN (600353,600355,600356,600357)

UPDATE Stg_ILI SET ILITypeDomainId = (SELECT Id FROM dbo.ListDomain ld WHERE ld.DomainCatalogId = 26 AND Code = 'MFL') WHERE ILITypeDomainId = 31

UPDATE Structure SET OccupancyCtgryDomainId = (SELECT Id FROM dbo.ListDomain ld WHERE ld.DomainCatalogId = 89 AND Code = 'n/a') WHERE OccupancyCtgryDomainId = 85

INSERT INTO ListDomain (DomainCatalogID, Code, Descr)
SELECT 26, 'Unknown', 'Unknown' WHERE NOT EXISTS (SELECT * FROM ListDomain WHERE DomainCatalogId = 26 AND Code = 'Unknown')

UPDATE POECompanyLookup SET ToolTypeDomainID = (SELECT Id FROM ListDomain WHERE DomainCatalogId = 26 AND Code = 'Unknown') WHERE ToolTypeDomainID = 600333

