-- Copy the map from the test db to the client db

-- Run this query on the test db 
SELECT * FROM dbo.SystemPreferences
WHERE parameterName LIKE '%default'

-- Insert the row entries from the query above for 'MapProject_Default' and 'SpatialData_Defult' into the client db
