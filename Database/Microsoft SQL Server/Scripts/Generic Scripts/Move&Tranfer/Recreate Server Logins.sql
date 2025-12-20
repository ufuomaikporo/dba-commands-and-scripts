/*
This script generates the code to re-create valid windows users, groups, and sql server logins 

Run the script on the server whose logins you would like to copy, then copy the resulting output
to the master database of the server where you would like the logins to be created
*/

USE master

IF OBJECT_ID('tempdb..##InvalidUsers') IS NOT NULL
BEGIN
	DROP TABLE ##InvalidUsers
END

IF OBJECT_ID('tempdb..##InvalidUsers') IS NULL
BEGIN
	CREATE TABLE ##InvalidUsers (SID VARBINARY(85), name VARCHAR(200))
END

INSERT INTO ##InvalidUsers
EXEC sp_validatelogins;


SELECT 'IF (SUSER_ID('+QUOTENAME(SP.name,'''')+') IS NULL) BEGIN CREATE LOGIN ' +QUOTENAME(SP.name)+
               CASE 
                    WHEN SP.type_desc = 'SQL_LOGIN' THEN ' WITH PASSWORD = ' +CONVERT(NVARCHAR(MAX),SL.password_hash,1)+ ' HASHED, CHECK_EXPIRATION = ' 
                        + CASE WHEN SL.is_expiration_checked = 1 THEN 'ON' ELSE 'OFF' END +', CHECK_POLICY = ' +CASE WHEN SL.is_policy_checked = 1 THEN 'ON,' ELSE 'OFF,' END
                    ELSE ' FROM WINDOWS WITH'
                END 
       +' DEFAULT_DATABASE=[' +SP.default_database_name+ '], DEFAULT_LANGUAGE=[' +SP.default_language_name+ '] END;' COLLATE SQL_Latin1_General_CP1_CI_AS AS [-- Logins To Be Created --]
FROM sys.server_principals SP
LEFT JOIN sys.sql_logins AS SL ON SP.principal_id = SL.principal_id
WHERE SP.type IN ('S','G','U')
        AND SP.name NOT LIKE '##%##'
		AND SP.name NOT IN (SELECT name FROM ##InvalidUsers)
        AND SP.name NOT LIKE 'NT AUTHORITY%'
        AND SP.name NOT LIKE 'NT SERVICE%'
        AND SP.name NOT IN  ('sa', 'distributor_admin')