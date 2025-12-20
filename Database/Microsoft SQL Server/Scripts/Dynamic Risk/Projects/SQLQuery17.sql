
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
				
SELECT OBJECT_NAME(fkc.constraint_object_id) AS fk_constraint,
	   SCHEMA_NAME(t1.schema_id) AS fk_table_schema,
	   OBJECT_NAME(fkc.parent_object_id) AS fk_table,
	   COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS fk_column,
	   SCHEMA_NAME(t2.schema_id) AS referenced_table_schema,
	   OBJECT_NAME(fkc.referenced_object_id) AS referenced_table,
	   COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS referenced_column,
	   kcu.ordinal_position
FROM sys.foreign_key_columns fkc
JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
	ON kcu.constraint_name = OBJECT_NAME(fkc.constraint_object_id)
	AND kcu.column_name = COL_NAME(fkc.parent_object_id, fkc.parent_column_id)
JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id
JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id
WHERE OBJECT_NAME(fkc.referenced_object_id) = 'LD_MetalLossType'