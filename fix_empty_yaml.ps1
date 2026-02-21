# Find and fix all empty YAML blocks (--- followed immediately by ---)

$vaultRoot = 'D:\Obsidian\Main'

# Get all files modified in last 6 hours
$files = Get-ChildItem -Path $vaultRoot -Recurse -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object {
    $_.LastWriteTime -gt (Get-Date).AddHours(-6) -and `
    $_.FullName -notlike "*09 - Kindle*" -and `
    $_.FullName -notlike "*MOC*"
}

$fixed = 0

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)

    # Look for empty YAML: --- directly followed by ---
    if ($content -match '(?m)^---\s*\n---') {
        # Replace with YAML containing tags
        $newContent = $content -replace '(?m)^---\s*\n---', "---`ntags: #tech`n---"

        # Write back
        $utf8NoBOM = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($file.FullName, $newContent, $utf8NoBOM)

        $fixed++
        Write-Host "FIXED EMPTY YAML: $($file.BaseName)" -ForegroundColor Green
    }
}

Write-Host "`nTotal files fixed: $fixed" -ForegroundColor Blue
