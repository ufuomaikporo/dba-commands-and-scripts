DECLARE @TableList NVARCHAR(MAX)
DECLARE @TableName NVARCHAR(100)
DECLARE @SQL NVARCHAR(MAX)

IF OBJECT_ID('tempdb..##DataQC') IS NOT NULL
BEGIN
	DROP TABLE ##DataQC
END

CREATE TABLE ##DataQC (TableName VARCHAR(100), RowCnt INT)

SET @TableList = 'Bend
Casing
ClassArea
Coating
Crossing
CrossingLocn
HCACFR
HCACFRSeg
HydroTest
HydroTestRange
Incident
InlineInspection
InlineInspectionRange
InlineInspectionFeature
JointCoating
LandUse
MAOP
MOP
OperatingData
ProductComponent
PipeSegment
Tap
Valve
AddHierarchy_AssessmentId
AddHierarchy_LineName
AddHierarchy_LineNumber
AddHierarchy_PODSID
CouponCorrRate
CTCouplingPresence
ECSMECoatEvaluation
ICCleanPigProgram
InternalCoatingSME
OFFaultLine
OFFrostDepth
OFSeismicArea
OFUnstableSlope
ONValveTime
SCCHSCCHistoryScore
SCCNNSCCHistoryScore
SCCPs
TPDMarkers
TPDPatrolFrequency
TPDPublicAwareness'

SET @TableList = REPLACE(@TableList, ' ', '')
SET @TableList = REPLACE(@TableList, CHAR(10), ' ')
SET @TableList = REPLACE(@TableList, CHAR(13), '')
SET @TableList = REPLACE(@TableList, CHAR(9), '')
SET @TableList = REPLACE(@TableList, ' ', ''', ''')
SET @TableList = REPLACE(@TableList, ''''', ', '')

SET @TableList = '''' + @TableList + ''''

SET @SQL = 'DECLARE TableList_Cursor CURSOR FOR
SELECT name
FROM sys.tables 
WHERE name IN (' + @TableList + ')
ORDER BY 1'

EXECUTE (@SQL)

OPEN TableList_Cursor
FETCH NEXT FROM TableList_Cursor INTO @TableName

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @SQL = 'INSERT INTO ##DataQC
				VALUES (''' + @TableName + ''', (SELECT COUNT(*) FROM ' + @TableName + '))'

	EXECUTE (@SQL)
	
	FETCH NEXT FROM TableList_Cursor INTO @TableName

END

CLOSE TableList_Cursor
DEALLOCATE TableList_Cursor

SELECT * FROM ##DataQC

