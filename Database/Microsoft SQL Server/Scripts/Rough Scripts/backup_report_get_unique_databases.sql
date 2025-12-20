USE master
Declare @type INT
Set @type = 26
SELECT msdb.dbo.backupset.database_name, 
       msdb.dbo.backupset.backup_finish_date,
       REVERSE(SUBSTRING(REVERSE(msdb.dbo.backupmediafamily.physical_device_name), 1,
                             CHARINDEX('\', REVERSE(msdb.dbo.backupmediafamily.physical_device_name)) - 1 
                    )
          ) AS physical_file_name
FROM 
   msdb.dbo.backupmediafamily 
   INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
INNER JOIN (
SELECT  msdb.dbo.backupset.database_name,
		MAX(msdb.dbo.backupset.backup_finish_date) AS last_backup_date
FROM 
   msdb.dbo.backupmediafamily 
   INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE 
   (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - @type)
GROUP BY database_name
) dbs
ON dbs.database_name = msdb.dbo.backupset.database_name 
  AND dbs.last_backup_date = msdb.dbo.backupset.backup_finish_date