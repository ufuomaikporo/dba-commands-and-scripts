#################################################################################################
# Queries
#################################################################################################

# Query to finds all triggers that will be affected by column name change

$FindTriggers = "SELECT DISTINCT(trig.object_id) AS trigger_id, 
                 trig.name AS trigger_name, 
				 subq.table_name AS table_name, 
				 CONVERT(NVARCHAR(MAX), OBJECT_DEFINITION(trig.object_id)) AS definition
FROM sys.triggers trig
JOIN 
(SELECT trig.object_id AS trig_id,
	   trig.name AS trigger_name,
	   isc.table_name, 
	   isc.column_name
FROM INFORMATION_SCHEMA.COLUMNS isc
INNER JOIN sys.triggers trig
	ON OBJECT_ID(isc.table_name) = trig.parent_id
WHERE (column_name {0})
) subq
ON subq.trig_id = trig.object_id
GO"

# Query to check if an object exist

$ObjectExists = "IF OBJECT_ID('{0}', '{1}') IS NOT NULL
                   SELECT 'Y'
				ELSE SELECT 'N'"

$ColumnExists = "
IF EXISTS (SELECT column_name FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = '{0}' AND column_name = '{1}')
 	SELECT 'Y'
 ELSE SELECT 'N'"

# Command to drop triggers that need to be modified

$DropTriggers = "DROP TRIGGER {0}
GO"

# Stores query to get the number of occurrence of a column that needs to be modified for all tables in the database

$GetDuplicateCount = "SELECT table_name, COUNT(column_name) AS column_count
FROM INFORMATION_SCHEMA.COLUMNS
WHERE column_name LIKE '{0}' 
GROUP BY table_name 
HAVING COUNT(column_name) > 1
GO"

$GetRenameCol = "SELECT table_name, column_name
FROM INFORMATION_SCHEMA.COLUMNS
WHERE column_name LIKE '{0}'
 AND column_name != '{1}'"

# Stores query to find tables do that not have the column that needs to be modified, so the column can be added to the table 

$GetAddColTables = "SELECT table_name FROM INFORMATION_SCHEMA.TABLES
WHERE table_type = 'BASE TABLE'  
EXCEPT
SELECT table_name FROM INFORMATION_SCHEMA.TABLES 
WHERE table_name LIKE 'GDB%' OR
	   table_name LIKE 'SDE%' OR
	   table_name LIKE 'i[0-9]%'
EXCEPT
SELECT DISTINCT(table_name) 
FROM INFORMATION_SCHEMA.COLUMNS isc
WHERE column_name = '{0}'
GO"

# Stores query to get the list of columns (and tables) with more than 1 column that stores the same value but
# with slightly different name variation

$GetColList = "SELECT TOP {0} table_name, column_name
FROM INFORMATION_SCHEMA.COLUMNS
WHERE column_name LIKE '{1}'
	AND column_name != '{2}'
	AND table_name = '{3}'	
GO"

# Stores commands to find and drop the user defined default constraint on a specified column of a specified table

$DropDefaultConst = "DECLARE @ConstraintName nvarchar(200)
SELECT @ConstraintName = Name FROM SYS.DEFAULT_CONSTRAINTS
WHERE PARENT_OBJECT_ID = OBJECT_ID('{0}')
AND PARENT_COLUMN_ID = (SELECT column_id FROM sys.columns
                        WHERE NAME = N'{1}'
                        AND object_id = OBJECT_ID(N'{0}'))
IF @ConstraintName IS NOT NULL
EXEC('ALTER TABLE {0} DROP CONSTRAINT ' + @ConstraintName)"

# Stores command to drop unnecessary duplicate columns

$DropColumns_ddl = "ALTER TABLE {0} DROP COLUMN {1};"

# Stores the command to change column names

$RenameColumn_ddl = "sp_rename '{0}.{1}', '{2}', 'COLUMN';"

# Stores command to Add columns to tables that do not have them

$Addcolumn_ddl = "ALTER TABLE {0} 
ADD {1} {2} DEFAULT ({3})
GO"

#############################################################################################################
#INITIALIZE SOME Variables
#############################################################################################################

# Variables to store database server name and database name

$ServerName = "CGY-T470-0001"
$DB = 'KEY_IRASV5_Upstream'

# array to store SQL Regular Expressions for the columns that need to be replaced

$SQLRegEx = @("Create%User%", "Create%Date%", "LastMod%User%", "LastMod%Date%")

# array to store new column names for columns that need to be modified. The new column names must match the 
# SQL Regular Expression array position-wise

$NewValue = @("CreatedUser", "CreatedDate", "LastModByUserId", "LastModDateTime")

# Make a comma-seperated list with the new column names

$NewNameList = "'" + [system.String]::Join("', '", $NewValue) + "'"

# Store datatypes for columns. Must match the $NewValue array columns position-wise

$ColDataTypes = @('varchar(64)', 'datetime', 'varchar(64)','datetime')

# Stores default values for the columns in the same position as the $ColDataTypes array

$ColDefaultValues = @('suser_sname()', 'getdate()', 'suser_sname()', 'getdate()')

# Convert SQL regular expressions into the Powershell equivalant  
$OldValue = $SQLRegEx -replace "%", "\w*"

############################################################################################################
# Modify Table Columns
#############################################################################################################

######################################### DELETE COLUMNS ###################################################

# This loop deletes all duplicate columns, renames the columns that need to be renamed and adds column to tables
# that do not have them. it does this for each regular expression in the $SQLRegEx array

 For ($i = 0; $i -lt $SQLRegEx.Length; $i++)
 {

	# Get the duplicate column count for tables with duplicate columns
	$SQL = $GetDuplicateCount -f $SQLRegEx[$i]
	$DeleteColList = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DB -Query $SQL

	# Loop through each table with columns that need to be modifed
	ForEach ($table in $DeleteColList)
	{
		
		# Get list of duplicate columns for the table
		$SQL = $GetColList -f ($table.column_count - 1), $SQLRegEx[$i], $NewValue[$i], $table.table_name
		$DuplicateColList = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DB -Query $SQL

		# Loop through and drop all but one of the duplicate columns
		foreach ($table in $DuplicateColList)
		{
			# Drops default constraint on a column
			$SQL = $DropDefaultConst -f $table.table_name, $table.column_name
			Invoke-Sqlcmd -ServerInstance $ServerName -Database $DB -Query $SQL; 

			# Drops the column
			$SQL = $DropColumns_ddl -f $DuplicateColList.table_name, $DuplicateColList.column_name
			Invoke-Sqlcmd -ServerInstance $ServerName -Database $DB -Query $SQL; 
		} # End of inner For-Loop
		
	} # End of ForEach-Loop

############################################# RENAME COLUMNS ########################################################
 	
	# Get a list of columns that need a name change

	$SQL = $GetRenameCol -f $SQLRegEx[$i], $NewValue[$i]
	$RenameColList = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DB -Query $SQL

	# Loop through and change the column names

	ForEach ($table in $RenameColList) 
	{
		# Get a list consisting of table name and column name for columns that need to be modified
		# $SQL = $GetColList -f $SQLRegEx[$i], $table.table_name
		# $ColumnList = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DB -Query $SQL

		# Rename the columns
		$SQL = $RenameColumn_ddl -f $table.table_name, $table.column_name, $NewValue[$i]
		Invoke-Sqlcmd -ServerInstance $ServerName -Database $DB -Query $SQL
	}

} # End of outer ForEach-Loop

############################################### ADD COLUMNS #################################################

# For each new column name, get a list of tables that do not currently have that column and add the column

For ($i = 0; $i -lt $NewValue.Length; $i++)
{
	$SQL = $GetAddColTables -f $NewValue[$i]
	$AddColList = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DB -Query $SQL

	ForEach ($table in $AddColList)
	{
		$SQL = $ColumnExists -f $table.table_name, $NewValue[$i]
		#$Exists = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DB -Query $SQL

			$SQL = $Addcolumn_ddl -f $table.table_name, $NewValue[$i], $ColDataTypes[$i], $ColDefaultValues[$i]
			Invoke-Sqlcmd -ServerInstance $ServerName -Database $DB -Query $SQL
		
	}
} #end of ForEach-loop

#############################################################################################################
# Modifying the triggers
#############################################################################################################

# Create a string to be used in the WHERE clause of $FindTriggers SQL statement

$SearchList = "LIKE '" + $SQLRegEx[0] + "'"

For ($i = 1; $i -lt $SQLRegEx.Length; $i++)
{
	$SearchList += "`r`n OR column_name LIKE '" + $SQLRegEx[$i] + "'"
}

# Executes query to get trigger info for all triggers that will be affected by a column name change

$SQL = $FindTriggers -f $SearchList
$TriggerList = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DB -Query $SQL -MaxCharLength 8000

# Creates a string variable containing the Powershell command that will modify the trigger definitions in $TriggerList

$SearchNReplace = '$Trigger.definition | ForEach-Object {$_'

FOR ($i = 0 ; $i -lt $OldValue.Count; $i++) {
	$Replace = ' -replace ' + '"{0}"' + ", " + '"{1}"' 
	$SearchNReplace += $Replace -f $OldValue[$i], $NewValue[$i]
}

$SearchNReplace += "}"

# Modify the trigger definitions
foreach ($Trigger IN $TriggerList)
{ 
	$Trigger.definition = Invoke-Expression $SearchNReplace 
}


$Column = 'LastModDateTime'

 $TriggerIndex = $TriggerList.trigger_name.IndexOf('tu_inlineinspection')

 $TriggerList[$TriggerIndex].definition
	
		$IndexInsertStmt = $TriggerList[$TriggerIndex].definition.IndexOf('INSERT INTO')

		$BeginDef = $TriggerList[$TriggerIndex].definition.Substring(0,$IndexInsertStmt)

		$InsertNSelectStmt = $TriggerList[$TriggerIndex].definition.Substring($IndexInsertStmt)
		$IndexSelectStmt = $InsertNSelectStmt.IndexOf('SELECT')
		$InsertStmt =  $InsertNSelectStmt.Substring(0, $IndexSelectStmt)
		$SelectStmt = $InsertNSelectStmt.Substring($IndexSelectStmt)

		$BeginDef | Get-Member
		#>

		

# 		if ($Count -gt 1)
# 		{
# 			for ($i = 0; $i -lt $Count; $i++)
# 			{
# 				$Index = $BeginDef.IndexOf($Column)
# 				$BeginDef.Remove($Index - 1, $Column.Length + 2)
# 			}
# 		}

# 		$Count = $InsertStmt.contains($Column).count

# 		if ($Count -gt 1)
# 		{
# 			for ($i = 0; $i -lt $Count; $i++)
# 			{
# 				$Index = $InsertStmt.IndexOf($Column)
# 				$InsertStmt.Remove($Index - 1, $Column.Length + 2)
# 			}
# 		}

# 		$Count = $SelectStmt.contains($Column).count

# 		if ($Count -gt 1)
# 		{
# 			for ($i = 0; $i -lt $Count; $i++)
# 			{
# 				$Index = $SelectStmt.IndexOf($Column)
# 				$SelectStmt.Remove($Index - 1, $Column.Length + 2)
# 			}
# 		}

# 		$Trigger.definition = $BeginDef + $InsertStmt + $SelectStmt

# $TriggerList.trigger_id.Count
# $TriggerList[$TriggerList.trigger_name.IndexOf('tu_inlineinspection')].definition
# # write-host '-----------------------------------'
# $BeginDef
# write-host '------------------------'
# $InsertStmt
# write-host '----------------------------------'
# $SelectStmt


# foreach($Trigger in TriggerList)
# {
# }

############################################################################################################
# Recreate triggers
############################################################################################################

# Drop and recreate all Triggers that need to be modified. Excludes triggers that belong to Spatial database tables

# ForEach ($Trigger in $TriggerList)
# {
# 	#if ($Trigger.table_name -notmatch "GDB\w*" -and $Trigger.table_name -notmatch "SDE_\w*" `
# 	    #-and $Trigger.table_name -notmatch "i[0-9]\w*")
	
# 		$SQL = $DropTriggers -f $Trigger.trigger_name
# 		Invoke-Sqlcmd -ServerInstance $ServerName -Database $DB -Query $SQL
# 		Invoke-Sqlcmd -ServerInstance $ServerName -Database $DB -Query $Trigger.definition		
		
	
# } 

