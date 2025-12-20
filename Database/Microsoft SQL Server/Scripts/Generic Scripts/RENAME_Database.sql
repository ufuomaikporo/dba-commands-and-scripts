/*
This script renames a database if it exists on the server
*/

DECLARE @OldName NVARCHAR(100);
DECLARE @NewName NVARCHAR(100);
DECLARE @SQL NVARCHAR(MAX);

--************************************** SET THE FOLLOWING VARIABLES BEFORE RUNNING SCRIPT ******************************

SET @OldName = '_IRASV6_CONFIG';
SET @NewName = REPLACE(@OldName, 'MEP', 'MOM');

--***********************************************************************************************************************

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = @OldName)
BEGIN
	SET @SQL = 'USE master;  

	ALTER DATABASE ' + @OldName + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	ALTER DATABASE ' + @OldName + ' MODIFY NAME = ' + @NewName + '; 
	ALTER DATABASE ' + @NewName + ' SET MULTI_USER;
	'
	--SELECT @SQL
	EXECUTE (@SQL);
END
ELSE
BEGIN
	PRINT CHAR(10) + 'The ' + @OldName + 'database does not exist on this server' + CHAR(10)
END;