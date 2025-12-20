USE master
SELECT 
   DISTINCT(REVERSE(SUBSTRING(REVERSE(msdb.dbo.backupmediafamily.physical_device_name), 1,
                             CHARINDEX('\', REVERSE(msdb.dbo.backupmediafamily.physical_device_name)) - 1 
                    )
          )) AS physical_file_name
FROM 
   msdb.dbo.backupmediafamily 
   INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE 
   (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 1)  
ORDER BY 1 
 