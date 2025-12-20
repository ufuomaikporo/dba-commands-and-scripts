------------------------ STEPS TO ADD OR MODIFY DE PROJECT TEMPLATES --------------------------

-- Must be done on the config database 
USE ETP_IRASV6_CONFIG_UPGRADE_TEST


----------------- STEP 1 CONVERT PROJECT TEMPLATE TO XML
-- Check if a project template exists and covert it to XML format
SELECT Name, cast(replace(replace(replace(cast(dt.MetaData AS varchar(max)), '&', '&amp;'), '>', '&gt;'), '<', '&lt;') AS xml) ProjectFile 
FROM dbo.DEProjectTemplate dt 
WHERE Name LIKE '<ProjectName>'

-- TO DELETE a project template (this removes it from the DataExchange app)
DELETE FROM DEProjectTemplate WHERE Name ='GUIDCleaupTest'

----------------- STEP 2 PASTE IT NOTEPAD AND MODIFY
/*
Paste the output from step 1 into Notepad++ and make modifications to the XML file if needed then use
 the search and replace function in Notepad++ to replace the following before updating or inserting the DE project template
 into the DEProjectTemplate table
 */
"&amp" ---> "&"
"&gt" ----> ">"
"&lt" ----> "<"
"'" ---> "''"

--------------- STEP 3 INSERT OR UPDATE PROJECT TEMPLATE

-- Insert a new project template using the JSON FILE
INSERT INTO DEProjectTemplate (Name, MetaData)
SELECT 'GUIDcleanupTest', CAST('JSON file' AS VARBINARY(MAX))

-- Update a DE project 
UPDATE DEProjectTemplate
SET Metadata =  CAST('<XML metadata>' AS VARBINARY(MAX))
WHERE Name = '<ProjectName>'