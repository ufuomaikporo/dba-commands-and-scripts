USE master
Declare @type INT
SET @type = 1
DECLARE @DBFileCount INT
SELECT @DBFileCount =
   COUNT(DISTINCT(msdb.dbo.backupmediafamily.physical_device_name))
FROM 
   msdb.dbo.backupmediafamily 
   INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE 
   (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - @type) 

DECLARE @PhysicalFileCount INT
SELECT @PhysicalFileCount = COUNT(*) FROM tempdb.dbo.DiskBackupFile

--select @PhysicalFileCount - @DBFileCount 

IF (@PhysicalFileCount >= @DBFileCount )
BEGIN
  SELECT file_name FROM tempdb.dbo.DiskBackupFile
  EXCEPT
  SELECT 
   DISTINCT(REVERSE(SUBSTRING(REVERSE(msdb.dbo.backupmediafamily.physical_device_name), 1,
                             CHARINDEX('\', REVERSE(msdb.dbo.backupmediafamily.physical_device_name)) - 1 
                    )
          )) AS physical_file_name
FROM 
   msdb.dbo.backupmediafamily 
   INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE 
   (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - @type) 
ORDER BY 1 
END

Declare @type INT
SET @type = 1
DECLARE @DBFileCount INT
SELECT @DBFileCount =
   COUNT(DISTINCT(msdb.dbo.backupmediafamily.physical_device_name))
FROM 
   msdb.dbo.backupmediafamily 
   INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE 
   (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - @type) 

DECLARE @PhysicalFileCount INT
SELECT @PhysicalFileCount = COUNT(*) FROM tempdb.dbo.DiskBackupFile

BEGIN
   	SELECT 
	DISTINCT(REVERSE(SUBSTRING(REVERSE(msdb.dbo.backupmediafamily.physical_device_name), 1,
                             CHARINDEX('\', REVERSE(msdb.dbo.backupmediafamily.physical_device_name)) - 1 
                    )
          )) AS physical_file_name
	FROM 
		msdb.dbo.backupmediafamily 
		INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
	WHERE 
	(CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - @type) 
	EXCEPT
	SELECT file_name FROM tempdb.dbo.DiskBackupFile
END

select file_name from  tempdb.dbo.DBBackupHistory
except
SELECT file_name FROM tempdb.dbo.DiskBackupFile

SELECT file_name FROM tempdb.dbo.DiskBackupFile
except
select file_name from  tempdb.dbo.DBBackupHistory

