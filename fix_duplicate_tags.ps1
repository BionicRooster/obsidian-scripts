# Fix duplicate tags lines in files that were just modified

$vaultRoot = 'D:\Obsidian\Main'

# Get all markdown files modified in the last 2 hours
$files = Get-ChildItem -Path $vaultRoot -Recurse -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object {
    $_.LastWriteTime -gt (Get-Date).AddHours(-2) -and `
    $_.FullName -notlike "*09 - Kindle*" -and `
    $_.FullName -notlike "*MOC*"
}

$fixed = 0

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)

    # Check for duplicate tags lines
    if ($content -match '(?m)^tags:.*\n.*^tags:') {
        # Remove duplicate tags lines, keep only one
        $lines = $content -split "`n"
        $newLines = @()
        $seenTagsLine = $false

        foreach ($line in $lines) {
            if ($line -match '^tags:') {
                if (-not $seenTagsLine) {
                    $newLines += $line
                    $seenTagsLine = $true
                }
                # Skip subsequent tags lines
            } else {
                $newLines += $line
            }
        }

        $content = $newLines -join "`n"

        # Write back with UTF-8 encoding (no BOM)
        $utf8NoBOM = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($file.FullName, $content, $utf8NoBOM)

        $fixed++
        Write-Host "FIXED DUPLICATE: $($file.BaseName)" -ForegroundColor Yellow
    }
}

Write-Host "`nFixed duplicates: $fixed" -ForegroundColor Blue
