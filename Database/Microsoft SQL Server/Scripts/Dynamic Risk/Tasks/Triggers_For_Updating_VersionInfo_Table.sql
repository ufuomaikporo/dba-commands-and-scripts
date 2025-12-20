CREATE OR ALTER TRIGGER [dbo].[tu_versioninfo] ON [dbo].[VersionInfo] 
FOR UPDATE AS 
BEGIN
    UPDATE dbo.VersionInfo
    SET LastModByUserId = SUSER_SNAME(), LastModDateTime = GETDATE() 
    FROM dbo.VersionInfo as t, DELETED as d
    WHERE t.Id=d.Id;
END
GO

ALTER TABLE [dbo].[VersionInfo] ENABLE TRIGGER [tu_versioninfo]
GO

CREATE OR ALTER TRIGGER [dbo].[th_versioninfo]
ON [dbo].[VersionInfo] 
FOR UPDATE AS
BEGIN

	IF(UPDATE(DBVersion))
	BEGIN
		UPDATE dbo.versioninfo
		SET LastUpgradeUserId = SUSER_SNAME(),
			LastUpgradeDateTime = GETDATE()
		FROM dbo.VersionInfo as t, DELETED as d
		WHERE t.Id=d.Id;
	END;

	IF (UPDATE(LastUpgradeUserId) OR UPDATE(LastUpgradeDateTime) OR UPDATE (LastUpgradeType)
		 or UPDATE(DBVersion) or UPDATE(DBVersionComment) OR Update(DBVersionCheckPoint))
	BEGIN   
		INSERT INTO VersionHistory (DBVersion, DBVersionComment, LastModByUserId, LastModDateTime, DataExchangeLastRunDateTime,LastUpgradeUserId,LastUpgradeDateTime,LastUpgradeType,DBVersionCheckPoint)
		SELECT DBVersion, DBVersionComment, LastModByUserId, LastModDateTime, DataExchangeLastRunDateTime,LastUpgradeUserId,LastUpgradeDateTime,LastUpgradeType,DBVersionCheckPoint
		FROM DELETED
	END

END;
GO

ALTER TABLE [dbo].[VersionInfo] ENABLE TRIGGER [th_versioninfo]
GO