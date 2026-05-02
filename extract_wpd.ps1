$dir = 'D:\Documents\NLP\Master Class'

function Get-Strings($path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $text = [System.Text.Encoding]::ASCII.GetString($bytes)
    $found = [regex]::Matches($text, '[\x20-\x7E]{5,}')
    $lines = $found | ForEach-Object { $_.Value.Trim() } | Where-Object { $_ -match '[a-zA-Z]{3,}' }
    return $lines -join "`n"
}

$files = Get-ChildItem -Path $dir -File | Where-Object { $_.Extension -match '\.(wpd|doc|wri)$' }
foreach ($f in $files) {
    Write-Host "===== $($f.Name) ====="
    Write-Host (Get-Strings $f.FullName)
    Write-Host ''
}
