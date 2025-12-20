USE master
Declare @type INT
DECLARE @num_of_backup_files INT
Set @type = 1

SELECT name FROM sys.databases
WHERE database_id > 4
EXCEPT
SELECT  DISTINCT (msdb.dbo.backupset.database_name) AS dbname
FROM 
   msdb.dbo.backupmediafamily 
   INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE 
   (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - @type)
ORDER BY 1




