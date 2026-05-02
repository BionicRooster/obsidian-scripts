# Get file dates for NLP Master Class source files
$srcDir = 'D:\Documents\NLP\Master Class'
$files = Get-ChildItem $srcDir | Select-Object Name, LastWriteTime, Length
$files | ForEach-Object {
    Write-Host "$($_.Name)|$($_.LastWriteTime.ToString('yyyy-MM-dd'))|$($_.Length)"
}
