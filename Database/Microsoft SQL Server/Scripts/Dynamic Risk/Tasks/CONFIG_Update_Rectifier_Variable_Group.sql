UPDATE variable 
SET GroupId = (SELECT * FROM dbo.VariableGroup vg WHERE Name = 'Centerline')
WHERE GroupId = (SELECT * FROM dbo.VariableGroup vg WHERE Name = 'Rectifier')