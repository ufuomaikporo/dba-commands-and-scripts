$InputFile = "C:\Temp\SampleText.sql"

$InsertStmts = Select-String -Path $InputFile -Pattern "INSERT INTO.*VALUES.*" -Context 0, 1

foreach ($stmt in $InsertStmts.Line)
{
    Write-Host ""
    #$stmt
#-------------------------------- GET TABLE NAME -----------------------------

    $Substr = $Stmt.Replace("INSERT INTO ", "")
    $TableName = $Substr.Substring(0, $Substr.IndexOf(" "))

    $StartIndex = $Stmt.IndexOf('(') + 1
    $EndIndex = $Stmt.IndexOf(')')
    $ColumnList = $Stmt.Substring($StartIndex, $EndIndex - $StartIndex)
    $ColumnList = $ColumnList.Split(",")
    $ColumnList = $ColumnList.Replace(" ", "")

    $StartIndex = $Stmt.IndexOf("VALUES (") + 8
    $EndIndex = $Stmt.LastIndexOf(")")

    $ValuesList = $Stmt.Substring($StartIndex, $EndIndex - $StartIndex)
    $ValuesList = $ValuesList.Split(",")

    #$ColumnList
    #$ValuesList
    
    $Substr = "IF NOT EXISTS (SELECT 1 FROM $TableName WHERE "
    for ($i = 0; $i -lt $ColumnList.Count; $i++)
    {
        $Substr += "$($ColumnList[$i]) = $($ValuesList[$i])"

        if ($i -ne $ColumnList.Count - 1)
        {
            $Substr += " AND "
        }
    }

    $Substr += ")" + "`r`nBEGIN`r`n" + "`t$Stmt" + "`r`nEND"

    $OldStr = $stmt
    $NewStr = $Substr

  
   
   (Get-Content $InputFile).replace($OldStr, $NewStr) | Set-Content $InputFile
}
