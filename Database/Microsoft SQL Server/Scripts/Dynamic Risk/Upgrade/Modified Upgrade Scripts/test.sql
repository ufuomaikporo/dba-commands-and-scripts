/* 
 * Script for updating the list domains for fields in ILIAnalyst that have defaults defined.
 * There was a bug (43778) that uncovered a problem where in some instances, the list domain defined as the default was not mapped to the domain catalog
 * for the column in the database. The original script assumed a specific domain catalog was mapped, but it may not always be the case.
 *
 * PLEASE NOTE:
 * Please make sure this script is run after "CLIENT_NewRecordsIntoSystemPreferencesAndListDomain_BL40381".
 */

/*
	One of the previous scripts created the list domains set as defaults before. If it doesn't exist, we will:
		1. Add a list domain for the domain catalog of the column.
		2. Update the SystemPreferences table to use the list domain that was added.
*/
-- Check if the default list domain expected for Metal Loss (Corrosion) type exists. If not, we will add it and update the SystemPreferences table.
IF NOT EXISTS (SELECT * FROM ListDomain WHERE Code = 'Corrosion' AND DomainCatalogId = (SELECT TOP 1 DomainCatalogId FROM DomainCatalogColXRef WHERE TableName = 'MetalLoss' AND ColumnName = 'MetalLossTypeDomainId'))
BEGIN
	INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId)
	VALUES ((SELECT TOP 1 DomainCatalogId FROM DomainCatalogColXRef WHERE TableName = 'MetalLoss' AND ColumnName = 'MetalLossTypeDomainId'), 'Corrosion', 'Corrosion', NULL);

	-- Update the SystemPreferences table for the default metal loss type to use the list domain added.
	UPDATE SystemPreferences
	SET Value = (SELECT TOP 1 Id FROM ListDomain WHERE Code = 'Corrosion' AND DomainCatalogId = (SELECT TOP 1 DomainCatalogId FROM DomainCatalogColXRef WHERE TableName = 'MetalLoss' AND ColumnName = 'MetalLossTypeDomainId'))
	WHERE ParameterName = 'DefaultMetalLossType';
END
-- Check if the default list domain expected for Mechanical Damage (Deformation) type exists. If not, we will add it and update the SystemPreferences table.
IF NOT EXISTS (SELECT * FROM ListDomain WHERE Code = 'Deformation' AND DomainCatalogId = (SELECT TOP 1 DomainCatalogId FROM DomainCatalogColXRef WHERE TableName = 'MechanicalDamage' AND ColumnName = 'MechDmgDefectTypeDomainId'))
BEGIN
	INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId)
	VALUES ((SELECT TOP 1 DomainCatalogId FROM DomainCatalogColXRef WHERE TableName = 'MechanicalDamage' AND ColumnName = 'MechDmgDefectTypeDomainId'), 'Deformation', 'Deformation', NULL);

	-- Update the SystemPreferences table for the default mechanical damage type to use the list domain added.
	UPDATE SystemPreferences
	SET Value = (SELECT TOP 1 Id FROM ListDomain WHERE Code = 'Deformation' AND DomainCatalogId = (SELECT TOP 1 DomainCatalogId FROM DomainCatalogColXRef WHERE TableName = 'MechanicalDamage' AND ColumnName = 'MechDmgDefectTypeDomainId'))
	WHERE ParameterName = 'DefaultMechanicalDamageType';
END
-- Check if the default list domain expected for ESCA (CrackLike) type exists. if not, we will add it and update the SystemPreferences table.
IF NOT EXISTS (SELECT * FROM ListDomain WHERE Code = 'Crack-Like' AND DomainCatalogId = (SELECT TOP 1 DomainCatalogId FROM DomainCatalogColXRef WHERE TableName = 'ExcavationSiteCrackAnomaly' AND ColumnName = 'ESCATypeDomainId'))
BEGIN
	INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId)
	VALUES ((SELECT TOP 1 DomainCatalogId FROM DomainCatalogColXRef WHERE TableName = 'ExcavationSiteCrackAnomaly' AND ColumnName = 'ESCATypeDomainId'), 'Crack-Like', 'Crack-Like', NULL);

	-- Update the SystemPreferences table for the default crack anomaly type to use the list domain added.
	UPDATE SystemPreferences
	SET Value = (SELECT TOP 1 Id FROM ListDomain WHERE Code = 'Crack-Like' AND DomainCatalogId = (SELECT TOP 1 DomainCatalogId FROM DomainCatalogColXRef WHERE TableName = 'ExcavationSiteCrackAnomaly' AND ColumnName = 'ESCATypeDomainId'))
	WHERE ParameterName = 'DefaultESCAType';
END

-- Check if the default list domain expected for Metal Loss status (Not Found in Field) exists. If not, we will add it and update the SystemPreferences table.
IF NOT EXISTS (SELECT * FROM ListDomain WHERE Code = 'Not Found In Field' AND DomainCatalogId = (SELECT TOP 1 DomainCatalogId FROM DomainCatalogColXRef WHERE TableName = 'MetalLoss' AND ColumnName = 'MetalLossStatusDomainId'))
BEGIN
	INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId)
	VALUES ((SELECT TOP 1 DomainCatalogId FROM DomainCatalogColXRef WHERE TableName = 'MetalLoss' AND ColumnName = 'MetalLossStatusDomainId'), 'Not Found In Field', 'Not Found In Field', NULL);

	-- Update the SystemPreferences table for the default metal loss status to use the list domain added.
	UPDATE SystemPreferences
	SET Value = (SELECT TOP 1 Id FROM ListDomain WHERE Code = 'Not Found In Field' AND DomainCatalogId = (SELECT TOP 1 DomainCatalogId FROM DomainCatalogColXRef WHERE TableName = 'MetalLoss' AND ColumnName = 'MetalLossStatusDomainId'))
	WHERE ParameterName = 'DefaultMetalLossStatus';
END
-- Check if the default list domain expected for Mechanical Damage (Not Found in Field) status exists. If not, we will add it and update the SystemPreferences table.
IF NOT EXISTS (SELECT * FROM ListDomain WHERE Code = 'Not Found In Field' AND DomainCatalogId = (SELECT TOP 1 DomainCatalogId FROM DomainCatalogColXRef WHERE TableName = 'MechanicalDamage' AND ColumnName = 'MechDmgStatusDomainId'))
BEGIN
	INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId)
	VALUES ((SELECT TOP 1 DomainCatalogId FROM DomainCatalogColXRef WHERE TableName = 'MechanicalDamage' AND ColumnName = 'MechDmgStatusDomainId'), 'Not Found In Field', 'Not Found In Field', NULL);

	-- Update the SystemPreferences table for the default mechanical damage status to use the list domain added.
	UPDATE SystemPreferences
	SET Value = (SELECT TOP 1 Id FROM ListDomain WHERE Code = 'Not Found In Field' AND DomainCatalogId = (SELECT TOP 1 DomainCatalogId FROM DomainCatalogColXRef WHERE TableName = 'MechanicalDamage' AND ColumnName = 'MechDmgStatusDomainId'))
	WHERE ParameterName = 'DefaultMechanicalDamageStatus';
END
-- Check if the default list domain expected for ESCA (Not Found in Field) status exists. if not, we will add it and update the SystemPreferences table.
IF NOT EXISTS (SELECT * FROM ListDomain WHERE Code = 'Not Found In Field' AND DomainCatalogId = (SELECT TOP 1 DomainCatalogId FROM DomainCatalogColXRef WHERE TableName = 'ExcavationSiteCrackAnomaly' AND ColumnName = 'ESCAStatusDomainId'))
BEGIN
	INSERT INTO ListDomain (DomainCatalogId, Code, Descr, SourceDomainId)
	VALUES ((SELECT TOP 1 DomainCatalogId FROM DomainCatalogColXRef WHERE TableName = 'ExcavationSiteCrackAnomaly' AND ColumnName = 'ESCAStatusDomainId'), 'Not Found In Field', 'Not Found In Field', NULL);

	-- Update the SystemPreferences table for the default crack anomaly status to use the list domain added.
	UPDATE SystemPreferences
	SET Value = (SELECT TOP 1 Id FROM ListDomain WHERE Code = 'Not Found In Field' AND DomainCatalogId = (SELECT TOP 1 DomainCatalogId FROM DomainCatalogColXRef WHERE TableName = 'ExcavationSiteCrackAnomaly' AND ColumnName = 'ESCAStatusDomainId'))
	WHERE ParameterName = 'DefaultESCAStatus';
END