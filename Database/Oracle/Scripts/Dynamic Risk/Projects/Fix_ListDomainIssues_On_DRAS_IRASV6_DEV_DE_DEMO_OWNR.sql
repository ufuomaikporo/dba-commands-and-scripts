INSERT INTO ListDomain (Id, DomainCatalogId, Code, Descr)
VALUES ((SELECT MAX(Id) + 1 FROM ListDomain), 26, 'Unknown', 'Unknown');

UPDATE POECompanyLookUp SET ToolTypeDomainId = (SELECT Id FROM ListDomain WHERE DomainCatalogId = 26 AND Code = 'Unknown')
WHERE ToolTypeDomainId = 600333;

COMMIT;
