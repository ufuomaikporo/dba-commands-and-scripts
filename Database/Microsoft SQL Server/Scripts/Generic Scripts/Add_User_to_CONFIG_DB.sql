/*
This is the stored proc that I (Jagdish) created long time ago

I think it is still valid 

it has the list of tables that we need to insert the new userentries in

basically, there are 4 tables that we need to add the entries in

the roles id, you can copy form someone like Daniel or Sheila who you know would already have permission to load template on that db

These are the 4 tables but you can check an existing user and follow the parent record id in drasuser table in the config db


DrasUserDataSource 

DrasUserRole 

DrasUserPermission

DrasUser

*/

/****** Object: StoredProcedure [dbo].[IRAS_AddUser_Permission]    Script Date: 3/27/2023 1:58:06 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

EXECUTE IRAS_AddUser_Permission @UserName='EDDYFINDT\Ufuoma_Ikporo', @DataSourceId=1, @RoleId=1

CREATE PROCEDURE [dbo].[IRAS_AddUser_Permission]
@UserName VARCHAR(255), 
@DataSourceId Numeric(18,0), 
@RoleId Numeric(18,0), 
@PermissionId Numeric(18,0) = NULL

WITH EXECUTE AS OWNER AS
BEGIN
/************************************************************/
/*

 
Author    : Dynamic Risk Assessment Systems Inc.

 

Variables:

         1) Username        : Then Windows Login Name of the user using the IRAS Application with the Domain e.g. 'Domain_Name\FirstName_LastName'
         2) DataSourceId    : The Id of the datasource the above user will be connecting to, right now we only have one Data Source so the default DataSourceId will be 1
         3) RoleId            : The Role for the above user, the accepted values are:  
                                                                                    1 --> Administrator
                                                                                    2 --> Generic user
                                                                                    3 --> Guest user
                              The Role in turn ties to the Permission Id. 
        4) PermissionId        : The Permission for the above user, the accepted values are:  
                                                                                    1 --> All Permissions
                                                                                    2 --> Some Permissions
                                                                                    3 --> No Permissions

 

Usage    : EXECUTE IRAS_AddUser_Permission @UserName='Domain_Name\FirstName_LastName', @DataSourceId=1, @RoleId=1

 


*/
/************************************************************/

DECLARE @DisplayName varchar(255)
DECLARE @UserId Numeric(18,0)
DECLARE @ERR_MSG  NVARCHAR(4000)
DECLARE @ERR_SEV  SMALLINT
DECLARE @ERR_STA  SMALLINT

BEGIN TRY 
SET @UserId = (SELECT Id FROM DrasUser WHERE UserName = @UserName);

IF @UserId IS NOT NULL
BEGIN

PRINT 'The user '''+ @UserName + '''  already exists!'

RETURN;

END

SET @DisplayName = Replace (SUBSTRING(@UserName, CHARINDEX('\', @UserName) + 1, LEN(@UserName)),'_',' ')

----------------------------- Add User to the DrasUser table -----------------------------
        BEGIN
                INSERT INTO dbo.DrasUser ( UserName ,Password , MustChangePwd , DisplayName , IsLoggedIn , LastLogin)
                SELECT @UserName ,  Password , MustChangePwd , @DisplayName , IsLoggedIn , LastLogin  FROM dbo.DrasUser WHERE id=1;
        END
-------------------------------------------------------------------------------------------

SET @UserId = (SELECT Id FROM DrasUser WHERE UserName = @UserName);

----------------------------- Add DataSource for the user -----------------------------
IF @DataSourceId is NULL
        BEGIN
                SET @DataSourceId =1;
                INSERT INTO dbo.DrasUserDataSource ( IrasUserId ,DataSourceId)
                VALUES  ( @UserId ,@DataSourceId);
        END        
    ELSE
        BEGIN
                INSERT INTO dbo.DrasUserDataSource ( IrasUserId ,DataSourceId)
                VALUES  ( @UserId ,@DataSourceId);
        END
----------------------------- Add permissions for the user -----------------------------

IF @PermissionId is NULL
        BEGIN
        IF @RoleId is NULL
                BEGIN
                    SET @RoleID =1;
                    INSERT INTO dbo.DrasUserRole( IrasUserId ,IrasRoleId)
                    VALUES  ( @UserId ,@RoleID);
                END
            ELSE 
                BEGIN
                    INSERT INTO dbo.DrasUserRole( IrasUserId ,IrasRoleId)
                    VALUES  ( @UserId ,@RoleID);
                END      
        END
ELSE
        BEGIN
                INSERT INTO dbo.DrasUserPermission ( IrasUserId ,IrasPermissionId)
                VALUES  ( @UserId ,@PermissionId);
        END

PRINT 'User: '''+ @UserName + ''' added successfully '

END TRY
----------------------------- If errors, delete the added entries and Raise Error -----------------------------
BEGIN CATCH

DELETE FROM DrasUserDataSource WHERE IrasUserId=@UserId;
DELETE FROM DrasUserRole WHERE IrasUserId=@UserId;
DELETE FROM DrasUserPermission WHERE IrasUserId=@UserId;
DELETE FROM DrasUser WHERE Id=@UserId;

SET  @ERR_MSG = ERROR_MESSAGE();
SET @ERR_SEV =    ERROR_SEVERITY();
SET @ERR_STA = ERROR_STATE();

SET @ERR_MSG= 'Error occurred while adding user '''+ @UserName + ' to the database: ''' + @ERR_MSG
RAISERROR (@ERR_MSG, @ERR_SEV, @ERR_STA) WITH NOWAIT; 
END CATCH ;

END;
GO


-- EXECUTE IRAS_AddUser_Permission @UserName='EDDYFINDT\Debra_Carrobourg', @DataSourceId=1, @RoleId=1
-- EXECUTE IRAS_AddUser_Permission @UserName='EDDYFINDT\Azubuike_Ossai', @DataSourceId=1, @RoleId=1 
-- EXECUTE IRAS_AddUser_Permission @UserName='EDDYFINDT\Sheila_Cubid', @DataSourceId=1, @RoleId=1
-- EXECUTE IRAS_AddUser_Permission @UserName='EDDYFINDT\Hely_Bhagat', @DataSourceId=1, @RoleId=1


-#######################################################################################################################################

-- Creates windows authenticated login at server level if it does not already exist

CREATE LOGIN [EDDYFINDT\Dras Users] FROM WINDOWS;  
GO  

-- Create user (within database) for the (server level) login 

CREATE USER [EDDYFINDT\Dras Users] FOR LOGIN [EDDYFINDT\Dras Users];  
GO 

-- Add user to a role 

EXEC sp_addrolemember 'db_datareader', [EDDYFINDT\Dras Users]
EXEC sp_addrolemember 'db_datawriter', [EDDYFINDT\Dras Users]


