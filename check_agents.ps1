$f1 = 'C:\Users\awt\AppData\Local\Temp\claude\C--Users-awt\4e69e290-b648-4596-afd0-53476be7dd76\tasks\a306fc103fb7bf2a4.output'
$f2 = 'C:\Users\awt\AppData\Local\Temp\claude\C--Users-awt\4e69e290-b648-4596-afd0-53476be7dd76\tasks\ad7dbddd2d1cef758.output'

Write-Host '=== Jonathan Rice agent ==='
if (Test-Path $f1) {
    Get-Content $f1 -Encoding UTF8 | Select-Object -First 60 | ForEach-Object { Write-Host $_ }
} else {
    Write-Host 'Not yet written'
}

Write-Host ''
Write-Host '=== Malinda Lloyd agent ==='
if (Test-Path $f2) {
    Get-Content $f2 -Encoding UTF8 | Select-Object -First 60 | ForEach-Object { Write-Host $_ }
} else {
    Write-Host 'Not yet written'
}
