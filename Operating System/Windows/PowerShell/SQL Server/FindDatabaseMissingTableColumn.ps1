$GetServerList = "USE master

DECLARE @DBName NVARCHAR(100)
DECLARE @SQL NVARCHAR(MAX)
DECLARE @IfExists INT

DECLARE @DBList TABLE (DBName NVARCHAR(100))

DECLARE TableList_Cursor CURSOR FOR
SELECT name FROM sys.databases
WHERE database_id > 4
AND name LIKE '%IRAS%'

OPEN TableList_Cursor
FETCH NEXT FROM TableList_Cursor INTO @DBName

WHILE @@FETCH_STATUS = 0
BEGIN

	SET @SQL = 'USE ' + @DBName + '
				
				IF EXISTS  (SELECT 1 FROM INFORMATION_SCHEMA.columns 
					WHERE column_name = ''ProjectRunDate''
					AND table_name = ''ActionItem'')
				BEGIN
					SET @Result = 1
				END
				ELSE
				BEGIN
					SET @Result = 0
				END'

	EXECUTE sp_executesql @SQL, N'@Result INT OUT', @IfExists OUT

	IF (@IfExists = 0)
	BEGIN
		INSERT INTO @DBList
		VALUES (@DBName)
	END;

	FETCH NEXT FROM TableList_Cursor INTO @DBName
END

CLOSE TableList_Cursor
DEALLOCATE TableList_Cursor

SELECT * FROM @DBList"

$SeverList = @('SQL2012EXT', 'SQL2014', 'SQL2016', 'SQL2017', 'SQL2019', 'SQLDEVPREPROD')
$OutputFile = "C:\Temp\List Of Databases missing ProjectRunDate column in ActionItem table.txt"

Write-Output "" | Out-File $OutputFile -Force

foreach ($Server IN $SeverList)
{
    Write-Host $Server
    $DBList = Invoke-Sqlcmd -ServerInstance $Server -Database 'master' -Query $GetServerList

    Write-Output "**************************$Server**************************************" | Out-File $OutputFile -Append
    $DBList = [system.String]::Join("`r`n", ($DBList.DBName | Sort-Object)) 

    Write-Output "`r`n$DBList`r`n"| Out-File $OutputFile -Append

}