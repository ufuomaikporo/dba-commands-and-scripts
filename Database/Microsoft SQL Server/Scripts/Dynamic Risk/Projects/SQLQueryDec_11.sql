SELECT * FROM ListDomain WHERE Id IN (SELECT DISTINCT ILICBStatusDomainId FROM InlineInspectionCrsnCallBox)
SELECT * FROM ListDomain WHERE Id IN (SELECT DISTINCT ILICBFailPressAlgthmDomainId FROM InlineInspectionCrsnCallBox)
--SELECT * FROM ListDomain WHERE Id IN (SELECT DISTINCT ListDomainID FROM RememberedListDomainValues)
SELECT * FROM ListDomain WHERE Id IN (SELECT DISTINCT CoatingLineDomainId FROM POECoatingProperty)
--SELECT * FROM ListDomain	WHERE Id IN (SELECT DISTINCT DataFieldValueDomainId FROM VirtualTableDataListDomain)
SELECT * FROM ListDomain WHERE Id IN (SELECT DISTINCT StructureTypeDomainId FROM StructureAreaFill)
SELECT * FROM ListDomain WHERE Id IN (SELECT DISTINCT ILINCDStatusDomainId FROM InlineInspectionNonCrsnDfct)

SELECT * FROM DomainCatalogColXRef
WHERE tablename = 'InlineInspectionCrsnCallBox'
AND columnname = 'ILICBFailPressAlgthmDomainId'

select * from domaincatalog where id in (27, 29)

select * from ActionItemPropDCXRef