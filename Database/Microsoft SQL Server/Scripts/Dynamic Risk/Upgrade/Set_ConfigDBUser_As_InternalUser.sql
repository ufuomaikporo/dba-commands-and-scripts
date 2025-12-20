--USE [ConfigDBName]
-- Make sure the du.UserName user is added to the config database with AdminToolls first before running this script

DECLARE @irasUserId int
DECLARE @irasRoleId int

SET @irasUserId = (SELECT du.Id FROM dbo.DrasUser du WHERE du.UserName = 'EDDYFINDT\Ufuoma_Ikporo')
SET @irasRoleId = (SELECT dr.Id FROM dbo.DrasRole dr WHERE dr.Name = 'Admin')

-- If you want to set yourself as Internal, uncomment the following line. Otherwise, this script will make you as Admin
SET @irasRoleId = (SELECT dr.Id FROM dbo.DrasRole dr WHERE dr.Name = 'Internal')

DELETE FROM dbo.DrasUserRole WHERE IrasUserId = @irasUserId

INSERT INTO dbo.DrasUserRole (IrasUserId,IrasRoleId)
SELECT @irasUserId, @IrasRoleId

/*
DataExchange Checks

-- Check that the maps (ArcGis) are loaded (run on Stage db)
SELECT * FROM dbo.SystemPreferences 
WHERE ParameterName LIKE '%default'

--Check that Overlay Map package is loaded (Run on config db) - Use VM on same colocation as server or it takes extremely long time
SELECT * FROM dbo.DEFiles

--Check That Astera Templates are loaded (run on Config)
SELECT * FROM dbo.DETemplates

*/