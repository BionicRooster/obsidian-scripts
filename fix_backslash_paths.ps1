# Fix backslash paths in Obsidian image embeds
# Converts ![[path\to\image.jpg]] to ![[path/to/image.jpg]]

$vaultPath = 'D:\Obsidian\Main'
$fixed = 0
$filesModified = @()

Write-Host "Scanning for backslash paths in image embeds..." -ForegroundColor Cyan

# Get all markdown files
$mdFiles = Get-ChildItem -Path $vaultPath -Filter '*.md' -Recurse -ErrorAction SilentlyContinue

foreach ($file in $mdFiles) {
    try {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if (-not $content) { continue }

        # Check if file contains backslashes in image embeds
        if ($content -match '\!\[\[[^\]]*\\[^\]]*\]\]') {
            $originalContent = $content

            # Replace all backslashes with forward slashes inside ![[...]]
            # Use a more comprehensive regex replacement
            $newContent = [regex]::Replace($content, '(\!\[\[)([^\]]+)(\]\])', {
                param($match)
                $prefix = $match.Groups[1].Value
                $path = $match.Groups[2].Value.Replace('\', '/')
                $suffix = $match.Groups[3].Value
                return "$prefix$path$suffix"
            })

            if ($newContent -ne $originalContent) {
                Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8 -NoNewline
                $fixed++
                $relativePath = $file.FullName.Replace($vaultPath + '\', '')
                $filesModified += $relativePath
                Write-Host "Fixed: $relativePath" -ForegroundColor Green
            }
        }
    }
    catch {
        # Skip files with issues
        continue
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Total files fixed: $fixed" -ForegroundColor Green

if ($fixed -gt 0) {
    Write-Host "`nFiles modified:" -ForegroundColor Yellow
    $filesModified | Select-Object -First 20 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    if ($filesModified.Count -gt 20) {
        Write-Host "  ... and $($filesModified.Count - 20) more" -ForegroundColor DarkGray
    }
}
