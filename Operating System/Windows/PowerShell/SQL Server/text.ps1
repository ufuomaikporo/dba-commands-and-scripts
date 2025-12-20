$FileOrFolderPath = "C:\Users\Ufuoma_Ikporo\OneDrive - dynamicrisk.net\Scripts\Oracle\TestOracle\Debug\"
if ((Test-Path -Path $FileOrFolderPath) -eq $false) {
  Write-Warning "File or directory does not exist."
} else {
  $LockingProcess = CMD /C "openfiles /query /fo table | find /I ""$FileOrFolderPath"""
  Write-Host $LockingProcess
}