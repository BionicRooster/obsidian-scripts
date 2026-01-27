# Simple direct delete of small orphan files
$vaultPath = 'D:\Obsidian\Main'
$skipFolders = @('00 - Journal', '05 - Templates', '00 - Images', 'attachments', '.trash', '.obsidian', '.smart-env')

Write-Host "Scanning vault..." -ForegroundColor Cyan

# Get all .md files
$allFiles = Get-ChildItem -Path $vaultPath -Filter '*.md' -Recurse -ErrorAction SilentlyContinue

# Build linked files set
$linkedFiles = @{}
foreach ($file in $allFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($content) {
        $ms = [regex]::Matches($content, '\[\[([^\]|]+)(?:\|[^\]]+)?\]\]')
        foreach ($m in $ms) {
            $target = $m.Groups[1].Value
            if ($target -match '/') { $target = $target.Split('/')[-1] }
            if ($target -match '#') { $target = $target.Split('#')[0] }
            $linkedFiles[$target.Trim().ToLower()] = $true
        }
    }
}

Write-Host "Found $($linkedFiles.Count) linked files" -ForegroundColor White

$deleted = 0
$errors = 0

foreach ($file in $allFiles) {
    # Skip files >= 50 bytes
    if ($file.Length -ge 50) { continue }

    $relPath = $file.FullName.Replace($vaultPath + '\', '')

    # Skip excluded folders
    $skip = $false
    foreach ($folder in $skipFolders) {
        if ($relPath.StartsWith($folder)) { $skip = $true; break }
    }
    if ($skip) { continue }

    # Check if orphan (no incoming links)
    if (-not $linkedFiles.ContainsKey($file.BaseName.ToLower())) {
        try {
            Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
            Write-Host "DELETED: $($file.BaseName)" -ForegroundColor Green
            $deleted++
        }
        catch {
            Write-Host "ERROR: $($file.BaseName) - $($_.Exception.Message)" -ForegroundColor Red
            $errors++
        }
    }
}

Write-Host ""
Write-Host "=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "Total deleted: $deleted" -ForegroundColor Green
if ($errors -gt 0) {
    Write-Host "Errors: $errors" -ForegroundColor Red
}
