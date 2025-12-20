$Directory = 'C:\app\oracle\diag\rdbms\orcl\orcl\trace\'
$RetentionDate = (Get-Date).AddDays(-7)

$FilesToDelete = Get-ChildItem -Path $Directory | Where-Object {$_.LastWriteTime -lt $RetentionDate}

$FilesToDelete | Sort-Object LastAccessTime -Descending | Select-Object -First 10