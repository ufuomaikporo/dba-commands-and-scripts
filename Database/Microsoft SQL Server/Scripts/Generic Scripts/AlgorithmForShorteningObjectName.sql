DECLARE @FKTableName NVARCHAR(100);
DECLARE @ModifiedFKTableName NVARCHAR(100);
DECLARE @NewString NVARCHAR(100) ;
DECLARE @TempString NVARCHAR(100);
DECLARE @EndIndex INT;
DECLARE @StartIndex INT;

---------------------------------- Get first 3 to 4 letters of  -------------------------------------------
SET @FKTableName = 'RiskCalculationGroup'
SET @StartIndex = 1;
SET @NewString = ''

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
		SET @NewString += SUBSTRING(@FKTableName, @StartIndex, @EndIndex - @StartIndex);
	END
	ELSE
	BEGIN
		SET @NewString += SUBSTRING(@FKTableName, @StartIndex, 3);
	END;

	SET @StartIndex = @EndIndex; 

END;

------------------------------------- Get first letter of each word from a source word in Pascal case -----------------

SET @FKTableName = 'SoilLandUseArea'
SET @ModifiedFKTableName = ''
SET @StartIndex = 1

WHILE @StartIndex < LEN(@FKTableName)
BEGIN
	SET @TempString = STUFF(@FKTableName, 1, @StartIndex, '');
	SET @ModifiedFKTableName += SUBSTRING(@FKTableName, @StartIndex, 1)

	SET @EndIndex = PATINDEX('%[A-Z]%' COLLATE Latin1_General_BIN, @TempString) + @StartIndex

	IF (PATINDEX('%[A-Z]%' COLLATE Latin1_General_BIN, @TempString) = 0)
	BEGIN
		SET @EndIndex = LEN(@FKTableName);
	END;

	SET @StartIndex = @EndIndex
END

