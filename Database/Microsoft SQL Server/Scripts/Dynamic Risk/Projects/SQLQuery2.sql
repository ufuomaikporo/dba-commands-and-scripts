SELECT * FROM TempListDomainTable
WHERE DomainDescr IN ('State / Province Name', 'Class Area Rating', 'ILI Status', 
'ILI Type', 'ILI Tool', 'Failure Pressure Algorithm', 'ILI Defect Status', 'Coordinate System')
ORDER BY DomainDescr

--select * from Temp_DomainCatalog where DomainDescr = 'ILI Tool'