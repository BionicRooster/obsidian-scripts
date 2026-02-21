$remaining = Get-ChildItem -Path "D:\Obsidian\Main\20 - Permanent Notes" -Filter "*.md" | Where-Object { $_.Name -ne "20 - Permanent Notes.md" -and $_.CreationTime -gt (Get-Date).AddDays(-60) }
if ($remaining.Count -eq 0) {
    Write-Host "SUCCESS: No recent orphan files remaining in 20 - Permanent Notes"
} else {
    Write-Host "Remaining files: $($remaining.Count)"
    foreach ($f in $remaining) {
        Write-Host "  - $($f.Name)"
    }
}
