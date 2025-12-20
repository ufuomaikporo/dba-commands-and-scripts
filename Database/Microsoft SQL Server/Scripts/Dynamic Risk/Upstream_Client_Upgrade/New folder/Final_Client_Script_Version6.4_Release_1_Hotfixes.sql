
BEGIN TRY
	BEGIN TRAN
		IF (SELECT DBVersion FROM dbo.VersionInfo vi) =  AND (SELECT DBVersionCheckPoint FROM dbo.VersionInfo vi) = 0
		BEGIN
			/********************************************************************************************************/
			-- Update VersionInfo Application Version 6.4 Release 0 Updates 01 hotfixes
			/********************************************************************************************************/

			UPDATE dbo.VersionInfo
			SET DBVersion = '640001', DBVersionComment = 'Service Pack DDL 6.4, Rel. 0, Updates 01 hotfixes'

			UPDATE dbo.VersionInfo SET DBVersionCheckPoint = 8
		END	
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @dbVersion varchar(10) = (SELECT cast(DBVersion AS varchar(10)) FROM VersionInfo)
	DECLARE @checkPoint varchar(5) = (SELECT cast(DBVersionCheckPoint + 1 AS varchar(5)) FROM VersionInfo)
	RAISERROR( 'There is error occurred when applying upgrade at version %s, %s', 11, 0, @dbVersion, @checkPoint)
	ROLLBACK TRAN
END CATCH

GO




