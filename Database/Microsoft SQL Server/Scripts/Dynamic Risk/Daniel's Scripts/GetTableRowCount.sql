SET NOCOUNT ON
DECLARE @cmdstr varchar(100)
DECLARE @Sort bit
SELECT @Sort = 1 /* Edit this value FOR sorting options */

--Create Temporary Table
declare @TempTable TABLE
 (	[Table_Name] varchar(80),
	Row_Count int,
	Table_Size varchar(50),
	Data_Space_Used varchar(50),
	Index_Space_Used varchar(50),
	Unused_Space varchar(50)
 )
--Create Stored Procedure String
 SELECT @cmdstr = 'sp_msforeachtable ''sp_spaceused "?"'''
--Populate Tempoary Table
 INSERT INTO @TempTable EXEC(@cmdstr)
--Determine sorting method
IF @Sort = 0 
	 BEGIN 
	 --Retrieve Table Data and Sort Alphabet
	--     ically
	 SELECT * FROM @TempTable ORDER BY Table_Name
END
ELSE
	 BEGIN
	 /*Retrieve TABLE Data AND Sort BY the size OF the Table*/
	 SELECT * FROM @TempTable ORDER BY Row_Count DESC
END				?