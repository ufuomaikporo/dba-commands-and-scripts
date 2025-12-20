USE master;  
GO  

--EXEC sp_helptext N'dbo.sp_DX6Configv5'; 
--SELECT OBJECT_DEFINITION (OBJECT_ID(N'dbo.sp_DX6Configv5'));  
DECLARE @Substr NVARCHAR(1000)
DECLARE @Index INT
DECLARE @SQL NVARCHAR(MAX)
DECLARE @StoreProcName NVARCHAR(100)
DECLARE @DBName NVARCHAR(100)
DECLARE @ServerName NVARCHAR(100)
DECLARE @MaxStrLength INT

IF OBJECT_ID('tempdb..##DBList') IS NOT NULL
BEGIN
	EXECUTE ('DROP TABLE ##DBList')
END

IF OBJECT_ID('tempdb..##DBList') IS NULL
BEGIN
	CREATE TABLE ##DBList (ServerName VARCHAR(100), DBName VARCHAR(100), Command NVARCHAR(MAX));
END;

SET @StoreProcName = 'sp_Dx6ConfigV5'

DECLARE ServerDB_Cur CURSOR FOR
SELECT name FROM sys.databases
WHERE (name LIKE '%Stage%' OR name LIKE '%Prod%')
AND  (name NOT LIKE '%CONFIG%' AND name NOT LIKE '%LINK%' AND name NOT LIKE '%RISK%'  AND name NOT LIKE '%HELY%'
	  AND name NOT LIKE '%BASEDATA%' AND name NOT LIKE '%deleteme%' AND name NOT LIKE '%interchange%'
	  AND name NOT LIKE '%TEST%')
AND name LIKE '%IRASV6%'
--AND name = 'EEC_US_TRANS_IRASv6_IRASP_STAGE'
AND state_desc = 'ONLINE'
ORDER BY name 

OPEN ServerDB_Cur
FETCH NEXT FROM ServerDB_Cur INTO @DBName

-- Loop through each database
WHILE @@FETCH_STATUS = 0
BEGIN
	-- Set an index variable to act as a cursor and go through the characters in the stored procedure
	SET @Index = 0

	-- get the total character length for the stored procedure definition
	SET @SQL = 'USE ' + @DBName + ' 
				SELECT @Result = LEN(OBJECT_DEFINITION(OBJECT_ID(N''' + @StoreProcName + ''')))'

	EXECUTE sp_executesql @SQL, N'@Result INT OUT', @MaxStrLength OUT

	-- Loop through the stored procedure definition 
	WHILE @Index <= @MaxStrLength
	BEGIN
		-- Find the search string ---> 'UPDATE' within the stored procedure definition
		SET @SQL ='USE ' + @DBName + '
					SELECT @Result = CHARINDEX(''UPDATE'', OBJECT_DEFINITION(OBJECT_ID(''' + @StoreProcName + ''')), ' 
					+ CAST(@Index AS NVARCHAR) + ' )'

		EXECUTE sp_executesql @SQL, N'@Result INT OUT', @Index OUT

		-- If the search string is not found, set the Index variable to the last character in the stored procedure to exit the inner while-loop
		IF(@Index = 0)
		BEGIN
			SET @Index = @MaxStrLength
		END
		ELSE
		BEGIN
			--If the search-string is found, get the substring starting at the point where the search-string was found
			SET @SQL = 'USE ' + @DBName + '
						SELECT @Result = SUBSTRING(OBJECT_DEFINITION(OBJECT_ID(''' + @StoreProcName + ''')), ' 
						+ CAST(@Index AS NVARCHAR) + ', 30)'

			EXECUTE sp_executesql @SQL, N'@Result NVARCHAR(300) OUT', @Substr OUT

			-- If the substring has something other than the following strings within it print it
			IF (@Substr NOT LIKE '%ListDomain%' AND @Substr NOT LIKE '%#temp_Fabrication%' AND @Substr NOT LIKE '%UPDATE f_%' 
				AND @Substr NOT LIKE '%facilityalignment %')
			BEGIN
					SET @SQL = 'INSERT INTO ##DBList
								VALUES (@@ServerName , ''' + @DBName + ''', ''USE ' + @DBName + ' EXEC sp_helptext N''''dbo.' + @StoreProcName + ''''''')'
				
					EXECUTE (@SQL);

					SET @Index = @MaxStrLength
			END
		END
		SET @Index +=50 --BREAK
		--select @Index, @MaxStrLength,
		

	END

	FETCH NEXT FROM ServerDB_Cur INTO @DBName

END

CLOSE ServerDB_Cur
DEALLOCATE ServerDB_Cur

SELECT * FROM ##DBList
