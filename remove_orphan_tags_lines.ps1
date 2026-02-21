# Remove orphan tags: lines that appear immediately after YAML closing ---

$vaultRoot = 'D:\Obsidian\Main'

# Get all files modified in last 4 hours
$files = Get-ChildItem -Path $vaultRoot -Recurse -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object {
    $_.LastWriteTime -gt (Get-Date).AddHours(-4) -and `
    $_.FullName -notlike "*09 - Kindle*" -and `
    $_.FullName -notlike "*MOC*"
}

$fixed = 0

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)

    # Look for pattern: --- followed by tags: on next line
    if ($content -match '(?m)^---\s*\ntags: #tech\s*\n') {
        # Replace the pattern: remove the orphan tags: line
        $newContent = $content -replace '(?m)^---\s*\ntags: #tech\s*\n', "---`n"

        # Write back
        $utf8NoBOM = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($file.FullName, $newContent, $utf8NoBOM)

        $fixed++
        Write-Host "REMOVED ORPHAN: $($file.BaseName)" -ForegroundColor Yellow
    }
}

Write-Host "`nTotal orphan tags lines removed: $fixed" -ForegroundColor Blue
