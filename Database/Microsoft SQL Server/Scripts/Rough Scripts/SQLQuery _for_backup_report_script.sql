USE master
Declare @type INT
Set @type = 26

SELECT tmp.* FROM (SELECT  msdb.dbo.backupset.database_name,   REVERSE(SUBSTRING(REVERSE(msdb.dbo.backupmediafamily.physical_device_name), 1,                             CHARINDEX('\', REVERSE(msdb.dbo.backupmediafamily.physical_device_name)) - 1                     )          ) AS physical_file_name,        MAX(msdb.dbo.backupset.backup_finish_date) backupDate
FROM   msdb.dbo.backupmediafamily    INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE   (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - @type)
GROUP BY database_name, physical_device_name) tmp
INNER JOIN (SELECT  msdb.dbo.backupset.database_name,        
MAX(msdb.dbo.backupset.backup_finish_date) AS lastBackupDate
FROM   msdb.dbo.backupmediafamily    INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE   (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - @type)
GROUP BY database_name) tmp2 ON tmp.database_name = tmp2.database_name AND tmp.backupDate = tmp2.lastBackupDate


