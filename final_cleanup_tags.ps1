# Final cleanup - remove all duplicate tags: lines that appear after YAML front matter

$vaultRoot = 'D:\Obsidian\Main'

# Get all files modified in last 3 hours that aren't in exclusion folders
$files = Get-ChildItem -Path $vaultRoot -Recurse -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object {
    $_.LastWriteTime -gt (Get-Date).AddHours(-3) -and `
    $_.FullName -notlike "*09 - Kindle*" -and `
    $_.FullName -notlike "*MOC*"
}

$fixed = 0

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)

    # Check if there's a tags: line after the closing --- of YAML
    if ($content -match '(?m)^---.*?^---\s*\n.*?^tags:') {
        # Split into lines
        $lines = $content -split "`n"
        $inYaml = $false
        $yamlClosed = $false
        $newLines = @()

        foreach ($line in $lines) {
            if ($line -eq '---') {
                if (-not $inYaml) {
                    $inYaml = $true
                } else {
                    $yamlClosed = $true
                }
                $newLines += $line
            } elseif ($yamlClosed -and $line -match '^tags:') {
                # Skip tags lines that appear after YAML closing
                continue
            } else {
                $newLines += $line
            }
        }

        $newContent = $newLines -join "`n"

        # Write back with UTF-8 encoding (no BOM)
        $utf8NoBOM = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($file.FullName, $newContent, $utf8NoBOM)

        $fixed++
        Write-Host "CLEANED: $($file.BaseName)" -ForegroundColor Cyan
    }
}

Write-Host "`nTotal files cleaned: $fixed" -ForegroundColor Blue
