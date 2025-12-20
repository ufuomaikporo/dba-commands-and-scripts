<#
    This script adds a check to see if a row already exists before inserting it
#>
$InputFile = "C:\Temp\Base List Domain update.sql"
#$InputFile = "C:\Temp\SampleText.sql"

$InsertStmts = Select-String -Path $InputFile -Pattern "INSERT INTO.*VALUES.*" -Context 0, 1

foreach ($stmt in $InsertStmts.Line)
{
    #Get tablename for the INSERT statement
    $Substr = $Stmt -ireplace [regex]::Escape("INSERT INTO "), ""
    $TableName = $Substr.Substring(0, $Substr.IndexOf(" "))

    #Get the column list for the INSERT statement
    $StartIndex = $Stmt.IndexOf('(') + 1
    $EndIndex = $Stmt.IndexOf(')')
    $ColumnList = $Stmt.Substring($StartIndex, $EndIndex - $StartIndex)
    $ColumnList = $ColumnList.Split(",")
    $ColumnList = $ColumnList.Replace(" ", "")

    #Get the values for the column lists
    $SpotterIndex = $Stmt.ToUpper().IndexOf(" VALUES")
    $StartIndex = $Stmt.IndexOf("(", $SpotterIndex) + 1
    $EndIndex = $Stmt.LastIndexOf(")")
  
    $ValuesList = $Stmt.Substring($StartIndex, $EndIndex - $StartIndex)
    $ValuesList = $ValuesList.Split(",")
 
    #Modify the INSERT statement by adding a check for the row being inserted
    $Substr = "IF NOT EXISTS (SELECT 1 FROM $TableName WHERE "
    for ($i = 0; $i -lt $ColumnList.Count; $i++)
    {
        $Substr += "$($ColumnList[$i]) = $($ValuesList[$i])"

        if ($i -ne $ColumnList.Count - 1)
        {
            $Substr += " AND "
        }
    }
    
    $Substr += ")" + "`r`nBEGIN`r`n" 
    
    if ($TableName -ieq "ListDomain")
    {
        $Substr += "`tIF NOT EXISTS (SELECT 1 FROM DomainCatalog WHERE Id = $($ValuesList[0]))" + 
                    "`r`n`tBEGIN" +
                    "`r`n`t`tSELECT @SQL = 'INSERT INTO DomainCatalog (Id, DomainDescr) VALUES (' + CAST(Id AS NVARCHAR) +', ''' + DomainDescr +''')' " +
                    "`r`n`t`tFROM DRAS_IRASV6_DEMO_DE_STAGE.dbo.DomainCatalog WHERE id = $($ValuesList[0])" +
                    "`r`n`t`tEXECUTE (@SQL)" +
                    "`r`n`tEND" 
    }
    
    $Substr += "`r`n`t$Stmt" + "`r`nEND"

    $OldStr = $stmt
    $NewStr = $Substr  

   (Get-Content $InputFile).replace($OldStr, $NewStr) | Set-Content $InputFile
}
#>

