DECLARE @FKTableName NVARCHAR(100) = 'RiskCalculationGroup'
DECLARE @ModifiedFKTableName NVARCHAR(100);
DECLARE @TempString NVARCHAR(100);
DECLARE @EndIndex INT;
DECLARE @StartIndex INT;

--SET @ModifiedFKTableName = SUBSTRING(@FKTableName, 1, 3);
SET @StartIndex = 1;
SET @ModifiedFKTableName = ''

WHILE @StartIndex < LEN(@FKTableName)
BEGIN
	SET @TempString = STUFF(@FKTableName, 1, @StartIndex, '');
	SET @EndIndex = PATINDEX('%[A-Z]%' COLLATE Latin1_General_BIN, @TempString) + @StartIndex;

	IF (PATINDEX('%[A-Z]%' COLLATE Latin1_General_BIN, @TempString) = 0)
	BEGIN
		SET @EndIndex = LEN(@FKTableName) + 1;
	END;

	IF ((@EndIndex - @StartIndex) <= 5)
	BEGIN
		SET @ModifiedFKTableName += SUBSTRING(@FKTableName, @StartIndex, @EndIndex - @StartIndex);
	END
	ELSE
	BEGIN
		SET @ModifiedFKTableName += SUBSTRING(@FKTableName, @StartIndex, 3);
	END;

	SET @StartIndex = @EndIndex; 

END;



