# Check agent output files
$taskDir = 'C:\Users\awt\AppData\Local\Temp\claude\C--Users-awt\tasks'
$files = Get-ChildItem $taskDir -Filter '*.output'
foreach ($f in $files) {
    $size = $f.Length
    $lastLines = Get-Content $f.FullName -Tail 2 -ErrorAction SilentlyContinue
    $last = if ($lastLines) { $lastLines[-1] } else { "(empty)" }
    Write-Host "$($f.Name): $size bytes"
    Write-Host "  Last: $last"
}
