
USE DRAS_IRASv6_DEMO_QA_6_5_0
select * from sys.tables where name like 'LD_MD%'
SELECT dbversion, dbversioncheckpoint from versioninfo

select * from sys.tables where name in (
select LDTableName from DrasInternal.dbo.ListDomainTableInfo where tablename = 'POECompanyLookup'
)

SELECT * FROM sys.columns where object_name(object_id) = 'POECompanyLookup'
ILICompanyDomainId
ToolTypeDomainID
MetalLossTypeDomainID

update  versioninfo set dbversion = 640208, dbversioncheckpoint = 0


ALTER TABLE POECompanyLookUp ADD CONSTRAINT FK_POECompLookup_MetalLossTypeDomain FOREIGN KEY (MetalLossTypeDomainId) 
									REFERENCES LD_MetalLossType(Id)

									SELECT * FROM LD_MetalLossType
									select * from LD_ILICompany
									select * from LD_ToolType
									select top 2 * from Listdomain

SELECT * FROM ##NewDomainTableList where fktablename ='POECompanyLookUp'


									sp_columns POECompanyLookUp

	select DomainCatalogId from ListDomain where id in (select ToolTypeDomainId from POECompanyLookUp)
	select * from Domaincatalog where id in (26,31)

	select * from DrasInternal.dbo.ListDomainTableInfo  where ColumnName = 'ToolTypeDomainId'
	SELECT * FROM DomainCatalogColXRef where tablename = 'POECompanyLookUp' and columnname = 'ToolTypeDomainId'
ALTER TABLE POECompanyLookUp ALTER COLUMN MetalLossTypeDomainId NUMERIC (10,0)

UPDATE ListDomain 
SET DomainCatalogId = 31
WHERE Id in (select ToolTypeDomainId from POECompanyLookUp)

SET IDENTITY_INSERT LD_MetalLossType ON
--INSERT INTO LD_MetalLossType (Id, Code, Descr, CreatedUser, CreatedDate, LastModByUserId, LastModDateTime)
--SELECT Id, Code, Descr, SUSER_SNAME(), GETDATE(), LastModByUserId, LastModDateTime
--FROM Listdomain WHERE Id IN (SELECT DISTINCT MetalLossTypeDomainId FROM POECompanyLookUp)

INSERT INTO LD_MetalLossType (Id, Code, Descr, CreatedUser, CreatedDate, LastModByUserId, LastModDateTime)
VALUES (602042, 'N/A', 'N/A', SUSER_SNAME(), GETDATE(), SUSER_SNAME(), GETDATE())

SELECT * FROM ListDomain where id IN (SELECT DISTINCT MetalLossTypeDomainId FROM POECompanyLookUp)
									SELECT * FROM POECompanyLookUp

SET IDENTITY_INSERT LD_MetalLossType ON;

INSERT INTO LD_MetalLossType (Id, Code, Descr, EffectiveEndDate)
SELECT * FROM temp_LD_MetalLossType
				
WITH tmpQuery AS 
(SELECT Id,
		DomainCatalogId,
		Code,
		Descr
FROM ListDomain
WHERE Id IN (SELECT DISTINCT MetalLossTypeDomainId FROM POECompanyLookUp)
UNION
SELECT Id,
		DomainCatalogId,
		Code,
		Descr
FROM ListDomain WHERE DomainCatalogId = 300
AND Code NOT IN (SELECT Code FROM LD_MetalLossType)
) 
INSERT INTO temp_LD_MetalLossType (Id, Code, Descr, EffectiveEndDate)
SELECT Id,
		CASE 
		WHEN Code = '' THEN '<None>'
		ELSE Code
		END AS Code,
		CASE 
		WHEN Code = '' THEN '<None>'
		ELSE ISNULL(Descr, '<None>')
		END AS Descr,
		CASE 
			WHEN DomainCatalogId = -1 THEN GETDATE()
			ELSE NULL
		END AS EffectiveEndDate
FROM tmpQuery
WHERE Id NOT IN (SELECT Id FROM LD_MetalLossType)
ORDER BY 1

SELECT * FROM LD_MetalLossType

INSERT INTO LD_MetalLossType

SET IDENTITY_INSERT LD_MetalLossType OFF

INSERT INTO LD_MetalLossType
VALUES ()

SELECT * FROM LIstDomain where id = 602042