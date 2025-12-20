USE [ConfigDBName]
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

